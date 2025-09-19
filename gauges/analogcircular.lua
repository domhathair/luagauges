---analogcircular.lua

local iup = require("iuplua")
local gauges = require("gauges")

---@class analogcircular_mask
---@field noarc boolean
---@field noticks boolean
---@field noneedle boolean
---@field nodigital boolean
---@field noframe boolean

---@class analogcircular_flags
---@field size table             -- {w, h} or result of canvas:DrawGetSize()
---@field color string           -- draw color (text/lines)
---@field width integer          -- stroke width
---@field style canvas.style     -- "STROKE" or "FILL" styles
---@field postfix string         -- unit suffix for digital text
---@field format string          -- lua string.format format for labels
---@field major_ticks integer    -- major tick count
---@field minor_ticks integer    -- minor ticks between majors
---@field mask analogcircular_mask

---Draw a circular analog gauge.
---![](../images/analogcircular.png)
---@param self canvas
---@param min number
---@param max number
---@param value number
---@param flags? analogcircular_flags
---@param mask? analogcircular_mask
function gauges.analogcircular(self, min, max, value, flags, mask)
    flags = flags or {}
    mask = mask or {}

    if mask.noarc and mask.noticks and mask.noneedle and mask.nodigital then return end

    local size    = flags.size or { self:DrawGetSize() }
    local color   = flags.color or iup.GetGlobal("TXTFGCOLOR")
    local width   = flags.width or 2
    local style   = flags.style or "STROKE"
    local postfix = flags.postfix
    local format  = flags.format or "%d"
    local major   = math.max(1, flags.major_ticks or 10)
    local minor   = math.max(0, flags.minor_ticks or 5)

    local w, h    = gauges.unpack(size)
    local cx, cy  = w * 0.5, h * 0.5
    local radius  = math.min(w, h) * 0.35
    local label_r = radius + math.max(10, math.floor(radius * 0.1)) + 5
    local frame_r = label_r + math.max(10, math.floor(label_r * 0.1)) + 5

    gauges.style(self, color, width, style)

    local ratio = gauges.norm(min, max, value)

    local function hour_to_deg(hh) return (hh - 3) * 30 end
    local start_deg = hour_to_deg(7.5)
    local end_deg   = hour_to_deg(4.5)
    local span_deg  = end_deg - start_deg; if span_deg <= 0 then span_deg = span_deg + 360 end

    local function tick_at_angle(angle_deg, r_outer, r_inner, w_override)
        local rad = math.rad(angle_deg)
        local x1 = cx + r_outer * math.cos(rad)
        local y1 = cy + r_outer * math.sin(rad)
        local x2 = cx + r_inner * math.cos(rad)
        local y2 = cy + r_inner * math.sin(rad)
        gauges.style(self, color, w_override or width, style)
        gauges.drawline(self, x1, y1, x2, y2)
        gauges.style(self, color, width, style)
    end

    if not mask.noarc then
        local a1, a2 = 360 - end_deg, 360 - start_deg -- counter-clockwise from 3 o'clock
        gauges.drawarc(self, cx - radius, cy - radius, cx + radius, cy + radius, a1, a2)
    end

    local major_len = math.max(8, math.floor(radius * 0.12))
    local minor_len = math.max(4, math.floor(radius * 0.06))

    if not mask.noticks then
        for i = 0, major do
            local ang = start_deg + (span_deg / major) * i
            tick_at_angle(ang, radius, radius - major_len, width)

            local lx = cx + label_r * math.cos(math.rad(ang))
            local ly = cy + label_r * math.sin(math.rad(ang))
            local val = min + (max - min) * (i / major)
            local txt = string.format(format, (format == "%d") and math.floor(val + 0.5) or val)
            local tw, th = self:DrawGetTextSize(txt)
            gauges.drawtext(self, txt, lx - tw / 2, ly - th / 2)

            if i < major and minor > 0 then
                for j = 1, minor - 1 do
                    local subang = ang + (span_deg / major) * (j / minor)
                    tick_at_angle(subang, radius, radius - minor_len, math.max(1, math.floor(width * 0.6)))
                end
            end
        end
    end

    if not mask.noneedle then
        local needle_ang = start_deg + span_deg * ratio
        local needle_r   = radius - major_len - 6
        gauges.drawline(self, cx, cy, cx + needle_r * math.cos(math.rad(needle_ang)),
            cy + needle_r * math.sin(math.rad(needle_ang)))
        gauges.drawarc(self, cx - width, cy - width, cx + width, cy + width)
    end

    if not mask.nodigital then
        local digy  = cy + label_r * math.sin(math.rad(start_deg))
        local digw  = math.abs(label_r * math.cos(math.rad(start_deg))) * 2
        local txt   = string.format(format .. "%s", value, postfix and (" " .. postfix) or "")
        local _, th = self:DrawGetTextSize(txt)
        gauges.textstyle(self, { alignment = "ACENTER", wrap = "NO", ellipsis = "YES" }, function()
            gauges.drawtext(self, txt, cx - digw / 2, digy - th / 2, digw, th)
        end)
    end

    if not mask.noframe then
        gauges.style(self, color, width * 2, style)
        gauges.drawarc(self, cx - frame_r, cy - frame_r, cx + frame_r, cy + frame_r)
    end
end

return gauges
