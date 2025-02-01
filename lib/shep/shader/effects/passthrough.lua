local effect = require('lib.shep.shader.effect')

return function ()
    local passthrough = effect.new(
        'passthrough'
    )

    passthrough.draw = function (buffer, shaderObj)
        local front, back = buffer()
        love.graphics.setCanvas(front)
        love.graphics.clear()
        love.graphics.draw(back)
    end

    return passthrough:build()
end