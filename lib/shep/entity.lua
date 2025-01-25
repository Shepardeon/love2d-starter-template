local entity = {}
local lume = require('lib.lume')

---@param updateFn fun(self: Entity, dt: number)|nil
---@param drawFn fun(self: Entity, dt: number)|nil
---@return Entity
function entity.new(updateFn, drawFn)
    --- @class Entity
    local self = {}
    self.uuid = lume.uuid()
    self.alive = true

    self.update = updateFn or function(dt)
        -- do nothing
    end

    self.draw = drawFn or function()
        -- do nothing
    end

    function self:isAlive()
        return self.alive
    end

    return self
end

return entity