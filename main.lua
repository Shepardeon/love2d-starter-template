local shep = require('lib.shep')

---@type Game
local game

local player = {}

---@param scene Scene
function player.new(scene)
    ---@param self Player
    ---@param dt number
    local update = function(self, dt)
        self.x = self.x + 1
        self.stateMachine:update(dt)

        if scene.game.input:pressed('jump') then
            self.stateMachine:changeState(self.jumpState)
        end
    end

    ---@param self Player
    local draw = function(self)
        love.graphics.rectangle('fill', self.x, self.y, 10, 10)
    end

    ---@class Player: Entity
    local self = shep.entity.new(scene, update, draw)
    self.x = 0
    self.y = 0

    self.stateMachine = shep.stateMachine.new()

    function self:idleState()
        print("I am in idle state")
    end

    function self:exitIdleState()
        print("I am exiting idle state")
    end

    function self:jumpState()
        print("I am in jump state")
    end

    function self:enterJumpState()
        print("I am entering jump state")
    end

    self.stateMachine:addState(self.idleState, nil, self.exitIdleState)
    self.stateMachine:addState(self.jumpState, self.enterJumpState)
    self.stateMachine:changeState(self.idleState)

    return self
end

function love.load()
    game = shep.game.new()

    game:resizeGameWindow(1)

    local scene = shep.scene.new(game)
    local entity = player.new(scene)

    game:addScene(scene)
    game:switchScene(scene.sceneIndex)
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