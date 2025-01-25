local scene = {}
local lume = require('lib.lume')
local bump = require('lib.bump')
local camera = require('lib.shep.camera')

---@param game Game
---@param updateFn fun(self: Scene, dt: number)|nil
---@param drawFn fun(self: Scene)|nil
---@param enableFn fun(self: Scene)|nil
---@param disableFn fun(self: Scene)|nil
---@return Scene
function scene.new(game, updateFn, drawFn, enableFn, disableFn)
    --- @class Scene
    local self = {}
    self.entities = {}
    self.canvas = love.graphics.newCanvas(game.window.width, game.window.height)
    self.camera = camera.new(game.window.width, game.window.height, { center = true, maintainAspectRatio = true })
    self.world = bump.newWorld()

    self.camera:addLayer('close', 1.5, { relativeScale = 0.5 })
    self.camera:addLayer('far', 0.75)

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

        self.camera:update()
    end

    self.draw = drawFn or function()
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()

        self.camera:push()
            self.camera:push('far')

            for i = 1, #self.entities do
                local entity = self.entities[i]
                entity:draw()
            end

            self.camera:pop('far')

            -- Draw everything on the canvas
            for i = 1, #self.entities do
                local entity = self.entities[i]
                entity:draw()
            end

            self.camera:push('close')

            for i = 1, #self.entities do
                local entity = self.entities[i]
                entity:draw()
            end

            self.camera:pop('close')

        self.camera:pop()

        love.graphics.setCanvas()

        -- Draw the canvas
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setBlendMode('alpha', 'premultiplied')
        love.graphics.draw(self.canvas, 0, 0, 0, game.window.scaleX, game.window.scaleY)
        love.graphics.setBlendMode('alpha')
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

    self.sceneIndex = game:addScene(self)
    self.game = game

    return self
end

return scene