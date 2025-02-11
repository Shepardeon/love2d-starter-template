local lume = require('lib.lume')

---@class shep.Entity: Object
---@field uuid string
---@field protected alive boolean
---@field protected scene shep.Scene
local Entity = Object:extend()

--- Creates a new Entity instance.
---@param scene shep.Scene
function Entity:new(scene)
    self.uuid = lume.uuid()
    self.alive = true
    self.scene = scene

    scene:addEntity(self)
end

--- Checks if the entity is alive.
---@return boolean
function Entity:isAlive()
    return self.alive
end

--- Updates the entity.
---@param dt number
function Entity:update(dt)
    -- do nothing
end

--- Draws the entity.
function Entity:draw()
    -- do nothing
end

return Entity