local shep = require('lib.shep')

---@type Game
local game

function love.load()
    game = shep.game.new()
    local scene = shep.scene.new()
    local entity = shep.entity.new()

    local sceneIndex = game:addScene(scene)
    game:switchScene(sceneIndex)
    scene:addEntity(entity)
    scene:removeEntity(entity)
    scene:findEntity(entity.uuid)
    local alive = entity:isAlive()

    shep.utils.printAll("The entity is alive ?", alive)

    game.input:bind('space', 'jump')
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end