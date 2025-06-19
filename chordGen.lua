local standalone = true

if #({ ... }) == #arg then
    local param = { ... }
    for i = 1, #arg do
        if param[i] ~= arg[i] then
            standalone = false
            break
        end
    end
else
    standalone = false
end

if standalone and #arg == 0 or arg[1] == '-h' or arg[1] == '--help' then
    print("Usage: lua chordGen.lua [option] chord1 chord2 ...")
    return
end

local dimData = {
    [0] = { -- 0D
        yStep = 0,
        draw = 'none',
    },
    { -- 1D (octave)
        yStep = math.log(8 / 4, 2),
        draw = 'arrow',
        color = '808080',
    },
    { -- 2D (fifth)
        yStep = math.log(6 / 4, 2),
        draw = 'left',
        color = 'F27A93',
    },
    { -- 3D (third)
        yStep = math.log(5 / 4, 2),
        draw = 'right',
        color = '6DD884',
    },
    { -- 4D
        yStep = math.log(7 / 4, 2),
        draw = 'rise',
        color = 'B498EE',
    },
    { -- 5D
        yStep = math.log(11 / 4, 2),
        draw = 'fall',
        color = 'FFC247',
    },
    { -- 6D
        yStep = math.log(13 / 4, 2),
        draw = 'arcleft',
        color = 'B5B539',
    },
    { -- 7D
        yStep = math.log(17 / 4, 2),
        draw = 'arcright',
        color = 'E19C7D',
    },
}
for i = 1, #dimData do
    local dim = dimData[i]
    dimData[-i] = {
        yStep = -dim.yStep,
        draw = dim.draw,
        color = dim.color,
    }
end

---@alias SsvtDim number

---@class SsvtChord
---@field d? SsvtDim
---@field note? 'skip' | 'dotted'
---@field bias? 'l' | 'r'
---@field bass? true
---@field [number] SsvtChord

local bw = .1   -- Beam width
local nw = .014 -- Note width

local drawBuffer

local ucs_x, ucs_y = 0, 0
local function moveOrigin(dx, dy)
    ucs_x = ucs_x + dx
    ucs_y = ucs_y + dy
end

local function addShape(mode, color, layer, ...)
    local points = { ... }
    local numCount = 0
    for i = 1, #points do
        if type(points[i]) == 'number' then
            numCount = numCount + 1
            points[i] = points[i] + (numCount % 2 == 1 and ucs_x or ucs_y)
        end
    end

    table.insert(drawBuffer, {
        mode = mode,
        layer = layer,
        color = color,
        points = points,
    })
end

local function lerp(a, b, t)
    return a * (1 - t) + b * t
end

local function drawBass(mode, x1, x2)
    if mode == 'l' then
        addShape('polygon', "F0F0F0", 99,
            x1 - 0.05, 0,
            x1 - 0.12, .04,
            x1 - 0.12, -.04
        )
    else
        addShape('polygon', "F0F0F0", 99,
            x2 + 0.05, 0,
            x2 + 0.12, .04,
            x2 + 0.12, -.04
        )
    end
end
local function drawNote(mode, x1, x2)
    if mode == 'dotted' then
        -- Dotted line
        for i = 0, 10, 2 do
            local x = lerp(x1 + .05, x2 - .05, i / 11)
            local w = (x2 - x1 - .1) / 11
            addShape('polygon', "F0F0F0", 0,
                x, -nw / 2,
                x + w, -nw / 2,
                x + w, nw / 2,
                x, nw / 2
            )
        end
    elseif mode == 'skip' then
        -- Short line
        x1, x2 = lerp(x1, x2, .3), lerp(x2, x1, .3)
        addShape('polygon', "808080", 0,
            x1 + .05, -nw / 2,
            x2 - .05, -nw / 2,
            x2 - .05, nw / 2,
            x1 + .05, nw / 2
        )
    else
        -- Line
        addShape('polygon', "F0F0F0", 0,
            x1 + .05, -nw / 2,
            x2 - .05, -nw / 2,
            x2 - .05, nw / 2,
            x1 + .05, nw / 2
        )
    end
end

