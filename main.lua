local shep = require('lib.shep')

---@type shep.Game
local game

local player = {}

---@param scene shep.Scene
function player.new(scene)
    ---@param self Player
    ---@param dt number
    local update = function(self, dt)
        self.x = self.x + 100 * dt
        self.stateMachine:update(dt)
        self.animator:update(dt)

        if scene.game.input:pressed('jump') then
            self.stateMachine:changeState(self.jumpState)

            if self.currentAnimation == 'walk_right' then
                self.currentAnimation = 'walk_left'
            else
                self.currentAnimation = 'walk_right'
            end

            self.animator:setAnimation(self.currentAnimation)
        end
    end

    ---@param self Player
    local draw = function(self)
        self.spriteAtlas:drawQuad('walk_right1', -150, -150)
        self.spriteAtlas:drawQuad('walk_right2', -150, -100)
        self.spriteAtlas:drawQuad('walk_right3', -150, -50)
        
        self.animator:draw(self.x, self.y)
        self.spriteAtlas:draw()
    end

    ---@class Player: shep.Entity
    local self = shep.entity.new(scene, update, draw)
    self.x = -450
    self.y = 0

    --- Test atlas
    self.spriteAtlas = shep.atlas.new('assets/ranger_f.png', {
        tileWidth = 15*2,
        tileHeight = 18*2,
        spacingX = 1,
    })

    --- Animator with shared atlas => will use sprite batching
    self.animator = shep.animator.new(self.spriteAtlas)

    self.spriteAtlas:addQuad('walk_right1', 0, 1)
    self.spriteAtlas:addQuad('walk_right2', 1, 1)
    self.spriteAtlas:addQuad('walk_right3', 2, 1)

    --- Animations can be built directly from the atlas
    local walkRightFrames = {'walk_right1', 'walk_right2', 'walk_right3', 'walk_right2'}
    self.animator:addAnimation('walk_right', walkRightFrames, {0.1, 0.1, 0.1, 0.1})
    self.animator:setAnimation('walk_right')

    --- Or they can be created directly from the animator
    local walkLeftFrames = self.animator:getFrames('walk_left', 0,3, 1,3, 2,3, 1,3)
    self.animator:addAnimation('walk_left', walkLeftFrames, {0.1, 0.1, 0.1, 0.1})

    self.currentAnimation = 'walk_right'

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

local effect
local effect

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    game = shep.game.new()

    game:resizeGameWindow(1)

    local scene = shep.scene.new(game)
    local entity = player.new(scene)

    game:switchScene(scene.sceneIndex)
    scene:findEntity(entity.uuid)
    local alive = entity:isAlive()

    shep.utils.printAll("The entity is alive ?", alive)

    game.input:bind('space', 'jump')
    game.input:bind('s', function()
        scene.camera:shake(6, 60, 0.4)
    end)

    game.events:addEvent('onJump')
    game.events:hook('onJump', function()
        shep.utils.printText('Player jumped!', "I called that from an event!")
    end)

    effect = shep.shader.new(shep.shader.effects.desaturate)
end

function love.update(dt)
    if (game.input:pressed('jump')) then
        game.events:fire('onJump')
    end

    game:update(dt)
end

local function buffer()
    game.currentScene.back, game.currentScene.front = game.currentScene.front, game.currentScene.back
    return game.currentScene.front, game.currentScene.back
end

local state = {}
local function push()
    state.canvas = love.graphics.getCanvas()
    state.shader = love.graphics.getShader()
    state.fg_r, state.fg_g, state.fg_b, state.fg_a = love.graphics.getColor()

    -- draw scene to front buffer
    love.graphics.setCanvas((buffer())) -- parens are needed: take only front buffer
    love.graphics.clear(love.graphics.getBackgroundColor())
end

local function pop()
    -- save more state
    state.blendmode = love.graphics.getBlendMode()

    -- process all shaders
    love.graphics.setColor(state.fg_r, state.fg_g, state.fg_b, state.fg_a)
    love.graphics.setBlendMode("alpha", "premultiplied")
    -- for _,e in ipairs(chain) do
    --   if not disabled[e.name] then
    --     (e.draw or moonshine.draw_shader)(buffer, e.shader)
    --   end
    -- end

    local result = shep.shader.effects.desaturate().shader
    shep.shader.draw(buffer, result)

    -- present result
    love.graphics.setShader()
    love.graphics.setCanvas(state.canvas)
    love.graphics.draw(game.currentScene.front)

    -- restore state
    love.graphics.setBlendMode(state.blendmode)
    love.graphics.setShader(state.shader)
end

function love.draw()
    push()
    game:draw()
    pop()
end