--- @class shep.Effect
local Effect = Object:extend()

--- Initializes a new Effect.
---@param name string -- Name of the effect
---@param shader love.Shader|nil -- Love's compiled shader object
---@param setters table<string, fun(val: any)>|nil -- Table of functions to set the shader's data
---@param defaults table<string, any>|nil -- Table of default values for the shader
---@param draw fun(buffer: fun(pipeline: shep.ShaderPipeline): (love.Canvas, love.Canvas), shader: love.Shader)|nil -- Function to draw the effect if needed
function Effect:new(name, shader, setters, defaults, draw)
    self.name = name
    self.shader = shader
    self.setters = setters or {}
    self.defaults = defaults or {}
    self.draw = draw
end

--- Builds the effect by setting default values.
---@return shep.Effect
function Effect:build()
    for param, value in pairs(self.defaults) do
        if not self.setters[param] then
            error("No setter found for perameter: " .. param)
        end

        self.setters[param](value)
    end

    return self
end

return Effect