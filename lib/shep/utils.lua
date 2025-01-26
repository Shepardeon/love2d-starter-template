local utils = {}

local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function utils.distance(x1, y1, x2, y2)
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function utils.distance2(x1, y1, x2, y2)
    return (x2 - x1)^2 + (y2 - y1)^2
end

---@param x number
---@param y number
---@return number
function utils.length(x, y)
    return sqrt(x^2 + y^2)
end

---@param x number
---@param y number
---@return number
function utils.length2(x, y)
    return x^2 + y^2
end

---@param x number
---@param y number
---@return number, number
function utils.normalize(x, y)
    local len = utils.length(x, y)
    return x / len, y / len
end

--- Rotate a point about another point by a given angle
---@param px number
---@param py number
---@param ox number
---@param oy number
---@param angle number
function utils.rotateAboutPoint(px, py, ox, oy, angle)
    px, py = px - ox, py - oy
    local c, s = cos(angle), sin(angle)
    return px * c - py * s + ox, px * s + py * c + oy
end

--- Repeats a value n times in a table
---@param val any
---@param n number
---@return table
function utils.repeatTable(val, n)
    local t = {}
    for i = 1, n do
        t[i] = val
    end
    return t
end

-- function utils.repeat(val, n)
--     local t = {}
--     for i = 1, n do
--         t[i] = val
--     end
--     return t
-- end

function utils.printAll(...)
    local args = {...}
    for _, v in ipairs(args) do
        print(v)
    end
end

function utils.printText(...)
    local args = {...}
    print(table.concat(args, " "))
end

return utils