-- plot.lua

local iup = require("iuplua")
local gauges = require("gauges")

local plots = {}  -- id -> {data={}, xmin, xmax, ymin, ymax}
local params = {} -- id -> flags (color, etc.)

local borderw, borderh = 40, 30

---Choose a "nice" step given a range and desired tick count.
---@param range number
---@param target number
local function step(range, target)
    local z = range / math.max(1, target)
    local mag = 10 ^ math.floor(math.log10(z))
    local n = z / mag
    local nice = (n < 1.5) and 1 or (n < 3 and 2 or (n < 7 and 5 or 10))
    return nice * mag
end

---Interpolate a point on the segment (x1,y1)-(x2,y2) by forced X.
local function pointonxline(x1, y1, x2, y2, newx)
    if x2 == x1 then return x1, y1 end
    local t = (newx - x1) / (x2 - x1)
    return newx, y1 + (y2 - y1) * t
end

---Interpolate a point on the segment by forced Y.
local function pointonyline(x1, y1, x2, y2, newy)
    if y2 == y1 then return x1, y1 end
    local t = (newy - y1) / (y2 - y1)
    return x1 + (x2 - x1) * t, newy
end

---Append a data point to a plot id (keeps data up to xmax)
---@param id any
---@param x number
---@param y number
function gauges.append(id, x, y)
    local p = params[id]
    local d = plots[id]
    if not p or not d then return end
    table.insert(d, { x, y })

    if x > p.xmax then
        p.xmax = x
        p.xmin = x - p.win
    end

    local cutoff = p.xmin - p.win * 0.05
    while #d > 2 and d[2][1] < cutoff do table.remove(d, 1) end

    if not p.nostretch then
        local ymin, ymax = y, y
        for _, pt in ipairs(d) do
            if pt[2] < ymin then ymin = pt[2] end
            if pt[2] > ymax then ymax = pt[2] end
        end
        if ymin == ymax then
            ymin = ymin - 1; ymax = ymax + 1
        end
        local pad = 0.1 * (ymax - ymin)
        p.ymin, p.ymax = ymin - pad, ymax + pad
    end
end

local function mapx(p, w, x) return borderw + (x - p.xmin) / (p.xmax - p.xmin) * (w - (borderh * 2)) end
local function mapy(p, h, y) return borderh + (p.ymax - y) / (p.ymax - p.ymin) * (h - (borderh * 2)) end

---@class plot_mask
---@field nobackground boolean
---@field noframe boolean
---@field nosteps boolean
---@field nograph boolean

---@class plot_flags
---@field size table
---@field xmax number
---@field ymin number
---@field ymax number
---@field label string
---@field color string
---@field width integer
---@field nostretch boolean
---@field style canvas.style
---@field format string
---@field mask plot_mask

---Draw or update a plot area identified by `id`.
---![](../images/plot.png)
---@param self canvas
---@param id any
---@param flags? plot_flags
---@param mask? plot_mask
function gauges.plot(self, id, flags, mask)
    flags = flags or {}
    mask = mask or {}

    if mask.nobackground and mask.noframe and mask.nosteps and mask.nograph then return end

    local size = flags.size or { self:DrawGetSize() }
    local format = flags.format or "%.1f"

    local p = params[id] or (function()
        params[id] = {
            win = flags.xmax or 10,
            xmin = 0,
            xmax = flags.xmax or 10,
            ymin = flags.ymin or -1,
            ymax = flags.ymax or 1,
            label = flags.label or "",
            color = flags.color or "0 0 0",
            width = flags.width or 2,
            style = flags.style or "STROKE",
            nostretch = flags.nostretch or false
        }
        plots[id] = {}
        return params[id]
    end)()
    local d = plots[id]
    local w, h = gauges.unpack(size)

    if not mask.nobackground then
        gauges.style(self, "255 255 255", nil, "FILL")
        gauges.drawrectangle(self, 0, 0, w, h)
    end

    if not mask.noframe then
        gauges.style(self, "0 0 0", 1, "STROKE")
        gauges.drawrectangle(self, borderw, borderh, w - (borderw / 2), h - borderh)
    end

    if not mask.nosteps then
        gauges.style(self, "180 180 180", 1, "STROKE_DOT")

        gauges.textstyle(self, { alignment = "ACENTER", wrap = "NO", ellipsis = "YES" }, function()
            local xstep = step(p.xmax - p.xmin, 10)
            local xprev, xend = nil, nil
            for gx = math.ceil(p.xmin / xstep) * xstep, p.xmax, xstep do
                local sx = mapx(p, w, gx)
                gauges.drawline(self, sx, borderh, sx, h - borderh)
                local txt = string.format(format, gx)
                local tw, _ = self:DrawGetTextSize(txt)
                local psx, psy, psw = sx - tw / 2, h - borderh + 5, tw
                if xprev then
                    local xstepw = sx - xprev
                    psx, psw = sx - xstepw / 2, xstepw
                end
                if not xend or psx >= xend - 1 then
                    gauges.drawtext(self, txt, psx, psy, psw)
                end
                xprev, xend = sx, psx + psw
            end

            local ystep = step(p.ymax - p.ymin, 10)
            for gy = math.ceil(p.ymin / ystep) * ystep, p.ymax, ystep do
                local sy = mapy(p, h, gy)
                gauges.drawline(self, borderw, sy, w - (borderw / 2), sy)
                local txt = string.format(format, gy)
                local tw, th = self:DrawGetTextSize(txt)
                gauges.drawtext(self, txt, borderw - tw - 5, sy - th / 2)
            end
        end)
    end

    if p.label ~= "" then
        local tw, _ = self:DrawGetTextSize(p.label)
        gauges.drawtext(self, p.label, (w - tw) / 2, 10)
    end

    if flags.mask and flags.mask.nograph then else
        gauges.style(self, p.color, p.width, p.style)

        if not d or #d < 2 then return end
        local px, py = mapx(p, w, d[1][1]), mapy(p, h, d[1][2])
        for i = 2, #d do
            local sx, sy = mapx(p, w, d[i][1]), mapy(p, h, d[i][2])
            if sx < borderw then else
                local dpx, dpy, dsx, dsy = px, py, sx, sy
                if (dpy < borderh and dsy < borderh) or (dpy > (h - borderh) and dsy > (h - borderh)) then else
                    if dpx < borderw then dpx, dpy = pointonxline(dpx, dpy, dsx, dsy, borderw) end
                    if dpy < borderh then dpx, dpy = pointonyline(dpx, dpy, dsx, dsy, borderh) end
                    if dsy < borderh then dsx, dsy = pointonyline(dpx, dpy, dsx, dsy, borderh) end
                    if dpy > (h - borderh) then dpx, dpy = pointonyline(dpx, dpy, dsx, dsy, h - borderh) end
                    if dsy > (h - borderh) then dsx, dsy = pointonyline(dpx, dpy, dsx, dsy, h - borderh) end
                    gauges.drawline(self, dpx, dpy, dsx, dsy)
                end
            end
            px, py = sx, sy
        end
    end
end

return gauges
