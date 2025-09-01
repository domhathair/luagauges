---digitmeter.lua

--[[
    ———a———
   |       |
   f       b
   |       |
    ———g———
   |       |
   e       c
   |       |
    ———d———
]]

local iup = require("iuplua")
local gauges = require("gauges")

local segmap = {
    ["0"] = { "a", "b", "c", "d", "e", "f" },
    ["1"] = { "b", "c" },
    ["2"] = { "a", "b", "d", "e", "g" },
    ["3"] = { "a", "b", "c", "d", "g" },
    ["4"] = { "b", "c", "f", "g" },
    ["5"] = { "a", "c", "d", "f", "g" },
    ["6"] = { "a", "c", "d", "e", "f", "g" },
    ["7"] = { "a", "b", "c" },
    ["8"] = { "a", "b", "c", "d", "e", "f", "g" },
    ["9"] = { "a", "b", "c", "d", "f", "g" },
    [":"] = { "a", "d" },
    [";"] = { "b", "d" },
    ["<"] = { "a", "f", "g" },
    ["="] = { "d", "g" },
    [">"] = { "a", "b", "g" },
    ["?"] = { "a", "b", "g" },
    ["@"] = { "a", "b", "c", "e" },
    ["A"] = { "a", "b", "c", "d", "e", "g" },
    ["B"] = { "c", "d", "e", "f", "g" },
    ["C"] = { "d", "e", "g" },
    ["D"] = { "b", "c", "d", "e", "g" },
    ["E"] = { "a", "d", "e", "f", "g" },
    ["F"] = { "a", "e", "f", "g" },
    ["G"] = { "a", "c", "d", "e", "f" },
    ["H"] = { "c", "e", "f", "g" },
    ["I"] = { "a", "e" },
    ["J"] = { "a", "c", "d" },
    ["K"] = { "a", "c", "e", "f", "g" },
    ["L"] = { "d", "e", "f" },
    ["M"] = { "a", "c", "e", "g" },
    ["N"] = { "c", "e", "g" },
    ["O"] = { "c", "d", "e", "g" },
    ["P"] = { "a", "b", "e", "f", "g" },
    ["Q"] = { "a", "b", "c", "f", "g" },
    ["R"] = { "e", "g" },
    ["S"] = { "a", "c", "d", "f" },
    ["T"] = { "d", "e", "f", "g" },
    ["U"] = { "c", "d", "e" },
    ["V"] = { "b", "d", "f" },
    ["W"] = { "b", "d", "f", "g" },
    ["X"] = { "c", "e" },
    ["Y"] = { "b", "c", "d", "f", "g" },
    ["Z"] = { "a", "b", "d", "e" },
    ["["] = { "a", "d", "e", "f" },
    ["\\"] = { "c", "f" },
    ["]"] = { "a", "b", "c", "d" },
    ["^"] = { "a" },
    ["_"] = { "d" },
    ["`"] = { "f" },
    ["a"] = { "a", "b", "c", "d", "e", "g" },
    ["b"] = { "c", "d", "e", "f", "g" },
    ["c"] = { "d", "e", "g" },
    ["d"] = { "b", "c", "d", "e", "g" },
    ["e"] = { "a", "d", "e", "f", "g" },
    ["f"] = { "a", "e", "f", "g" },
    ["g"] = { "a", "c", "d", "e", "f" },
    ["h"] = { "c", "e", "f", "g" },
    ["i"] = { "a", "e" },
    ["j"] = { "a", "c", "d" },
    ["k"] = { "a", "c", "e", "f", "g" },
    ["l"] = { "d", "e", "f" },
    ["m"] = { "a", "c", "e", "g" },
    ["n"] = { "c", "e", "g" },
    ["o"] = { "c", "d", "e", "g" },
    ["p"] = { "a", "b", "e", "f", "g" },
    ["q"] = { "a", "b", "c", "f", "g" },
    ["r"] = { "e", "g" },
    ["s"] = { "a", "c", "d", "f" },
    ["t"] = { "d", "e", "f", "g" },
    ["u"] = { "c", "d", "e" },
    ["v"] = { "b", "d", "f" },
    ["w"] = { "b", "d", "f", "g" },
    ["x"] = { "c", "e" },
    ["y"] = { "b", "c", "d", "f", "g" },
    ["z"] = { "a", "b", "d", "e" },
    ["-"] = { "g" },
    [" "] = {},
    ["."] = { "." },
}

