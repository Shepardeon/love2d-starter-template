local Effect = require('lib.shep.shader.effect')

return function()
    local desaturate = Effect(
        'desaturate',
        love.graphics.newShader('assets/shaders/desaturate.glsl')
    )

    desaturate.setters = {
        ---@param val number
        saturation = function (val)
            val = val or 1
            desaturate.shader:send('saturation', val)
        end
    }

    desaturate.defaults = {
        saturation = 0
    }

    return desaturate:build()
end