local function drawBeam(color, mode, x1, y1, x2, y2)
    if mode == 'none' then return end
    if mode == 'arrow' then
        local m = (x1 + x2) / 2
        addShape('polygon', color, 1,
            m, y1,
            m + bw * .8, y1 * .9 + y2 * .1,
            m + bw * .2, y1 * .9 + y2 * .1,
            m + bw * .2, y2,
            m - bw * .2, y2,
            m - bw * .2, y1 * .9 + y2 * .1,
            m - bw * .8, y1 * .9 + y2 * .1
        )
    else
        if y1 > y2 then y1, y2 = y2, y1 end
        y1, y2 = y1 - nw / 2, y2 + nw / 2
        if mode == 'left' then
            addShape('polygon', color, 2,
                x1, y1,
                x1, y2,
                x1 + bw, y2,
                x1 + bw, y1
            )
        elseif mode == 'right' then
            addShape('polygon', color, 2,
                x2, y1,
                x2, y2,
                x2 - bw, y2,
                x2 - bw, y1
            )
        elseif mode == 'mid' then
            local m = (x1 + x2) / 2
            addShape('polygon', color, 2,
                m - bw / 4, y1,
                m + bw / 4, y1,
                m + bw / 4, y2,
                m - bw / 4, y2
            )
        elseif mode == 'rise' then
            addShape('polygon', color, 3,
                x1, y1,
                x1 + bw * 1.26, y1,
                x2, y2,
                x2 - bw * 1.26, y2
            )
        elseif mode == 'fall' then
            addShape('polygon', color, 3,
                x2, y1,
                x2 - bw * 1.1, y1,
                x1, y2,
                x1 + bw * 1.1, y2
            )
        elseif mode == 'arcleft' then
            addShape('path', color, 4,
                "M", x1, y1,
                "Q", x1 - 2.6 * bw, (y1 + y2) / 2, x1, y2,
                "L", x1 + bw, y2,
                "Q", x1 + bw - 2.6 * bw, (y1 + y2) / 2, x1 + bw, y1,
                "Z"
            )
        elseif mode == 'arcright' then
            addShape('path', color, 4,
                "M", x2, y1,
                "Q", x2 + 2.6 * bw, (y1 + y2) / 2, x2, y2,
                "L", x2 - bw, y2,
                "Q", x2 - bw + 2.6 * bw, (y1 + y2) / 2, x2 - bw, y1,
                "Z"
            )
        else
            error("Unknown beam style: " .. mode)
        end
    end
end

---@param chord SsvtChord
---@param x1 number
---@param x2 number
local function DrawBranch(chord, x1, x2)
    local nData = dimData[chord.d]

    assert(nData, "Unknown dimension: " .. tostring(chord.d))

    moveOrigin(0, nData.yStep)

    -- Bass
    if chord.bass then
        drawBass(chord.bias or 'l', x1, x2)
    end

    -- Note
    drawNote(chord.note, x1, x2)

    -- Beam
    drawBeam(nData.color, nData.draw, x1, 0, x2, -nData.yStep)

    -- Branches
    for n = 1, #chord do
        local nxt = chord[n]
        if nxt.bias == 'l' then
            DrawBranch(nxt, x1, x2 - .16)
        elseif nxt.bias == 'r' then
            DrawBranch(nxt, x1 + .16, x2)
        else
            DrawBranch(nxt, x1, x2)
        end
    end

    moveOrigin(0, -nData.yStep)
end

---@param chord SsvtChord
local function drawChord(chord)
    drawBuffer = {}
    DrawBranch(chord, 0, 1)
    table.sort(drawBuffer, function(a, b) return a.layer < b.layer end)
    return drawBuffer
end

