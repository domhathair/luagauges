---gauges.lua

local iup = require("iuplua")
local gauges = {}

---@param min number
---@param max number
---@param cur number
---@return number
function gauges.norm(min, max, cur)
    if cur < min then cur = min end
    if cur > max then cur = max end
    return (cur - min) / (max - min)
end

---@param self canvas
---@param color? string|"0 0 0"
---@param width? integer
---@param style? canvas.style
function gauges.style(self, color, width, style)
    self.drawcolor = color or "0 0 0"
    if width then self.drawlinewidth = width end
    if style then self.drawstyle = style end
end

---@param self canvas
---@param opts table
---@param fn function
function gauges.textstyle(self, opts, fn)
    local old              = {
        alignment = self.drawtextalignment,
        wrap = self.drawtextwrap,
        ellipsis = self.drawtextellipsis,
    }
    self.drawtextalignment = opts.alignment or old.alignment
    self.drawtextwrap      = opts.wrap or old.wrap
    self.drawtextellipsis  = opts.ellipsis or old.ellipsis

    fn()

    self.drawtextalignment = old.alignment
    self.drawtextwrap      = old.wrap
    self.drawtextellipsis  = old.ellipsis
end

---@param ... any
function gauges.unpack(...)
    local fn = _G.table and table.unpack or unpack
    return fn(...)
end

---@param t? table #Table to `iup.canvas`
---@param n string #Name of function to be called
---@param ... any  #Arguments to `gauges.call(...)`
---@return canvas
function gauges.canvas(t, n, ...)
    local cv = iup.canvas(t and t or {})
    local params = { ... }

    function cv:action()
        iup.DrawBegin(self)
        iup.DrawParentBackground(self)

        local fn = gauges[n]
        if type(fn) == "function" then
            fn(self, unpack(params))
        end

        iup.DrawEnd(self)
    end

    return cv;
end

---@param self canvas
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function gauges.drawline(self, x1, y1, x2, y2)
    self:DrawLine(
        math.floor(x1),
        math.floor(y1),
        math.floor(x2),
        math.floor(y2)
    )
end

---@param self canvas
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function gauges.drawrectangle(self, x1, y1, x2, y2)
    self:DrawRectangle(
        math.floor(x1),
        math.floor(y1),
        math.floor(x2),
        math.floor(y2)
    )
end

---@param self canvas
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param a1? number
---@param a2? number
function gauges.drawarc(self, x1, y1, x2, y2, a1, a2)
    self:DrawArc(
        math.floor(x1),
        math.floor(y1),
        math.floor(x2),
        math.floor(y2),
        a1 and math.floor(a1) or 0,
        a2 and math.floor(a2) or 360
    )
end

---@param self canvas
---@param points number[]
function gauges.drawpolygon(self, points)
    local floor = {}
    for _, p in ipairs(points) do
        table.insert(floor, math.floor(p))
    end
    self:DrawPolygon(floor)
end

---@param self canvas
---@param str string
---@param x number
---@param y number
---@param w? number
---@param h? number
function gauges.drawtext(self, str, x, y, w, h)
    self:DrawText(str,
        math.floor(x),
        math.floor(y),
        w and math.floor(w),
        h and math.floor(h)
    )
end

return gauges
