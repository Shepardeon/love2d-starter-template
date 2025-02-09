local lume = require('lib.lume')

---@class shep.Entity: Object
---@field uuid string
---@field protected alive boolean
local Entity = Object:extend()

---@param scene shep.Scene
function Entity:new(scene)
    self.uuid = lume.uuid()
    self.alive = true

    scene:addEntity(self)
end

function Entity:isAlive()
    return self.alive
end

---@param dt number
function Entity:update(dt)
    -- do nothing
end

function Entity:draw()
    -- do nothing
end

return Entity