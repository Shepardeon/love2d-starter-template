local effect = {}

---@param name string -- Name of the effect
---@param shader love.Shader|nil -- Love's compiled shader object
---@param setters table<string, fun(val: any)>|nil -- Table of functions to set the shader's data
---@param defaults table<string, any>|nil -- Table of default values for the shader
---@param draw fun(buffer: fun(): (love.Canvas, love.Canvas), shader: love.Shader)|nil -- Function to draw the effect if needed
---@return shep.Effect
function effect.new(name, shader, setters, defaults, draw)
    --- @class shep.Effect
    local self = {}
    self.name = name
    self.shader = shader
    self.setters = setters or {}
    self.defaults = defaults or {}
    self.draw = draw

    ---@return shep.Effect
    function self:build()
        for param, value in pairs(self.defaults) do
            if not self.setters[param] then
                error("No setter found for perameter: " .. param)
            end

            self.setters[param](value)
        end

        return self
    end

    return self
end

return effect