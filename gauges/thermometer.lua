---thermometer.lua

local iup = require("iuplua")
local gauges = require("gauges")

---@class thermometer_mask
---@field notube boolean
---@field nofluid boolean
---@field noticks boolean
---@field nodigital boolean

---@class thermometer_flags
---@field size table
---@field fluid_color string     -- RGBA string for fluid
---@field tube_color string      -- stroke color for tube & ticks
---@field width integer
---@field style canvas.style
---@field postfix string
---@field format string
---@field major_ticks integer
---@field minor_ticks integer
---@field divider number         -- min, max and value divider

---Draw a vertical thermometer.
---![](../images/thermometer.png)
---@param self canvas
---@param min number
---@param max number
---@param value number
---@param flags? thermometer_flags
---@param mask? thermometer_mask
function gauges.thermometer(self, min, max, value, flags, mask)
    flags = flags or {}
    mask = mask or {}

    if max <= min then
        max = min + 1
    end

    if mask.notube and mask.nofluid and mask.noticks and mask.nodigital then return end

    local size      = flags.size or { self:DrawGetSize() }
    local fcolor    = flags.fluid_color or "200 22 22 200" -- RGBA
    local tcolor    = flags.tube_color or iup.GetGlobal("TXTFGCOLOR")
    local width     = flags.width or 2
    local style     = flags.style or "STROKE"
    local postfix   = flags.postfix
    local format    = flags.format or "%.1f"
    local major     = math.max(1, flags.major_ticks or 10)
    local minor     = math.max(0, flags.minor_ticks or 5)
    local divider   = flags.divider or 1

    min, max, value =
        min / divider,
        max / divider,
        value / divider

    local w, h      = gauges.unpack(size)
    local thinw     = math.max(1, math.floor(width / 2))

    local margin    = math.floor(w * 0.10)
    local tube      = {}
    tube.w          = (w / 2) - margin
    tube.h          = h * 0.8
    tube.x1         = margin
    tube.y1         = h * 0.1
    tube.x2         = tube.x1 + tube.w
    tube.y2         = tube.y1 + tube.h

    local ratio     = gauges.norm(min, max, value)

    if not mask.nofluid then
        gauges.style(self, fcolor, thinw, "FILL")
        local fill_y = tube.y2 - ratio * tube.h
        if fill_y < tube.y2 - width then
            gauges.drawrectangle(self, tube.x1 + thinw, fill_y, tube.x2 - width, tube.y2 - width)
        end
    end

    local tw, th, tc = nil, nil, {}
    if not mask.nodigital then
        gauges.style(self, tcolor, width, style)
        local dig_y = tube.y1 + tube.h / 2
        local txt = string.format(format .. "%s", value, postfix and (" " .. postfix) or "")
        tw, th = self:DrawGetTextSize(txt)
        gauges.textstyle(self, { alignment = "ACENTER", wrap = "NO", ellipsis = "YES" }, function()
            gauges.drawtext(self, txt, tube.x1, dig_y - th / 2, tube.w, th)
        end)
        tc = { dig_y - th / 2, dig_y + th / 2 }
    end

    if not mask.notube then
        gauges.style(self, tcolor, width, style)
        gauges.drawrectangle(self, tube.x1, tube.y1, tube.x2, tube.y2)
        if min < 0 then
            local zero_y = tube.y2 - (0 - min) / (max - min) * tube.h
            gauges.style(self, tcolor, thinw, "STROKE_DOT")
            if th and tc and zero_y > tc[1] and zero_y < tc[2] then
                local pad = tw / 2 + tw * 0.1
                gauges.drawline(self, tube.x1, zero_y, tube.x1 + tube.w / 2 - pad, zero_y)
                gauges.drawline(self, tube.x1 + tube.w / 2 + pad, zero_y, tube.x2, zero_y)
            else
                gauges.drawline(self, tube.x1, zero_y, tube.x2, zero_y)
            end
        end
    end

    if not mask.noticks then
        gauges.style(self, tcolor, thinw, style)
        local step_h    = tube.h / major
        local sub_step  = (minor > 0) and (step_h / minor) or 0
        local major_len = math.max(8, math.floor(tube.w * 0.08))
        local minor_len = math.max(4, math.floor(tube.w * 0.025))
        local shift     = math.max(4, math.floor(tube.w * 0.025))

        for i = 0, major do
            local y = tube.y2 - i * step_h
            gauges.drawline(self, tube.x2 + shift, y, tube.x2 + shift + major_len, y)
            local val = min + (max - min) * (i / major)
            local txt = string.format(format, (format == "%d") and math.floor(val + 0.5) or val)
            tw, th = self:DrawGetTextSize(txt)
            gauges.drawtext(self, txt, tube.x2 + shift + major_len + shift, y - th / 2)

            if i < major and minor > 0 then
                for j = 1, minor - 1 do
                    local sy = y - sub_step * j
                    gauges.drawline(self, tube.x2 + shift, sy, tube.x2 + shift + minor_len, sy)
                end
            end
        end
    end
end

return gauges
