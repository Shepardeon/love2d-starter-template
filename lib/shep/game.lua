local eventManager = require("lib.shep.eventManager")
local inputManager = require("lib.shep.inputManager")
local timer = require("lib.hump.timer")

---@class shep.Game: Object
---@field private scenes table<shep.Scene>
---@field private currentScene shep.Scene
---@field private timeScale number
---@field window table<string, number>
---@field events shep.EventManager
---@field input shep.InputManager
local Game = Object:extend()

---@class shep.GameWindow
---@field width number
---@field height number
---@field scaleX number
---@field scaleY number
local defaultWindowOptions = {
    width = 960,
    height = 540,
    scaleX = 1,
    scaleY = 1
}

---@param windowOptions shep.GameWindow|nil
function Game:new(windowOptions)
    self.scenes = {}
    self.currentScene = nil
    self.timeScale = 1
    self.window =  windowOptions or defaultWindowOptions

    self.globalTimer = timer()
    self.events = eventManager()
    self.input = inputManager()

    self.events:addEvent('gameResized')
end

---@param scene shep.Scene
---@return number # Scene index
function Game:addScene(scene)
    table.insert(self.scenes, scene)
    return #self.scenes
end

---@param index integer
function Game:switchScene(index)
    local scene = self.scenes[index]
    if scene == nil then
        error("Scene not found with index " .. index, 2)
    end

    if self.currentScene then
        self.currentScene:disable()
    end

    self.currentScene = scene
    self.currentScene:enable()
end

---@param scale number
function Game:resizeGameWindow(scale)
    love.window.setMode(self.window.width * scale, self.window.height * scale, { resizable = true })
    self.window.scaleX = scale
    self.window.scaleY = scale

    self.events:fire('gameResized', self.window.width, self.window.height, scale)
end

---@return number
---@return number
function Game:getGameWindowSize()
    return self.window.width, self.window.height
end

---@param timeScale number
function Game:setTimeScale(timeScale)
    self.timeScale = timeScale
end

---@param timeScale number
---@param duration number
function Game:setTimeScaleFor(timeScale, duration)
    self.timeScale = timeScale
    self.globalTimer:tween('timeScale', duration, self, {timeScale = 1}, 'in-out-cubic')
end

---@param dt number
function Game:update(dt)
    self.currentScene:update(dt * self.timeScale)
    self.input:update()
    self.globalTimer:update(dt)
end

function Game:draw()
    self.currentScene:draw()
end

return Game