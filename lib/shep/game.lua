local game = {}
local eventManager = require("lib.shep.eventManager")
local inputManager = require("lib.shep.inputManager")

---@return Game
function game.new()
    ---@class Game
    ---@field private scenes table<Scene>
    ---@field private currentScene Scene
    ---@field private timeScale number
    ---@field events EventManager
    ---@field input InputManager
    local self = {}
    self.scenes = {}
    self.currentScene = nil
    self.timeScale = 1

    self.events = eventManager.new()
    self.input = inputManager.new()

    ---@param scene Scene
    ---@return number # Scene index
    function self:addScene(scene)
        table.insert(self.scenes, scene)
        return #self.scenes
    end

    ---@param index integer
    function self:switchScene(index)
        local scene = self.scenes[index]
        if scene == nil then
            error("Scene not found with index " .. index, 2)
        end

        if self.currentScene then
            self.currentScene.disable()
        end

        self.currentScene = scene
        self.currentScene.enable()
    end

    ---@param timeScale number
    function self:setTimeScale(timeScale)
        self.timeScale = timeScale
    end

    ---@param dt number
    function self:update(dt)
        self.input:update()
        self.currentScene.update(dt * self.timeScale)
    end

    function self:draw()
        self.currentScene.draw()
    end

    return self
end

return game