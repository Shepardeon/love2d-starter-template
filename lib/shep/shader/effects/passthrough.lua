local Effect = require('lib.shep.shader.effect')

return function ()
    local passthrough = Effect(
        'passthrough'
    )

    passthrough.draw = function (pipeline, buffer, shaderObj)
        local front, back = buffer(pipeline)
        love.graphics.setCanvas(front)
        love.graphics.clear()
        love.graphics.draw(back)
    end

    return passthrough:build()
end