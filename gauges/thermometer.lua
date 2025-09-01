---thermometer.lua

local iup = require("iuplua")
local gauges = require("gauges")

---@class thermometer_mask
---@field notube boolean
---@field nofluid boolean
---@field nocount boolean
---@field nodigital boolean

---@class thermometer_flags
---@field size table
---@field fcolor string #Fluid color
---@field tcolor string #Tube color
---@field width integer
---@field style canvas.style
---@field postfix string
---@field format string
---@field cmajor integer
---@field cminor integer
---@field mask thermometer_mask

---![](../images/thermometer.png)
---@param self canvas
---@param min integer
---@param max integer
---@param current integer
---@param flags? thermometer_flags
function gauges.thermometer(self, min, max, current, flags)
    flags = flags or {}

    if flags.mask
        and flags.mask.notube
        and flags.mask.nofluid
        and flags.mask.nocount
        and flags.mask.nodigital then
        ---There is nothing to do
        return
    end

    local size = flags.size or { self:DrawGetSize() }
    local fcolor = flags.fcolor or "200 22 22 200" ---RGBA
    local tcolor = flags.tcolor or iup.GetGlobal("TXTFGCOLOR")
    local width = flags.width or 2
    local style = flags.style or "STROKE"
    local postfix = flags.postfix or nil
    local format = flags.format or "%.1f"
    local cmajor = flags.cmajor or 10
    local cminor = flags.cminor or 5

    local w, h = gauges.unpack(size)
    local thinw = math.max(1, width / 2)

    local margin = math.floor(w * 0.1)
    local tube = {}
    tube.w = (w / 2) - margin
    tube.h = h * 0.8
    tube.x1 = margin
    tube.y1 = h * 0.1
    tube.x2 = tube.x1 + tube.w
    tube.y2 = tube.y1 + tube.h

    local ratio = math.min(math.max((current - min) / (max - min), 0), 1)

    if flags.mask and flags.mask.nofluid then else
        local filly = tube.y2 - ratio * tube.h
        if filly < tube.y2 - width then
            gauges.style(self, fcolor, thinw, "FILL")
            gauges.drawrectangle(self, tube.x1 + thinw, filly, tube.x2 - width, tube.y2 - width)
        end
    end

    if flags.mask and flags.mask.notube then else
        gauges.style(self, tcolor, width, style)
        gauges.drawrectangle(self, tube.x1, tube.y1, tube.x2, tube.y2)
        if min < 0 then
            local zeroy = tube.y2 - (0 - min) / (max - min) * tube.h
            gauges.style(self, tcolor, thinw, "STROKE_DOT")
            gauges.drawline(self, tube.x1, zeroy, tube.x2, zeroy)
        end
    end

    if flags.mask and flags.mask.nocount then else
        gauges.style(self, tcolor, thinw, style)
        local steph = tube.h / cmajor
        local substeph = steph / cminor
        local majorlen = math.max(8, math.floor(tube.w * 0.08))
        local minorlen = math.max(4, math.floor(tube.w * 0.025))
        local countshift = math.max(4, math.floor(tube.w * 0.025))
        for i = 0, cmajor do
            local y = tube.y2 - i * steph
            gauges.drawline(self, tube.x2 + countshift, y, tube.x2 + countshift + majorlen, y)
            local val = min + (max - min) * (i / cmajor)
            local txt = string.format(format, format == "%d" and math.floor(val + 0.5) or val)
            local _, txth = self:DrawGetTextSize(txt)
            gauges.drawtext(self, txt, tube.x2 + countshift + majorlen + countshift, y - txth / 2)
            if i < cmajor then
                if cminor > 1 then
                    for j = 1, cminor - 1 do
                        local suby = y - substeph * j
                        gauges.drawline(self, tube.x2 + countshift, suby, tube.x2 + countshift + minorlen, suby)
                    end
                end
            end
        end
    end

    if flags.mask and flags.mask.nodigital then else
        local digiy = tube.y1 + tube.h / 2

        local txt = string.format(format .. "%s", current, postfix and (" " .. postfix) or "")
        local _, txth = self:DrawGetTextSize(txt)

        gauges.textstyle(self, { alignment = "ACENTER", wrap = "NO", ellipsis = "YES" }, function()
            gauges.drawtext(self, txt, tube.x1, digiy - txth / 2, tube.w, txth)
        end)
    end
end

return gauges