---@param dat string
---@return SsvtChord
local function decode(dat)
    ---@type SsvtChord
    local buf = { d = 0 }
    local note = dat:match("^%-?%d+")
    if note then
        buf.d = tonumber(note:match("%-?%d+"))
        dat = dat:sub(#note + 1)
    end
    while true do
        local char = dat:sub(1, 1)
        if char == '.' then
            if math.abs(buf.d) == 1 then
                buf.note = 'skip'
            else
                buf.note = 'dotted'
            end
        elseif char == 'l' then
            buf.bias = 'l'
        elseif char == 'r' then
            buf.bias = 'r'
        elseif char == 'x' then
            buf.bass = true
        else
            break
        end
        dat = dat:sub(2)
    end
    local branch = string.match(dat, "%b()")
    if branch then
        branch = branch:sub(2, -2) -- Remove outer parentheses (and garbages come after)
        local resStrings = {}
        local balance = 0
        local start = 1
        for i = 1, #branch do
            local char = branch:sub(i, i)
            if char == "(" then
                balance = balance + 1
            elseif char == ")" then
                balance = balance - 1
                assert(balance >= 0, "More ( than )")
            elseif char == "," and balance == 0 then
                table.insert(resStrings, branch:sub(start, i - 1))
                start = i + 1
            end
        end
        table.insert(resStrings, branch:sub(start))
        for i = 1, #resStrings do
            table.insert(buf, decode(resStrings[i]))
        end
    end
    return buf
end

if not standalone then
    return {
        dimData = dimData,
        decode = decode,
        drawChord = drawChord,
    }
end

local function toSvg(data, param)
    -- Calculate bounding box
    local minX, maxX, minY, maxY = 999, -999, 999, -999
    for i = 1, #data do
        local shape = data[i].points
        local numCount = 0
        for j = 1, #shape do
            if type(shape[j]) == 'number' then
                numCount = numCount + 1
                if numCount % 2 == 1 then
                    if shape[j] < minX then minX = shape[j] elseif shape[j] > maxX then maxX = shape[j] end
                else
                    if shape[j] < minY then minY = shape[j] elseif shape[j] > maxY then maxY = shape[j] end
                end
            end
        end
    end

    minX, maxX = minX - .1, maxX + .1
    minY, maxY = minY - .1, maxY + .1

    -- Snap to zero & Flip vertically
    maxX, maxY = maxX - minX, maxY - minY
    for i = 1, #data do
        local shape = data[i].points
        local numCount = 0
        for j = 1, #shape do
            if type(shape[j]) == 'number' then
                numCount = numCount + 1
                if numCount % 2 == 1 then
                    shape[j] = shape[j] - minX
                else
                    shape[j] = maxY - (shape[j] - minY)
                end
            end
        end
    end

    -- Stringify (to 4 significant digits)
    for i = 1, #data do
        local shape = data[i].points
        for j = 1, #shape do
            if type(shape[j]) == 'number' then
                shape[j] = string.format("%.4g", shape[j])
            end
        end
    end

    local shapeData = ""
    for i = 1, #data do
        local shape = data[i]
        if shape.mode == 'polygon' then
            shapeData = shapeData ..
                ([[<polygon points="%s" fill="#%s" />]]):format(
                    table.concat(shape.points, ","),
                    shape.color
                )
        elseif shape.mode == 'path' then
            shapeData = shapeData ..
                ([[<path d="%s" fill="#%s" />]]):format(
                    table.concat(shape.points, " "),
                    shape.color
                )
        end
    end
    local kx, ky
    if param.w > 0 then kx = param.w / maxX end
    if param.h > 0 then ky = param.h / maxY end
    if not (kx and ky) then
        if kx then
            ky = kx
        elseif ky then
            kx = ky
        else
            kx, ky = 128, 128
        end
    end
    return string.format(
        [[<svg width="%d" height="%d" viewBox="0 0 %f %f" xmlns="http://www.w3.org/2000/svg">%s%s</svg>]],
        math.ceil(kx * maxX),
        math.ceil(ky * maxY),
        string.format("%.4g", maxX),
        string.format("%.4g", maxY),
        param.bg and ([[<rect width="100%%" height="100%%" fill="#%s" />]]):format(param.bg) or "",
        shapeData
    )
end

local count = 0
local param = {
    w = 128,
    h = -1,
    bg = false, -- 524E61
}
for i = 1, #arg do
    if arg[i]:match("^w=%-?%d+") then
        param.w = tonumber(arg[i]:match("%-?%d+"))
    elseif arg[i]:match("^h=%-?%d+") then
        param.h = tonumber(arg[i]:match("%-?%d+"))
    elseif arg[i]:match("^bg=%x%x%x%x%x%x$") then
        param.bg = arg[i]:match("%x%x%x%x%x%x")
    elseif arg[i] == 'nobg' then
        param.bg = false
    else
        local chordStr = arg[i]
        local chord = decode(chordStr)
        local svgData = toSvg(drawChord(chord), param)
        count = count + 1
        local fileName = count .. ".svg"
        io.open(fileName, "w"):write(svgData):close()
    end
end
print(count .. " x SVG generated successfully.")
