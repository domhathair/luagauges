---analogcircular.lua

local iup = require("iuplua")
local gauges = require("gauges")

---@class analogcircular_mask
---@field noarc boolean
---@field nocount boolean
---@field noneedle boolean
---@field nodigital boolean

---@class analogcircular_flags
---@field size table
---@field color string
---@field width integer
---@field style canvas.style
---@field postfix string
---@field format string
---@field cmajor integer
---@field cminor integer
---@field mask analogcircular_mask

---![](../images/analogcircular.png)
---@param self canvas
---@param min integer
---@param max integer
---@param current integer
---@param flags? analogcircular_flags
function gauges.analogcircular(self, min, max, current, flags)
    flags = flags or {}

    if flags.mask
        and flags.mask.noarc
        and flags.mask.nocount
        and flags.mask.noneedle
        and flags.mask.nodigital then
        ---There is nothing to do
        return
    end

    local size = flags.size or { self:DrawGetSize() }
    local color = flags.color or iup.GetGlobal("TXTFGCOLOR")
    local width = flags.width or 2
    local style = flags.style or "STROKE"
    local postfix = flags.postfix or nil
    local format = flags.format or "%d"
    local cmajor = flags.cmajor or 10
    local cminor = flags.cminor or 5

    local w, h = gauges.unpack(size)
    if cmajor < 1 then cmajor = 1 end

    local function drawtickatangle(cx, cy, angle_deg, outerr, innerr, tth)
        local rad = math.rad(angle_deg)
        local x1 = cx + outerr * math.cos(rad)
        local y1 = cy + outerr * math.sin(rad)
        local x2 = cx + innerr * math.cos(rad)
        local y2 = cy + innerr * math.sin(rad)
        gauges.style(self, color, tth or width, style)
        gauges.drawline(self, x1, y1, x2, y2)
        gauges.style(self, color, width, style)
    end

    gauges.style(self, color, width, style)

    local ratio     = gauges.norm(min, max, current)
    local cx        = w * 0.5
    local cy        = h * 0.5
    local radius    = math.min(w, h) * 0.40
    local labr      = radius + math.max(10, math.floor(radius * 0.1)) + 5

    local starthour = 8
    local endhour   = 4
    local function hourtodeg(hh) return (hh - 3) * 30 end
    local startdeg = hourtodeg(starthour)
    local enddeg   = hourtodeg(endhour)

    local span_deg = enddeg - startdeg
    if span_deg <= 0 then span_deg = span_deg + 360 end

    if flags.mask and flags.mask.noarc then else
        ---Angles are counter-clock wise relative to the 3 o'clock position
        local a1, a2 = 360 - enddeg, 360 - startdeg
        gauges.drawarc(self, cx - radius, cy - radius, cx + radius, cy + radius, a1, a2)
    end

    local majorlen = math.max(8, math.floor(radius * 0.12))
    local minorlen = math.max(4, math.floor(radius * 0.06))

    if flags.mask and flags.mask.nocount then else
        for i = 0, cmajor do
            local ang = startdeg + (span_deg / cmajor) * i

            drawtickatangle(cx, cy, ang, radius, radius - majorlen, width)

            local lx = cx + labr * math.cos(math.rad(ang))
            local ly = cy + labr * math.sin(math.rad(ang))

            local val = min + (max - min) * (i / cmajor)

            local txt = string.format(format, format == "%d" and math.floor(val + 0.5) or val)
            local txtw, txth = self:DrawGetTextSize(txt)
            gauges.drawtext(self, txt, lx - txtw / 2, ly - txth / 2)

            if i < cmajor then
                if cminor > 1 then
                    for j = 1, cminor - 1 do
                        local subang = ang + (span_deg / cmajor) * (j / cminor)
                        drawtickatangle(cx, cy, subang, radius, radius - minorlen,
                            math.max(1, math.floor(width * 0.6)))
                    end
                end
            end
        end
    end

    if flags.mask and flags.mask.noneedle then else
        local needleang = startdeg + span_deg * ratio
        local needleout = radius - majorlen - 6
        gauges.drawline(self, cx, cy, cx + needleout * math.cos(math.rad(needleang)),
            cy + needleout * math.sin(math.rad(needleang)))
        gauges.drawarc(self, cx - width, cy - width, cx + width, cy + width)
    end

    if flags.mask and flags.mask.nodigital then else
        local digy = cy + labr * math.sin(math.rad(startdeg))
        local digw = math.abs(labr * math.cos(math.rad(startdeg))) * 2

        local txt = string.format(format .. "%s", current, postfix and (" " .. postfix) or "")
        local _, txth = self:DrawGetTextSize(txt)

        gauges.textstyle(self, { alignment = "ACENTER", wrap = "NO", ellipsis = "YES" }, function()
            gauges.drawtext(self, txt, cx - digw / 2, digy - txth / 2, digw, txth)
        end)
    end
end

return gauges
