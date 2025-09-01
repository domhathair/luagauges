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

local min, max, cur, t = -1, 1, 0, 0

local file = ""
local gauges = {}

file = "gauges/digitmeter.lua"
gauges = dofile(file)

local cv1 = iup.canvas { expand = "YES" }
function cv1:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.digitmeter(self, cur, { format = "%05.1f" })

    iup.DrawEnd(self)
end

file = "gauges/analogcircular.lua"
gauges = dofile(file)

local cv2 = iup.canvas { expand = "YES" }
function cv2:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.analogcircular(self, min, max, cur, { format = "%.1f" })

    iup.DrawEnd(self)
end

file = "gauges/thermometer.lua"
gauges = dofile(file)

local cv3 = iup.canvas { expand = "YES" }
function cv3:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.thermometer(self, min, max, cur, { format = "%.1f" })

    iup.DrawEnd(self)
end

file = "gauges/plot.lua"
gauges = dofile(file)

local cv4 = iup.canvas { expand = "YES" }
function cv4:action()
    iup.DrawBegin(self)
    iup.DrawParentBackground(self)

    gauges.plot(self, "A",
        { xmax = 1000, color = "255 0 0", ymin = min, ymax = max, nostretch = true })
    gauges.plot(self, "B",
        { xmax = 1000, color = "0 0 255", ymin = min, ymax = max, nostretch = true, mask = { nobackground = true, noframe = true, nosteps = true } })

    iup.DrawEnd(self)
end

local w, h = 640, 480
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
    title = file, minsize = w .. "x" .. h }

local fps = 60
iup.timer {
    time = 1000 / fps,
    run = "YES",
    action_cb = function()
        iup.Update(dlg, 1)
    end
}

local time = 4
iup.timer {
    time = 10,
    run = "YES",
    action_cb = function()
        t = t + time

        local sin = math.sin(math.rad(t))
        local cos = math.cos(math.rad(t))

        gauges.append("A", t, sin)
        gauges.append("B", t, cos)

        cur = sin - cos
    end
}

dlg:popup(iup.CENTER, iup.CENTER)