local shapes = {
    ["a"] = { lo = "h", coor = { 0.150, 0.075, 0.850, 0.125 } },
    ["b"] = { lo = "v", coor = { 0.850, 0.175, 0.950, 0.425 } },
    ["c"] = { lo = "v", coor = { 0.850, 0.575, 0.950, 0.825 } },
    ["d"] = { lo = "h", coor = { 0.150, 0.875, 0.850, 0.925 } },
    ["e"] = { lo = "v", coor = { 0.050, 0.575, 0.150, 0.825 } },
    ["f"] = { lo = "v", coor = { 0.050, 0.175, 0.150, 0.425 } },
    ["g"] = { lo = "h", coor = { 0.150, 0.475, 0.850, 0.525 } },
    ["."] = { lo = "h", coor = { 0.800, 0.875, 0.900, 0.925 } },
}

local function snap(v) return math.floor(v + 0.5) end

local function drawch(self, ch, x, y, cellw, cellh)
    local segs = segmap[ch] or {}

    for _, seg in ipairs(segs) do
        local lo = shapes[seg].lo
        local coor = shapes[seg].coor

        local pts = {}
        for i = 1, #coor, 2 do
            local px, py = snap(x + coor[i] * cellw), snap(y + coor[i + 1] * cellh)

            table.insert(pts, px)
            table.insert(pts, py)
        end

        local farc, sarc = {}, {}
        if lo == "h" then
            local radius = (pts[4] - pts[2]) / 2
            farc = { pts[1] - radius, pts[2], pts[1] + radius, pts[4] }
            sarc = { pts[3] - radius, pts[2], pts[3] + radius, pts[4] }
        else
            local radius = (pts[3] - pts[1]) / 2
            farc = { pts[1], pts[2] - radius, pts[3], pts[2] + radius }
            sarc = { pts[1], pts[4] - radius, pts[3], pts[4] + radius }
        end

        gauges.drawrectangle(self, gauges.unpack(pts))
        gauges.drawarc(self, gauges.unpack(farc))
        gauges.drawarc(self, gauges.unpack(sarc))
    end
end

---@class digitmeter_flags
---@field color string
---@field format string
---@field spacing number
---@field margin integer
---@field height integer
---@field scale number

---![](../images/digitmeter.png)
---@param self canvas
---@param value any
---@param flags? digitmeter_flags
function gauges.digitmeter(self, value, flags)
    flags         = flags or {}
    local format  = flags.format or "%d"
    local color   = flags.color or iup.GetGlobal("TXTFGCOLOR")
    local spacing = flags.spacing or 0.18
    local margin  = flags.margin or 8
    local height  = flags.height or nil
    local scale   = flags.scale or 1.0

    local w, h    = self:DrawGetSize()

    local text    = string.format(format, value)
    local n       = #text
    if n == 0 then return end

    local rdigit = 0.56
    local rdot   = 0.32
    local rspace = 0.40

    local units  = 0.0
    for i = 1, n do
        local ch = text:sub(i, i)
        if ch == "." then
            units = units + rdot
        elseif ch == " " then
            units = units + rspace
        else
            units = units + rdigit
        end
    end

    local availw = math.max(1, w - 2 * margin)
    local availh = math.max(1, h - 2 * margin)

    local denom = units + math.max(0, n - 1) * spacing
    local hbywidth = (denom > 0) and (availw / denom) or availh
    local chh = (height and math.min(height, availh) or math.min(availh, hbywidth)) * scale
    chh = math.max(1, math.floor(chh + 0.5))

    local gap = math.max(0, snap(spacing * chh))

    local cellw = {}
    local totalw = 0
    for i = 1, n do
        local ch = text:sub(i, i)
        local cw = math.floor((ch == ".") and (rdot * chh)
            or (ch == " " and rspace * chh)
            or (rdigit * chh) + 0.5)
        cw = math.max(1, cw)
        cellw[i] = cw
        totalw = totalw + cw
        if i < n then totalw = totalw + gap end
    end

    if totalw > availw then
        local scaledown = availw / totalw
        chh = math.max(1, math.floor(chh * scaledown + 0.5))
        gap = math.max(0, snap(spacing * chh))
        totalw = 0
        for i = 1, n do
            local ch = text:sub(i, i)
            local cw = math.floor((ch == ".") and (rdot * chh)
                or (ch == " " and rspace * chh)
                or (rdigit * chh) + 0.5)
            cw = math.max(1, cw)
            cellw[i] = cw
            totalw = totalw + cw
            if i < n then totalw = totalw + gap end
        end
    end

    local startx = snap(margin + (availw - totalw) / 2)
    local starty = snap(margin + (availh - chh) / 2)

    gauges.style(self, color, nil, "FILL")

    local x = startx
    for i = 1, n do
        local ch = text:sub(i, i)
        local cw = cellw[i]
        drawch(self, ch, x, starty, cw, chh)
        x = x + cw
        if i < n then x = x + gap end
    end
end

return gauges
