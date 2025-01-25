local game = {}

local format = string.format

---@return Game
function game.new()
    ---@class Game
    local self = {}
    self.scenes = {}
    self.currentScene = nil
    self.timeScale = 1

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
            error(format("Scene not found with index %i", index), 2)
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
        self.currentScene.update(dt * self.timeScale)
    end

    function self:draw()
        self.currentScene.draw()
    end

    return self
end

return game