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

---Alexander Fakoó's Siekoo alphabet
---![](https://fakoo.de/en/siekoo/siekoo-alphabet.gif)
local siekoo = {
    ["0"] = { 1, 2, 3, 4, 5, 6 },
    ["1"] = { 2, 3 },
    ["2"] = { 1, 2, 4, 5, 7 },
    ["3"] = { 1, 2, 3, 4, 7 },
    ["4"] = { 2, 3, 6, 7 },
    ["5"] = { 1, 3, 4, 6, 7 },
    ["6"] = { 1, 3, 4, 5, 6, 7 },
    ["7"] = { 1, 2, 3 },
    ["8"] = { 1, 2, 3, 4, 5, 6, 7 },
    ["9"] = { 1, 2, 3, 4, 6, 7 },
    [":"] = { 1, 4 },
    [";"] = { 2, 4 },
    ["<"] = { 1, 6, 7 },
    ["="] = { 4, 7 },
    [">"] = { 1, 2, 7 },
    ["?"] = { 1, 2, 7 },
    ["@"] = { 1, 2, 3, 5 },
    ["A"] = { 1, 2, 3, 4, 5, 7 },
    ["B"] = { 3, 4, 5, 6, 7 },
    ["C"] = { 4, 5, 7 },
    ["D"] = { 2, 3, 4, 5, 7 },
    ["E"] = { 1, 4, 5, 6, 7 },
    ["F"] = { 1, 5, 6, 7 },
    ["G"] = { 1, 3, 4, 5, 6 },
    ["H"] = { 3, 5, 6, 7 },
    ["I"] = { 1, 5 },
    ["J"] = { 1, 3, 4 },
    ["K"] = { 1, 3, 5, 6, 7 },
    ["L"] = { 4, 5, 6 },
    ["M"] = { 1, 3, 5, 7 },
    ["N"] = { 3, 5, 7 },
    ["O"] = { 3, 4, 5, 7 },
    ["P"] = { 1, 2, 5, 6, 7 },
    ["Q"] = { 1, 2, 3, 6, 7 },
    ["R"] = { 5, 7 },
    ["S"] = { 1, 3, 4, 6 },
    ["T"] = { 4, 5, 6, 7 },
    ["U"] = { 3, 4, 5 },
    ["V"] = { 2, 4, 6 },
    ["W"] = { 2, 4, 6, 7 },
    ["X"] = { 3, 5 },
    ["Y"] = { 2, 3, 4, 6, 7 },
    ["Z"] = { 1, 2, 4, 5 },
    ["["] = { 1, 4, 5, 6 },
    ["\\"] = { 3, 6 },
    ["]"] = { 1, 2, 3, 4 },
    ["^"] = { 1 },
    ["_"] = { 4 },
    ["`"] = { 6 },
    ["a"] = { 1, 2, 3, 4, 5, 7 },
    ["b"] = { 3, 4, 5, 6, 7 },
    ["c"] = { 4, 5, 7 },
    ["d"] = { 2, 3, 4, 5, 7 },
    ["e"] = { 1, 4, 5, 6, 7 },
    ["f"] = { 1, 5, 6, 7 },
    ["g"] = { 1, 3, 4, 5, 6 },
    ["h"] = { 3, 5, 6, 7 },
    ["i"] = { 1, 5 },
    ["j"] = { 1, 3, 4 },
    ["k"] = { 1, 3, 5, 6, 7 },
    ["l"] = { 4, 5, 6 },
    ["m"] = { 1, 3, 5, 7 },
    ["n"] = { 3, 5, 7 },
    ["o"] = { 3, 4, 5, 7 },
    ["p"] = { 1, 2, 5, 6, 7 },
    ["q"] = { 1, 2, 3, 6, 7 },
    ["r"] = { 5, 7 },
    ["s"] = { 1, 3, 4, 6 },
    ["t"] = { 4, 5, 6, 7 },
    ["u"] = { 3, 4, 5 },
    ["v"] = { 2, 4, 6 },
    ["w"] = { 2, 4, 6, 7 },
    ["x"] = { 3, 5 },
    ["y"] = { 2, 3, 4, 6, 7 },
    ["z"] = { 1, 2, 4, 5 },
    ["-"] = { 7 },
    [" "] = {},
    ["."] = { 8 },
}

local shapes = {
    [1] = { lo = "h", coor = { 0.150, 0.075, 0.850, 0.125 } },
    [2] = { lo = "v", coor = { 0.850, 0.175, 0.950, 0.425 } },
    [3] = { lo = "v", coor = { 0.850, 0.575, 0.950, 0.825 } },
    [4] = { lo = "h", coor = { 0.150, 0.875, 0.850, 0.925 } },
    [5] = { lo = "v", coor = { 0.050, 0.575, 0.150, 0.825 } },
    [6] = { lo = "v", coor = { 0.050, 0.175, 0.150, 0.425 } },
    [7] = { lo = "h", coor = { 0.150, 0.475, 0.850, 0.525 } },
    [8] = { lo = "d", coor = { 0.800, 0.875, 0.900, 0.925 } },
}

local function snap(v) return math.floor(v + 0.5) end

---Internal: draw a single character using a 7-seg like geometry
---@param self canvas
---@param ch string
---@param x number
---@param y number
---@param w number
---@param h number
local function draw_ch(self, ch, x, y, w, h)
    local on = siekoo[ch] or {}
    if not on then -- unknown chars become blanks
        return
    end

    for _, seg in ipairs(on) do
        local lo = shapes[seg].lo
        local coor = shapes[seg].coor

        local pts = {}
        for i = 1, #coor, 2 do
            table.insert(pts, snap(x + coor[i] * w))
            table.insert(pts, snap(y + coor[i + 1] * h))
        end

        local farc, sarc = {}, {}
        if lo == "v" then
            local radius = (pts[3] - pts[1]) / 2
            farc = { pts[1], pts[2] - radius, pts[3], pts[2] + radius }
            sarc = { pts[1], pts[4] - radius, pts[3], pts[4] + radius }
        else
            local radius = (pts[4] - pts[2]) / 2
            farc = { pts[1] - radius, pts[2], pts[1] + radius, pts[4] }
            sarc = { pts[3] - radius, pts[2], pts[3] + radius, pts[4] }
        end

        gauges.drawrectangle(self, gauges.unpack(pts))
        if lo ~= "d" then
            gauges.drawarc(self, gauges.unpack(farc))
            gauges.drawarc(self, gauges.unpack(sarc))
        end
    end
end

---@class digitmeter_flags
---@field size table
---@field color string
---@field format string
---@field spacing number     -- gap factor relative to char height (0..1)
---@field margin integer
---@field height integer
---@field scale number
---@field r_digit number     -- width/height ratio for digits
---@field r_dot number       -- width/height ratio for '.'
---@field r_space number     -- width/height ratio for ' '

---Draw seven-seg style text/number centered inside bounds.
---![](../images/digitmeter.png)
---@param self canvas
---@param value any
---@param flags? digitmeter_flags
function gauges.digitmeter(self, value, flags)
    flags         = flags or {}

    local size    = flags.size or { self:DrawGetSize() }
    local format  = flags.format or "%d"
    local color   = flags.color or iup.GetGlobal("TXTFGCOLOR")
    local spacing = flags.spacing or 0.18
    local margin  = flags.margin or 8
    local height  = flags.height or nil
    local scale   = flags.scale or 1.0
    local r_digit = flags.r_digit or 0.56
    local r_dot   = flags.r_dot or 0.32
    local r_space = flags.r_space or 0.40

    local w, h    = gauges.unpack(size)
    local text    = string.format(format, value)
    local n       = #text
    if n == 0 then return end

    local units = 0.0
    for i = 1, n do
        local ch = text:sub(i, i)
        if ch == "." then
            units = units + r_dot
        elseif ch == " " then
            units = units + r_space
        else
            units = units + r_digit
        end
    end

    local availw, availh = math.max(1, w - 2 * margin), math.max(1, h - 2 * margin)
    local denom = units + math.max(0, n - 1) * spacing
    local hbywidth = (denom > 0) and (availw / denom) or availh

    local chh = math.max(1, snap((height and math.min(height, availh) or math.min(availh, hbywidth)) * scale))
    local gap = math.max(0, snap(spacing * chh))

    local cellw, totalw = {}, 0
    local function measure()
        cellw, totalw = {}, 0
        for i = 1, n do
            local ch = text:sub(i, i)
            local cw =
                math.floor(((ch == ".") and (r_dot * chh))
                    or ((ch == " ") and (r_space * chh))
                    or (r_digit * chh) + 0.5)
            cw = math.max(1, cw)
            cellw[i] = cw
            totalw = totalw + cw + ((i < n) and gap or 0)
        end
    end

    measure()
    if totalw > availw then
        local scaledown = availw / totalw
        chh = math.max(1, math.floor(chh * scaledown + 0.5))
        gap = math.max(0, math.floor(spacing * chh + 0.5))
        measure()
    end

    local startx = snap(margin + (availw - totalw) / 2)
    local starty = snap(margin + (availh - chh) / 2)

    gauges.style(self, color, nil, "FILL")

    local x = startx
    for i = 1, n do
        draw_ch(self, text:sub(i, i), x, starty, cellw[i], chh)
        x = x + cellw[i] + ((i < n) and gap or 0)
    end
end

return gauges
