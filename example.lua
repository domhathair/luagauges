package.path = package.path .. ";gauges/?.lua"

local iup = require("iuplua")

local function prequire(...)
    local status, lib = pcall(require, ...)
    if status then
        return lib
    end
    return nil
end

local NDEBUG = false
if not NDEBUG then
    local debug = prequire("lldebugger")
    if debug then
        debug.start()
    end
end

local min, max, cur, t = -1.1, 1.1, 0, 0
local color = ""

local file = ""
local gauges = {}

--------------------------------------------------------------

file = "gauges/digitmeter.lua"
gauges = dofile(file)

local cv1 = iup.canvas { expand = "YES", border = "YES", label = file }
function cv1:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.digitmeter(self, cur, { format = "%04.1f", color = color })

    iup.DrawEnd(self)
end

--------------------------------------------------------------

file = "gauges/analogcircular.lua"
gauges = dofile(file)

local cv2 = iup.canvas { expand = "YES", border = "YES", label = file }
function cv2:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.analogcircular(self, min * 10, max * 10, math.ceil(cur * 10), { format = "%d", postfix = "×10⁻¹" })

    iup.DrawEnd(self)
end

--------------------------------------------------------------

file = "gauges/thermometer.lua"
gauges = dofile(file)

local cv3 = iup.canvas { expand = "YES", border = "YES", label = file }
function cv3:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.thermometer(self, min * 20, max * 20, cur * 20, { format = "%.1f", postfix = "°C" })

    iup.DrawEnd(self)
end

--------------------------------------------------------------

file = "gauges/plot.lua"
gauges = dofile(file)

local cv4 = iup.canvas { expand = "YES", border = "YES", label = file }
function cv4:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.plot(self, "A",
        { xmax = 1000, color = "255 0 0", ymin = min, ymax = max, nostretch = true, label = "sin(t)|cos(t)" })
    gauges.plot(self, "B",
        { xmax = 1000, color = "0 0 255", ymin = min, ymax = max, nostretch = true },
        { nobackground = true, noframe = true, nosteps = true })

    iup.DrawEnd(self)
end

--------------------------------------------------------------

local w, h = 520, 520
local dlg = iup.dialog {
    iup.hbox {
        iup.vbox {
            cv1,
            cv2,
        },
        iup.vbox {
            cv3,
            cv4
        }
    },
    title = arg[0], minsize = w .. "x" .. h }

local coro = coroutine.create(function()
    local maxrgb = 255
    local function set_color(r, g, b) color = r .. " " .. g .. " " .. b end

    while true do
        for i = 0, maxrgb - 1 do
            set_color(i, maxrgb - i, 0);
            coroutine.yield()
        end
        for i = 0, maxrgb - 1 do
            set_color(maxrgb - i, 0, i);
            coroutine.yield()
        end
        for i = 0, maxrgb - 1 do
            set_color(0, i, maxrgb - i);
            coroutine.yield()
        end
    end
end)

local frame = 60
local frame_timer = iup.timer {
    time = 1000 / frame,
    action_cb = function()
        if coroutine.status(coro) ~= "running" then
            coroutine.resume(coro)
        end
        iup.Update(dlg, 1)
    end
}

local sys_tick = 4
local sys_tick_timer = iup.timer {
    time = sys_tick,
    action_cb = function()
        t = t + sys_tick

        local sin = math.sin(math.rad(t))
        local cos = math.cos(math.rad(t))

        gauges.append("A", t, sin)
        gauges.append("B", t, cos)

        cur = sin * cos
    end
}

dlg:showxy(iup.CENTER, iup.CENTER)

frame_timer.run, sys_tick_timer.run = "YES", "YES"

iup.MainLoop()
