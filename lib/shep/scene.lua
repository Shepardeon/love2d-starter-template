local scene = {}
local lume = require('lib.lume')

---@param updateFn fun(self: Scene, dt: number)|nil
---@param drawFn fun(self: Scene)|nil
---@param enableFn fun(self: Scene)|nil
---@param disableFn fun(self: Scene)|nil
---@return Scene
function scene.new(updateFn, drawFn, enableFn, disableFn)
    --- @class Scene
    local self = {}
    self.entities = {}

    self.enable = enableFn or function()
        -- do nothing
    end

    self.disable = disableFn or function()
        -- do nothing
    end

    --- @param dt number
    self.update = updateFn or function(dt)
        for i = #self.entities, 1, -1 do
            local entity = self.entities[i]
            entity:update(dt)
        end
    end

    self.draw = drawFn or function()
        for i = 1, #self.entities do
            local entity = self.entities[i]
            entity:draw()
        end
    end

    --- @param entity Entity
    function self:addEntity(entity)
        table.insert(self.entities, entity)
    end

    --- @param entity Entity
    function self:removeEntity(entity)
        lume.remove(self.entities, entity)
    end

    --- @param uuid string
    --- @return Entity|nil
    function self:findEntity(uuid)
        return lume.match(self.entities, function(e)
            return e.uuid == uuid
        end)
    end

    return self
end

return scene