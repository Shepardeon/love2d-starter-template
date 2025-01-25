local shep = require('lib.shep')

---@type Game
local game

local player = {}

function player.new()
    ---@param self Player
    ---@param dt number
    local update = function(self, dt)
        self.x = self.x + 1
    end

    ---@param self Player
    local draw = function(self)
        love.graphics.rectangle('fill', self.x, self.y, 10, 10)
    end

    ---@class Player: Entity
    local self = shep.entity.new(update, draw)
    self.x = 0
    self.y = 0

    return self
end

function love.load()
    game = shep.game.new()
    local scene = shep.scene.new()
    local entity = player.new()

    local sceneIndex = game:addScene(scene)
    game:switchScene(sceneIndex)
    scene:addEntity(entity)
    scene:findEntity(entity.uuid)
    local alive = entity:isAlive()

    shep.utils.printAll("The entity is alive ?", alive)

    game.input:bind('space', 'jump')
    game.events:addEvent('onJump')
    game.events:hook('onJump', function()
        shep.utils.printText('Player jumped!', "I called that from an event!")
    end)
end

function love.update(dt)
    if (game.input:pressed('jump')) then
        game.events:fire('onJump')
    end

    game:update(dt)
end

function love.draw()
    game:draw()
end