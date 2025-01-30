local effect = {}

---@param name string -- Name of the effect
---@param shader love.Shader -- Love's compiled shader object
---@param setters table<string, fun(val: any)> -- Table of functions to set the shader's data
---@param defaults table<string, any> -- Table of default values for the shader
---@param draw fun(inst: shep.ShaderPipeline, buffer: fun(shader: shep.ShaderPipeline): (love.Canvas, love.Canvas), shader: love.Shader)|nil -- Function to draw the effect if needed
---@return shep.Effect
function effect.new(name, shader, setters, defaults, draw)
    --- @class shep.Effect
    local self = {}
    self.name = name
    self.shader = shader
    self.setters = setters
    self.defaults = defaults
    self.draw = draw

    for param, value in pairs(defaults) do
        if not setters[param] then
            error("No setter found for perameter: " .. param)
        end

        self.setters[param](value)
    end

    return self
end

return effect