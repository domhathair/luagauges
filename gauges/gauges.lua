---gauges.lua

local iup = require("iuplua")
local gauges = {}

-- Math helpers

---Clamp value to [min, max] and normalize to 0..1
---@param min number
---@param max number
---@param value number
---@return number ratio -- value mapped to 0..1 inside the range
function gauges.norm(min, max, value)
    if value < min then value = min end
    if value > max then value = max end
    return (value - min) / (max - min)
end

---Lua 5.1/>5.1 compatibility for table.unpack
---@param ... any
function gauges.unpack(...)
    local fn = _G.table and table.unpack or unpack
    return fn(...)
end

-- Canvas helpers (typed wrappers around IUP Draw* API)

---Set draw color/width/style on canvas.
---@param self canvas
---@param color? string|"0 0 0"
---@param width? integer
---@param style? canvas.style
function gauges.style(self, color, width, style)
    self.drawcolor = color or "0 0 0"
    if width then self.drawlinewidth = width end
    if style then self.drawstyle = style end
end

---Temporarily override text style while running a function.
---@param self canvas
---@param opts {alignment?:string, wrap?:string, ellipsis?:string}
---@param fn fun()
function gauges.textstyle(self, opts, fn)
    local old              = {
        alignment = self.drawtextalignment,
        wrap      = self.drawtextwrap,
        ellipsis  = self.drawtextellipsis,
    }
    self.drawtextalignment = opts.alignment or old.alignment
    self.drawtextwrap      = opts.wrap or old.wrap
    self.drawtextellipsis  = opts.ellipsis or old.ellipsis

    fn()

    self.drawtextalignment = old.alignment
    self.drawtextwrap      = old.wrap
    self.drawtextellipsis  = old.ellipsis
end

---Draw a line (coords are floored for crisp pixels).
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

---Draw a rectangle (inclusive corners).
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

---Draw an arc inside given box; angles are optional.
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
        a1 or 0,
        a2 or 360
    )
end

---Draw a polygon from a numeric array.
---@param self canvas
---@param points number[]
function gauges.drawpolygon(self, points)
    local floor = {}
    for _, p in ipairs(points) do table.insert(floor, math.floor(p)) end
    self:DrawPolygon(floor)
end

---Draw text with optional bounding box.
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

-- Convenience: build a canvas that auto-calls a given gauges.* function

---Create an IUP canvas that draws a specific gauges.* widget each frame.
---@param t? table            -- canvas creation table
---@param name string         -- function name inside `gauges` (e.g. "analogcircular")
---@param ... any             -- parameters passed to that function
---@return canvas
function gauges.canvas(t, name, ...)
    local cv = iup.canvas(t or {})
    local params = { ... }

    function cv:action()
        iup.DrawBegin(self)
        iup.DrawParentBackground(self)

        local fn = gauges[name]
        if type(fn) == "function" then
            fn(self, gauges.unpack(params))
        end

        iup.DrawEnd(self)
    end

    return cv
end

return gauges
