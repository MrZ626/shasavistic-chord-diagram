local standalone = true

if #({ ... }) == #arg then
    local _arg = { ... }
    for i = 1, #arg do
        if _arg[i] ~= arg[i] then
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

local ins = table.insert

---@alias SSVT.Dim number

---@class SSVT.Chord
---@field d? SSVT.Dim
---@field note? 'skip' | 'dotted'
---@field bias? 'l' | 'r'
---@field bass? true
---@field [number] SSVT.Chord

---@class SSVT.Shape
---@field mode 'polygon' | 'path'
---@field _layer number
---@field color string
---@field points (string | number)[]

---@type SSVT.Shape[]
local drawBuffer

---@class SSVT.Environment
local env = {
    beamW = .1,      -- Beam width
    noteW = .014,    -- Note width
    svgW = 128,      -- SVG width, -1 = auto
    svgH = -1,       -- SVG height, -1 = auto
    bgColor = false, -- 524E61
}

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

    ins(drawBuffer, {
        mode = mode,
        _layer = layer,
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
                x, -env.noteW / 2,
                x + w, -env.noteW / 2,
                x + w, env.noteW / 2,
                x, env.noteW / 2
            )
        end
    elseif mode == 'skip' then
        -- Short line
        x1, x2 = lerp(x1, x2, .3), lerp(x2, x1, .3)
        addShape('polygon', "808080", 0,
            x1 + .05, -env.noteW / 2,
            x2 - .05, -env.noteW / 2,
            x2 - .05, env.noteW / 2,
            x1 + .05, env.noteW / 2
        )
    else
        -- Line
        addShape('polygon', "F0F0F0", 0,
            x1 + .05, -env.noteW / 2,
            x2 - .05, -env.noteW / 2,
            x2 - .05, env.noteW / 2,
            x1 + .05, env.noteW / 2
        )
    end
end

local function drawBeam(color, mode, x1, y1, x2, y2)
    if mode == 'none' then return end
    if mode == 'arrow' then
        local m = (x1 + x2) / 2
        addShape('polygon', color, 1,
            m, y1,
            m + env.beamW * .8, y1 * .9 + y2 * .1,
            m + env.beamW * .2, y1 * .9 + y2 * .1,
            m + env.beamW * .2, y2,
            m - env.beamW * .2, y2,
            m - env.beamW * .2, y1 * .9 + y2 * .1,
            m - env.beamW * .8, y1 * .9 + y2 * .1
        )
    else
        if y1 > y2 then y1, y2 = y2, y1 end
        y1, y2 = y1 - env.noteW / 2, y2 + env.noteW / 2
        if mode == 'left' then
            addShape('polygon', color, 2,
                x1, y1,
                x1, y2,
                x1 + env.beamW, y2,
                x1 + env.beamW, y1
            )
        elseif mode == 'right' then
            addShape('polygon', color, 2,
                x2, y1,
                x2, y2,
                x2 - env.beamW, y2,
                x2 - env.beamW, y1
            )
        elseif mode == 'mid' then
            local m = (x1 + x2) / 2
            addShape('polygon', color, 2,
                m - env.beamW / 4, y1,
                m + env.beamW / 4, y1,
                m + env.beamW / 4, y2,
                m - env.beamW / 4, y2
            )
        elseif mode == 'rise' then
            addShape('polygon', color, 3,
                x1, y1,
                x1 + env.beamW * 1.26, y1,
                x2, y2,
                x2 - env.beamW * 1.26, y2
            )
        elseif mode == 'fall' then
            addShape('polygon', color, 3,
                x2, y1,
                x2 - env.beamW * 1.1, y1,
                x1, y2,
                x1 + env.beamW * 1.1, y2
            )
        elseif mode == 'arcleft' then
            addShape('path', color, 4,
                "M", x1, y1,
                "Q", x1 - 2.6 * env.beamW, (y1 + y2) / 2, x1, y2,
                "L", x1 + env.beamW, y2,
                "Q", x1 + env.beamW - 2.6 * env.beamW, (y1 + y2) / 2, x1 + env.beamW, y1,
                "Z"
            )
        elseif mode == 'arcright' then
            addShape('path', color, 4,
                "M", x2, y1,
                "Q", x2 + 2.6 * env.beamW, (y1 + y2) / 2, x2, y2,
                "L", x2 - env.beamW, y2,
                "Q", x2 - env.beamW + 2.6 * env.beamW, (y1 + y2) / 2, x2 - env.beamW, y1,
                "Z"
            )
        else
            error("Unknown beam style: " .. mode)
        end
    end
end

---@param chord SSVT.Chord
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

---@param chord SSVT.Chord
local function drawChord(chord)
    drawBuffer = {}
    DrawBranch(chord, 0, 1)
    table.sort(drawBuffer, function(a, b) return a._layer < b._layer end)
    return drawBuffer
end

---@param str string
---@return SSVT.Chord
local function decode(str)
    ---@type SSVT.Chord
    local buf = { d = 0 }
    local note = str:match("^%-?%d+")
    if note then
        buf.d = tonumber(note:match("%-?%d+"))
        str = str:sub(#note + 1)
    end
    while true do
        local char = str:sub(1, 1)
        if char == '.' then
            if math.abs(buf.d) == 1 then
                buf.note = 'skip'
            else
                buf.note = 'dotted'
            end
        elseif char == 'l' or char == 'r' then
            buf.bias = char
        elseif char == 'x' then
            buf.bass = true
        else
            break
        end
        str = str:sub(2)
    end
    local branch = string.match(str, "%b()")
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
                ins(resStrings, branch:sub(start, i - 1))
                start = i + 1
            end
        end
        ins(resStrings, branch:sub(start))
        for i = 1, #resStrings do
            ins(buf, decode(resStrings[i]))
        end
    end
    return buf
end

---@param chord SSVT.Chord
---@return string
local function encode(chord)
    local str = {}
    if chord.d then ins(str, chord.d) end
    if chord.bass then ins(str, "x") end
    if chord.bias then ins(str, chord.bias) end
    if chord.note then ins(str, ".") end
    if chord[1] then
        ins(str, "(")
        for i = 1, #chord do
            ins(str, encode(chord[i]))
            if i < #chord then
                ins(str, ",")
            end
        end
        ins(str, ")")
    end
    return table.concat(str)
end

---@param data SSVT.Shape[]
local function toSVG(data)
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
    if env.svgW > 0 then kx = env.svgW / maxX end
    if env.svgH > 0 then ky = env.svgH / maxY end
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
        env.bgColor and ([[<rect width="100%%" height="100%%" fill="#%s" />]]):format(env.bgColor) or "",
        shapeData
    )
end

if not standalone then
    return {
        env = env,
        dimData = dimData,
        decode = decode,
        encode = encode,
        drawChord = drawChord,
        toSVG = toSVG,
    }
end

local count = 0
for i = 1, #arg do
    if arg[i]:match("^bw=.+") then
        env.beamW = tonumber(arg[i]:match("=(.+)")) or env.beamW
    elseif arg[i]:match("^bh=.+") then
        env.bh = tonumber(arg[i]:match("=(.+)")) or env.bh
    elseif arg[i]:match("^w=%-?%d+") then
        env.svgW = tonumber(arg[i]:match("%-?%d+"))
    elseif arg[i]:match("^h=%-?%d+") then
        env.svgH = tonumber(arg[i]:match("%-?%d+"))
    elseif arg[i]:match("^bg=%x%x%x%x%x%x$") then
        env.bgColor = arg[i]:match("%x%x%x%x%x%x")
    elseif arg[i] == 'nobg' then
        env.bgColor = false
    else
        local chordStr = arg[i]
        local chord = decode(chordStr)
        local svgData = toSVG(drawChord(chord))
        count = count + 1
        local fileName = count .. ".svg"
        io.open(fileName, "w"):write(svgData):close()
    end
end
print(count .. " x SVG generated successfully.")
