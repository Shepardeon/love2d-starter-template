local utils = {}

local sqrt = math.sqrt

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