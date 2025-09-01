---@meta
---@version >5.1
---@diagnostic disable: lowercase-global

local iup = { canvas = {} }

---@alias canvas.style         "FILL"|"STROKE"|"STROKE_DASH"|"STROKE_DOT"|"STROKE_DASH_DOT"|"STROKE_DASH_DOT_DOT"
---@alias canvas.textalignment "ALEFT"|"ARIGHT"|"ACENTER"
---@alias canvas.boolean       "YES"|"NO"

---All functions below can be used only in IupCanvas or IupBackgroundBox
---and inside the ACTION callback. To force a redraw anytime use
---the functions IupUpdate or IupRedraw.
---@class canvas
---@field drawcolor            string|"0 0 0"
---@field drawstyle            canvas.style
---@field drawlinewidth        integer
---@field drawfont             string|"Helvetica, Bold 10"
---@field drawtextalignment    canvas.textalignment
---@field drawtextwrap         canvas.boolean
---@field drawtextellipsis     canvas.boolean
---@field drawtextclip         canvas.boolean
---@field drawtextorientation  integer
---@field drawtextlayoutcenter canvas.boolean
---@field drawmakeinactive     canvas.boolean
---@field drawbgcolor          string|"0 0 0"
local canvas = iup.canvas {}

---Initialize the drawing process.
function canvas:DrawBegin() end

---Terminates the drawing process and actually draw on screen.
function canvas:DrawEnd() end

---Defines a rectangular clipping region.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function canvas:DrawSetClipRect(x1, y1, x2, y2) end

---Reset the clipping area to none.
function canvas:DrawResetClip() end

---Returns the previous rectangular clipping region set by IupDrawSetClipRect,
---if clipping was reset returns 0 in all values. (since 3.25)
---@return number x1
---@return number y1
---@return number x2
---@return number y2
---@nodiscard
function canvas:DrawGetClipRect() end

---Fills the canvas with the native parent background color.
function canvas:DrawParentBackground() end

---Draws a line including start and end points.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function canvas:DrawLine(x1, y1, x2, y2) end

---Draws a rectangle including start and end points.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function canvas:DrawRectangle(x1, y1, x2, y2) end

---Draws an arc inside a rectangle between the two angles in degrees.
---When filled will draw a pie shape with the vertex at the center of the rectangle.
---Angles are counter-clock wise relative to the 3 o'clock position.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param a1 number
---@param a2 number
function canvas:DrawArc(x1, y1, x2, y2, a1, a2) end

---Draws a polygon. Coordinates are stored in the array in the sequence: `x1, y1, x2, y2, ...`
---@param points number[]
function canvas:DrawPolygon(points) end

---Draws a text in the given position using the font defined by DRAWFONT (since 3.22).
---@param str string
---@param x number
---@param y number
---@param w? number
---@param h? number
function canvas:DrawText(str, x, y, w, h) end

---Draws an image given its name.
---The coordinates are relative the top-left corner of the image.
---@param image string|table
---@param x number
---@param y number
---@param w? number
---@param h? number
function canvas:DrawImage(image, x, y, w, h) end

---Draws a selection rectangle.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function canvas:DrawSelectRect(x1, y1, x2, y2) end

---Draws a focus rectangle.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function canvas:DrawFocusRect(x1, y1, x2, y2) end

---Returns the drawing area size.
---@return number w
---@return number h
---@nodiscard
function canvas:DrawGetSize() end

---Returns the given text size using the font defined by DRAWFONT.
---@param str string
---@return number w
---@return number h
---@nodiscard
function canvas:DrawGetTextSize(str) end

---Returns the given image size and bits per pixel.
---@param name string
---@return number w
---@return number h
---@return 8|24|32 bpp
---@nodiscard
function canvas:DrawGetImageInfo(name) end
