local lume = require('lib.lume')
local bump = require('lib.bump')

--- @class shep.Scene: Object
--- @field private entities shep.Entity[]
--- @field world bump.World
--- @field sceneIndex number
--- @field game shep.Game
local Scene = Object:extend()

--- Initializes a new Scene.
---@param game shep.Game
function Scene:new(game)
    self.entities = {}
    self.world = bump.newWorld()
    self.sceneIndex = game:addScene(self)
    self.game = game
end

--- Enables the scene.
function Scene:enable()
    -- do nothing
end

--- Disables the scene.
function Scene:disable()
    -- do nothing
end

--- Updates all entities in the scene.
---@param dt number
function Scene:update(dt)
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        entity:update(dt)
    end
end

--- Draws all entities in the scene.
function Scene:draw()
    for i = 1, #self.entities do
        local entity = self.entities[i]
        entity:draw()
    end
end

--- Adds an entity to the scene.
---@param entity shep.Entity
function Scene:addEntity(entity)
    table.insert(self.entities, entity)
end

--- Removes an entity from the scene.
---@param entity shep.Entity
function Scene:removeEntity(entity)
    lume.remove(self.entities, entity)
end

--- Finds an entity in the scene by UUID.
---@param uuid string
---@return shep.Entity|nil
function Scene:findEntity(uuid)
    return lume.match(self.entities, function(e)
        return e.uuid == uuid
    end)
end

return Scene