local scene = {}
local lume = require('lib.lume')
local bump = require('lib.bump')
local camera = require('lib.shep.camera')

---@param game shep.Game
---@param updateFn fun(self: shep.Scene, dt: number)|nil
---@param drawFn fun(self: shep.Scene)|nil
---@param enableFn fun(self: shep.Scene)|nil
---@param disableFn fun(self: shep.Scene)|nil
---@return shep.Scene
function scene.new(game, updateFn, drawFn, enableFn, disableFn)
    --- @class shep.Scene
    local self = {}
    self.entities = {}
    self.canvas = love.graphics.newCanvas(game.window.width, game.window.height)
    self.camera = camera.new(game.window.width, game.window.height, { center = true, maintainAspectRatio = true })
    self.world = bump.newWorld()

    self.enable = enableFn or function(this)
        -- do nothing
    end

    self.disable = disableFn or function(this)
        -- do nothing
    end

    --- @param dt number
    self.update = updateFn or function(this, dt)
        for i = #this.entities, 1, -1 do
            local entity = this.entities[i]
            entity:update(dt)
        end

        this.camera:update()
    end

    self.draw = drawFn or function(this)
        love.graphics.setCanvas(this.canvas)
        love.graphics.clear()

        this.camera:push()

            -- Draw everything on the canvas from the camera's perspective
            for i = 1, #this.entities do
                local entity = this.entities[i]
                entity:draw()
            end

            this.camera:pop()

        love.graphics.setCanvas()

        -- Draw the canvas
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setBlendMode('alpha', 'premultiplied')
        love.graphics.draw(this.canvas, 0, 0, 0, game.window.scaleX, game.window.scaleY)
        love.graphics.setBlendMode('alpha')
    end

    --- @param entity shep.Entity
    function self:addEntity(entity)
        table.insert(self.entities, entity)
    end

    --- @param entity shep.Entity
    function self:removeEntity(entity)
        lume.remove(self.entities, entity)
    end

    --- @param uuid string
    --- @return shep.Entity|nil
    function self:findEntity(uuid)
        return lume.match(self.entities, function(e)
            return e.uuid == uuid
        end)
    end

    self.sceneIndex = game:addScene(self)
    self.game = game

    return self
end

return scene