-- plot.lua

local iup = require("iuplua")
local gauges = require("gauges")

local plots = {}
local params = {}

local borderw, borderh = 40, 30

local function step(range, target)
    local zstep = range / target
    local mag = 10 ^ math.floor(math.log10(zstep))
    local norm = zstep / mag
    local nice
    if norm < 1.5 then
        nice = 1
    elseif norm < 3 then
        nice = 2
    elseif norm < 7 then
        nice = 5
    else
        nice = 10
    end
    return nice * mag
end

local function pointonxline(x1, y1, x2, y2, newx)
    if x2 == x1 then
        return x1, y1
    end
    local slope = (y2 - y1) / (x2 - x1)
    local newy = y1 + slope * (newx - x1)
    return newx, newy
end

local function pointonyline(x1, y1, x2, y2, newy)
    if y2 == y1 then
        return x1, y1
    end
    local slope = (x2 - x1) / (y2 - y1)
    local newx = x1 + slope * (newy - y1)
    return newx, newy
end


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
    for i = 1, #d do
        if d[i] and d[i][1] < cutoff then
            table.remove(d, i)
        else
            break
        end
    end

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
---@field title string
---@field color string
---@field width integer
---@field nostretch boolean
---@field style canvas.style
---@field format string
---@field mask plot_mask

---![](../images/plot.png)
---@param self canvas
---@param id any
---@param flags? plot_flags
function gauges.plot(self, id, flags)
    flags = flags or {}

    if flags.mask
        and flags.mask.nobackground
        and flags.mask.noframe
        and flags.mask.nosteps
        and flags.mask.nograph then
        ---There is nothing to do
        return
    end

    local size = flags.size or { self:DrawGetSize() }
    local format = flags.format or "%.1f"

    local p = params[id] or (function()
        local xmax = flags.xmax or 10
        local ymin = flags.ymin or -1
        local ymax = flags.ymax or 1
        local title = flags.title or ""
        local color = flags.color or "0 0 0"
        local width = flags.width or 2
        local style = flags.style or "STROKE"
        local nostretch = flags.nostretch or false
        params[id] = {
            win = xmax,
            xmin = 0,
            xmax = xmax,
            ymin = ymin,
            ymax = ymax,
            title = title,
            color = color,
            width = width,
            style = style,
            nostretch = nostretch
        }
        plots[id] = {}
        return params[id]
    end)()
    local d = plots[id]
    local w, h = gauges.unpack(size)

    if flags.mask and flags.mask.nobackground then else
        gauges.style(self, "255 255 255", nil, "FILL")
        gauges.drawrectangle(self, 0, 0, w, h)
    end

    if flags.mask and flags.mask.noframe then else
        gauges.style(self, "0 0 0", 1, "STROKE")
        gauges.drawrectangle(self, borderw, borderh, w - (borderw / 2), h - borderh)
    end

    if flags.mask and flags.mask.nosteps then else
        gauges.style(self, "180 180 180", 1, "STROKE_DOT")

        gauges.textstyle(self, { alignment = "ACENTER", wrap = "NO", ellipsis = "YES" }, function()
            local xstep = step(p.xmax - p.xmin, 10)
            local xprev = nil
            for gx = math.ceil(p.xmin / xstep) * xstep, p.xmax, xstep do
                local sx = mapx(p, w, gx)
                gauges.drawline(self, sx, borderh, sx, h - borderh)
                local txt = string.format(format, gx)
                local txtw, _ = self:DrawGetTextSize(txt)
                local psx, psy, psw = sx - txtw / 2, h - borderh + 5, nil
                if xprev then
                    local xstepw = sx - xprev
                    psx, psw = sx - xstepw / 2, xstepw
                end
                gauges.drawtext(self, txt, psx, psy, psw)
                xprev = sx
            end

            local ystep = step(p.ymax - p.ymin, 10)
            for gy = math.ceil(p.ymin / ystep) * ystep, p.ymax, ystep do
                local sy = mapy(p, h, gy)
                gauges.drawline(self, borderw, sy, w - (borderw / 2), sy)
                local txt = string.format(format, gy)
                local txtw, txth = self:DrawGetTextSize(txt)
                gauges.drawtext(self, txt, borderw - txtw - 5, sy - txth / 2)
            end
        end)
    end

    if p.title ~= "" then
        local tw, th = self:DrawGetTextSize(p.title)
        gauges.drawtext(self, p.title, (w - tw) / 2, 10)
    end

    if flags.mask and flags.mask.nograph then else
        gauges.style(self, p.color, p.width, p.style)

        if not d or #d < 2 then return end
        local px, py = mapx(p, w, d[1][1]), mapy(p, h, d[1][2])
        for i = 2, #d do
            local sx, sy = mapx(p, w, d[i][1]), mapy(p, h, d[i][2])
            if sx < borderw then else
                local dpx, dpy, dsx, dsy = px, py, sx, sy
                if dpx < borderw then dpx, dpy = pointonxline(dpx, dpy, dsx, dsy, borderw) end
                if (dpy < borderh and dsy < borderh) or (dpy > (h - borderh) and dsy > (h - borderh)) then else
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
