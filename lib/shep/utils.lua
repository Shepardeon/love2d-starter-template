local utils = {}

local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

--- Calculates the distance between two points.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function utils.distance(x1, y1, x2, y2)
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

--- Calculates the squared distance between two points.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function utils.distance2(x1, y1, x2, y2)
    return (x2 - x1)^2 + (y2 - y1)^2
end

--- Calculates the length of a vector.
---@param x number
---@param y number
---@return number
function utils.length(x, y)
    return sqrt(x^2 + y^2)
end

--- Calculates the squared length of a vector.
---@param x number
---@param y number
---@return number
function utils.length2(x, y)
    return x^2 + y^2
end

--- Normalizes a vector.
---@param x number
---@param y number
---@return number, number
function utils.normalize(x, y)
    local len = utils.length(x, y)
    return x / len, y / len
end

--- Rotates a point about another point by a given angle.
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

--- Repeats a value n times in a table.
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

--- Removes and returns the first element of a table.
---@param tbl table
function utils.shiftTable(tbl)
    return table.remove(tbl, 1)
end

--- Removes and returns the last element of a table.
---@param tbl table
function utils.popTable(tbl)
    return table.remove(tbl)
end

--- Calculates the average of the values in a table.
---@param tbl table
function utils.avgTable(tbl)
    local sum = 0
    for _, v in ipairs(tbl) do
        sum = sum + v
    end
    return sum / #tbl
end

--- Prints all arguments.
function utils.printAll(...)
    local args = {...}
    for _, v in ipairs(args) do
        print(v)
    end
end

--- Prints all arguments as a single concatenated string.
function utils.printText(...)
    local args = {...}
    print(table.concat(args, " "))
end

--- Prints the contents of a table.
---@param t table
function utils.printTable(t)
    for k, v in pairs(t) do
        print(k, '=>', v)
    end
end

return utils