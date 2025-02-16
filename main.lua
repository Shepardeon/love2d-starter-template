local shep = require('lib.shep')

---@type shep.Game
local game
---@type shep.Renderer
local renderer
---@type shep.Camera
local camera
---@type Player
local myPlayer

local gameScale = 1

-- Use shep's debug run function to get debug information
love.run = shep.debug.run

--#region Player
---@class Player: shep.Entity
local Player = shep.Entity:extend()

---@param scene shep.Scene
function Player:new(scene)
    self.super.new(self, scene)

    self.x = -450
    self.y = 0

    --- Test atlas
    self.spriteAtlas = shep.Atlas('assets/ranger_f.png', {
        tileWidth = 15*2,
        tileHeight = 18*2,
        spacingX = 1,
    })

    --- Animator with shared atlas => will use sprite batching
    self.animator = shep.Animator(self.spriteAtlas)

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

    ---@type shep.StateMachine
    self.stateMachine = shep.StateMachine()

    self.stateMachine:addState(self, self.idleState, nil, self.exitIdleState)
    self.stateMachine:addState(self, self.jumpState, self.enterJumpState)
    self.stateMachine:changeState(self.idleState)
end

function Player:update(dt)
    self.x = self.x + 100 * dt
    self.stateMachine:update(dt)
    self.animator:update(dt)

    if self.scene.game.input:pressed('jump') then
        self.stateMachine:changeState(self.jumpState)

        if self.currentAnimation == 'walk_right' then
            self.currentAnimation = 'walk_left'
        else
            self.currentAnimation = 'walk_right'
        end

        self.animator:setAnimation(self.currentAnimation)
    end
end

function Player:draw()
    self.spriteAtlas:drawQuad('walk_right1', 150, -150)
    self.spriteAtlas:drawQuad('walk_right2', 150, -100)
    self.spriteAtlas:drawQuad('walk_right3', 150, -50)

    self.animator:draw(self.x, self.y)
    self.spriteAtlas:draw()
end

function Player:idleState()
    print("I am in idle state")
    print("My UUID is", self.uuid)
end

function Player:exitIdleState()
    print("I am exiting idle state")
end

function Player:jumpState()
    print("I am in jump state")
end

function Player:enterJumpState()
    print("I am entering jump state")
end
--#endregion

local renderPipeline
local shaderParams = { saturation = 1 }
local images = {}
local finishedLoading = false

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    -- Initialize the game and renderer
    game = shep.Game()
    renderer = shep.Renderer(game.window.width, game.window.height, gameScale,
    {
        center = true,
        maintainAspectRatio = true,
        smoothingFunction = shep.Camera.smoothingFunctions.linear(75)
    })

    shep.localization:loadFromDirectory('assets/lang')

    -- Get the camera from the renderer
    camera = renderer:getCamera()
    camera:addLayer('far', 0.5)
    camera:addLayer('near', 2)

    -- Create a new scene and add the player to it
    local scene = shep.Scene(game)
    myPlayer = Player(scene)

    -- Switch to the new scene
    game:switchScene(scene.sceneIndex)
    scene:findEntity(myPlayer.uuid)
    local alive = myPlayer:isAlive()

    shep.utils.printAll("The entity is alive ?", alive)

    -- Bind input actions
    game.input:bind('space', 'jump')
    game.input:bind('s', function()
        camera:shake(6, 60, 0.4)
    end)
    game.input:bind('f1', function()
        shep.debug.config.drawDebug = not shep.debug.config.drawDebug
    end)
    game.input:bind('f2', function()
        shep.debug.config.drawGraph = not shep.debug.config.drawGraph
    end)
    game.input:bind('f3', function ()
        local locale = shep.localization.currentLocale == 'en' and 'fr' or 'en'
        shep.localization:setLocale(locale)
    end)

    -- Add and hook events
    game.events:addEvent('onJump')
    game.events:hook('onJump', function()
        shep.utils.printText('Player jumped!', "I called that from an event!")
    end)

    game.events:hook('gameResized', function(w, h, scale)
        renderer:resize(w, h, scale)
    end)

    -- Resize the game window
    game:resizeGameWindow(gameScale)

    -- Set the draw function for the renderer
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

    -- Set up the render pipeline
    renderPipeline = renderer:getRenderPipeline('_main')
    renderPipeline:next(shep.Shader.Effects.desaturate)
    game.globalTimer:tween(8, shaderParams, { saturation = 0 }, 'in-out-cubic')

    -- Add a render pass for the UI
    renderer:addRenderPass('ui', 2, shep.Shader.Effects.passthrough, function()
        if not finishedLoading then
            love.graphics.print('Loading...', 10, 350)
        else
            love.graphics.print('Loaded!', 10, 350)
            love.graphics.draw(images.testImage, 10, 370)
        end

        love.graphics.print('curren locale: ' .. shep.localization.currentLocale, 110, 390)
        love.graphics.print('localization test: ' .. shep.localization:t('testFallback'), 110, 410)
        love.graphics.print('localization hello: ' .. shep.localization:t('hello'), 110, 430)
        love.graphics.print('localization world: ' .. shep.localization:t('world'), 110, 450)
        love.graphics.print('localization welcome: ' .. shep.localization:t('welcome'), 110, 470)
        love.graphics.print('localization goodbye: ' .. shep.localization:t('goodbye'), 110, 490)
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

function love.draw()
    renderer:draw()
    if not shep.debug.config.drawDebug then
        love.graphics.print('Press F1 to toggle debug', 10, 10)
    end
    shep.debug.draw(0, 0, 1, 1)
end