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
---@field root? true
---@field [number] SsvtChord

local lw = .1
local nw = .014

local drawBuffer

local ucs_x, ucs_y = 0, 0
local function moveOrigin(dx, dy)
    ucs_x = ucs_x + dx
    ucs_y = ucs_y + dy
end

local function polygon(layer, color, ...)
    local points = { ... }
    for i = 1, #points, 2 do
        points[i] = points[i] + ucs_x
        points[i + 1] = points[i + 1] + ucs_y
    end
    table.insert(drawBuffer, {
        layer = layer,
        color = color,
        type = 'polygon',
        points = points,
    })
end

-- Warning: not any path
local function path(layer, color, ...)
    local points = { ... }
    for i = 1, #points, 2 do
        points[i] = points[i] + ucs_x
        points[i + 1] = points[i + 1] + ucs_y
    end
    table.insert(drawBuffer, {
        layer = layer,
        color = color,
        type = 'path',
        points = points,
    })
end

local function lerp(a, b, t)
    return a * (1 - t) + b * t
end

local function drawRoot(mode, x1, x2)
    if mode == 'l' then
        polygon(99, "F0F0F0",
            x1 - 0.05, 0,
            x1 - 0.12, .04,
            x1 - 0.12, -.04
        )
    else
        polygon(99, "F0F0F0",
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
            polygon(0, "F0F0F0",
                x, -nw / 2,
                x + w, -nw / 2,
                x + w, nw / 2,
                x, nw / 2
            )
        end
    elseif mode == 'skip' then
        -- Short line
        x1, x2 = lerp(x1, x2, .3), lerp(x2, x1, .3)
        polygon(0, "808080",
            x1 + .05, -nw / 2,
            x2 - .05, -nw / 2,
            x2 - .05, nw / 2,
            x1 + .05, nw / 2
        )
    else
        -- Line
        polygon(0, "F0F0F0",
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
        polygon(1, color,
            m, y1,
            m + lw * .8, y1 * .9 + y2 * .1,
            m + lw * .2, y1 * .9 + y2 * .1,
            m + lw * .2, y2,
            m - lw * .2, y2,
            m - lw * .2, y1 * .9 + y2 * .1,
            m - lw * .8, y1 * .9 + y2 * .1
        )
    else
        if y1 > y2 then y1, y2 = y2, y1 end
        y1, y2 = y1 - nw / 2, y2 + nw / 2
        if mode == 'left' then
            polygon(2, color,
                x1, y1,
                x1, y2,
                x1 + lw, y2,
                x1 + lw, y1
            )
        elseif mode == 'right' then
            polygon(2, color,
                x2, y1,
                x2, y2,
                x2 - lw, y2,
                x2 - lw, y1
            )
        elseif mode == 'mid' then
            local m = (x1 + x2) / 2
            polygon(2, color,
                m - lw / 4, y1,
                m + lw / 4, y1,
                m + lw / 4, y2,
                m - lw / 4, y2
            )
        elseif mode == 'rise' then
            polygon(3, color,
                x1, y1,
                x1 + lw * 1.26, y1,
                x2, y2,
                x2 - lw * 1.26, y2
            )
        elseif mode == 'fall' then
            polygon(3, color,
                x2, y1,
                x2 - lw * 1.1, y1,
                x1, y2,
                x1 + lw * 1.1, y2
            )
        elseif mode == 'arcleft' then
            path(4, color,
                x1, y1,
                x1 - 2.6 * lw, (y1 + y2) / 2,
                x1, y2,
                x1 + lw, y2,
                x1 + lw - 2.6 * lw, (y1 + y2) / 2,
                x1 + lw, y1
            )
        elseif mode == 'arcright' then
            path(4, color,
                x2, y1,
                x2 + 2.6 * lw, (y1 + y2) / 2,
                x2, y2,
                x2 - lw, y2,
                x2 - lw + 2.6 * lw, (y1 + y2) / 2,
                x2 - lw, y1
            )
        else
            error("Unknown beam style: " .. mode)
        end
    end
end

---@param chord SsvtChord
---@param x1 number
---@param x2 number
function DrawBranch(chord, x1, x2)
    local nData = dimData[chord.d]

    moveOrigin(0, nData.yStep)

    -- Root
    if chord.root then
        drawRoot(chord.bias or 'l', x1, x2)
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
function DrawChord(chord)
    drawBuffer = {}
    DrawBranch(chord, 0, 1)
    table.sort(drawBuffer, function(a, b) return a.layer < b.layer end)
    return drawBuffer
end

---@param dat string
---@return SsvtChord
local function SsvtDecode(dat)
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
            buf.root = true
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
            table.insert(buf, SsvtDecode(resStrings[i]))
        end
    end
    return buf
end

local function toSvg(data, sizeMode, targetSize)
    -- Calculate bounding box
    local minX, maxX, minY, maxY = 999, -999, 999, -999
    for i = 1, #data do
        local shape = data[i].points
        for j = 1, #shape, 2 do
            local x, y = shape[j], shape[j + 1]
            if x < minX then minX = x elseif x > maxX then maxX = x end
            if y < minY then minY = y elseif y > maxY then maxY = y end
        end
    end

    -- Snap to zero & Flip vertically
    maxX, maxY = maxX - minX, maxY - minY
    for i = 1, #data do
        local shape = data[i].points
        for j = 1, #shape, 2 do
            shape[j] = shape[j] - minX
            shape[j + 1] = maxY - (shape[j + 1] - minY)
        end
    end

    -- Strinify
    for i = 1, #data do
        local shape = data[i].points
        for j = 1, #shape do
            shape[j] = string.format("%.4g", shape[j])
        end
    end

    local shapeData = ""
    for i = 1, #data do
        local shape = data[i]
        if shape.type == 'polygon' then
            shapeData = shapeData ..
                ([[<polygon points="%s" fill="#%s" />]]):format(
                    table.concat(shape.points, ","),
                    shape.color
                )
        elseif shape.type == 'path' then
            shape.points = {
                "M", shape.points[1], shape.points[2],
                "Q", shape.points[3], shape.points[4], shape.points[5], shape.points[6],
                "L", shape.points[7], shape.points[8],
                "Q", shape.points[9], shape.points[10], shape.points[11], shape.points[12],
                "Z",
            }
            shapeData = shapeData ..
                ([[<path d="%s" fill="#%s" />]]):format(
                    table.concat(shape.points, " "),
                    shape.color
                )
        end
    end
    local k
    if sizeMode == 'w' then
        k = targetSize / maxX
    elseif sizeMode == 'h' then
        k = targetSize / maxY
    else
        error("Invalid size mode")
    end
    return string.format(
        [[<svg width="%d" height="%d" viewBox="0 0 %f %f" xmlns="http://www.w3.org/2000/svg"> %s </svg>]],
        math.ceil(k * maxX),
        math.ceil(k * maxY),
        string.format("%.4g", maxX),
        string.format("%.4g", maxY),
        shapeData
    )
end

if #arg == 0 then
    print("Usage: lua chord.lua <chord1> <chord2> ...")
else
    local count = 0
    local sizeMode, targetSize = 'w', 256
    for i = 1, #arg do
        if arg[i] and arg[i]:match("^[wh]=%d+$") then
            sizeMode = arg[i]:sub(1, 1)
            targetSize = tonumber(arg[i]:match("%d+"))
        else
            local chordStr = arg[i]
            local chord = SsvtDecode(chordStr)
            local svgData = toSvg(DrawChord(chord), sizeMode, targetSize)
            count = count + 1
            local fileName = count .. ".svg"
            io.open(fileName, "w"):write(svgData):close()
        end
    end
    print("SVG files generated successfully.")
end
