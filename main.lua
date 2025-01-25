local lume = require('lib.lume')
local shep = require('lib.shep')

function love.load()
    local game = shep.game.new()
    local scene = shep.scene.new()
    local entity = shep.entity.new()

    local sceneIndex = game:addScene(scene)
    game:switchScene(sceneIndex)
    scene:addEntity(entity)
    scene:removeEntity(entity)
    scene:findEntity(entity.uuid)
    local alive = entity:isAlive()

    shep.utils.printAll("The entity is alive ?", alive)
end

function love.update(dt)
end

function love.draw()
end