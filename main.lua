local shep = require('lib.shep')
local timer = require('lib.hump.timer')

---@type shep.Game
local game
---@type shep.Renderer
local renderer
---@type shep.Camera
local camera
---@type Player
local myPlayer

local gameScale = 1

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
        self.spriteAtlas:drawQuad('walk_right1', 150, -150)
        self.spriteAtlas:drawQuad('walk_right2', 150, -100)
        self.spriteAtlas:drawQuad('walk_right3', 150, -50)

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

local renderPipeline
local shaderParams = { saturation = 1 }
local images = {}
local finishedLoading = false
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    game = shep.game.new()
    renderer = shep.renderer.new(game.window.width, game.window.height, gameScale,
    {
        center = true,
        maintainAspectRatio = true,
        smoothingFunction = shep.camera.smoothingFunctions.linear(75)
    })

    camera = renderer:getCamera()
    camera:addLayer('far', 0.5)
    camera:addLayer('near', 2)

    local scene = shep.scene.new(game)
    myPlayer = player.new(scene)

    game:switchScene(scene.sceneIndex)
    scene:findEntity(myPlayer.uuid)
    local alive = myPlayer:isAlive()

    shep.utils.printAll("The entity is alive ?", alive)

    game.input:bind('space', 'jump')
    game.input:bind('s', function()
        camera:shake(6, 60, 0.4)
    end)

    game.events:addEvent('onJump')
    game.events:hook('onJump', function()
        shep.utils.printText('Player jumped!', "I called that from an event!")
    end)

    game.events:hook('gameResized', function(w, h, scale)
        renderer:resize(w, h, scale)
    end)

    game:resizeGameWindow(gameScale)

    renderer:setDrawFunction('_main', function()
        camera:push('far')
        game:draw()
        camera:pop('far')

        camera:push()
        game:draw()
        camera:pop()

        camera:push('near')
        game:draw()
        camera:pop('near')
    end)

    renderPipeline = renderer:getRenderPipeline('_main')
    renderPipeline:next(shep.shader.effects.desaturate)
    game.globalTimer:tween(8, shaderParams, { saturation = 0 }, 'in-out-cubic')

    renderer:addRenderPass('ui', 2, shep.shader.effects.passthrough, function()
        love.graphics.print('FPS:' .. love.timer.getFPS() , 10, 10)

        if not finishedLoading then
            love.graphics.print('Loading...', 10, 25)
        else
            love.graphics.print('Loaded!', 10, 25)
            love.graphics.draw(images.testImage, 10, 50)
        end
    end)

    -- Test loading an image
    shep.loader:newImage(images, 'testImage', 'assets/ranger_f.png')
    shep.loader:start(nil, function()
        shep.utils.printAll("All data loaded", "Image loaded", images.testImage)
        finishedLoading = true
    end)
end

function love.update(dt)
    if (game.input:pressed('jump')) then
        game.events:fire('onJump')
    end
    renderPipeline:send('desaturate', 'saturation', shaderParams.saturation)

    camera:update()
    -- Test: follow the player
    camera:followLockScreenOutside(dt, myPlayer.x, myPlayer.y, -200, 0, 200, 0)

    game:update(dt)

    if not finishedLoading then
        shep.loader:update()
    end
end

function love.resize(w, h)
    local newScale = math.min(w / game.window.width, h / game.window.height)
    game:resizeGameWindow(newScale)
end

--TODO: rework everything here in a rendering pipeline
function love.draw()
    renderer:draw()
end