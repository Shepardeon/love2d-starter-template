---@class shep.ShaderPipeline
---@field private effects table<number, shep.Effect>
---@field private disabled table<string, boolean>
---@field private state table
local Shader = Object:extend()
Shader.Effects = require('lib.shep.Shader.effects')

--- Initializes a new ShaderPipeline.
---@param effect shep.Effect|fun():shep.Effect
---@param width number|nil
---@param height number|nil
function Shader:new(effect, width, height)
    if height == nil then
        width, height = love.window.getMode()
    end

    self.front, self.back = love.graphics.newCanvas(width --[[@as number]], height), love.graphics.newCanvas(width --[[@as number]], height)
    self.effects = {}
    self.disabled = {}
    self.state = {}

    return self:next(effect)
end

--- Swaps the front and back buffers.
function Shader:buffer()
    self.back, self.front = self.front, self.back
    return self.front, self.back
end

--- Resizes the shader buffers.
---@param w number
---@param h number
function Shader:resize(w, h)
    self.front, self.back = love.graphics.newCanvas(w,h), love.graphics.newCanvas(w,h)
    return self
end

--- Adds a new effect to the pipeline.
---@param mEffect shep.Effect|fun():shep.Effect
function Shader:next(mEffect)
    if type(mEffect) == 'function' then
        mEffect = mEffect()
    end

    table.insert(self.effects, mEffect)
    return self
end

--- Pushes the current drawing state and sets up for drawing to the shader.
function Shader:push()
    -- save states
    self.state.canvas = love.graphics.getCanvas()
    self.state.Shader = love.graphics.getShader()
    self.state.fg_r, self.state.fg_g, self.state.fg_b, self.state.fg_a = love.graphics.getColor()

    -- allow to draw scene to front buffer
    love.graphics.setCanvas((self:buffer())) -- set back buffer as the current canvas
    love.graphics.clear(love.graphics.getBackgroundColor()) -- clear the back buffer

    -- User draws here before calling :pop()
end

--- Pops the drawing state and applies the shader effects.
function Shader:pop()
    -- User has drawn to the back buffer here

    -- save more states
    self.state.blendmode = love.graphics.getBlendMode()

    -- draw effects
    love.graphics.setColor(self.state.fg_r, self.state.fg_g, self.state.fg_b, self.state.fg_a)
    love.graphics.setBlendMode("alpha", "premultiplied")
    for _, eff in ipairs(self.effects) do
        if not self.disabled[eff.name] then
            (eff.draw or Shader.draw)(self, self.buffer, eff.Shader)
        end
    end

    -- present result
    love.graphics.setShader()
    love.graphics.setCanvas(self.state.canvas)
    love.graphics.draw(self.front)

    -- restore states
    love.graphics.setBlendMode(self.state.blendmode)
    love.graphics.setShader(self.state.Shader)
end

--- Disables one or more effects by name.
---@param name string -- Name of the effect to disable
---@param ... string -- Additional names to disable
---@return shep.ShaderPipeline
function Shader:disable(name, ...)
    if name then
        self.disabled[name] = true
        return Shader:disable(...)
    end

    return self
end

--- Enables one or more effects by name.
---@param name string -- Name of the effect to enable
---@param ... string -- Additional names to enable
---@return shep.ShaderPipeline
function Shader:enable(name, ...)
    if name then
        self.disabled[name] = nil
        return Shader:enable(...)
    end

    return self
end

--- Sends a parameter value to a specific effect.
---@param effectName string -- Name of the effect
---@param param string -- Name of the parameter to set
---@param value any -- Value to set the parameter to
---@return shep.ShaderPipeline
function Shader:send(effectName, param, value)
    for _, eff in ipairs(self.effects) do
        if eff.name == effectName then
            eff.setters[param](value)
        end
    end

    return self
end

--- Draws the shader effect.
---@param pipeline shep.ShaderPipeline
---@param buffer fun(pipeline: shep.ShaderPipeline): love.Canvas, love.Canvas
---@param ShaderObj love.Shader
function Shader.draw(pipeline, buffer, ShaderObj)
    local front, back = buffer(pipeline)
    love.graphics.setCanvas(front)
    love.graphics.clear()
    if Shader ~= love.graphics.getShader() then
        love.graphics.setShader(ShaderObj)
    end
    love.graphics.draw(back)
end

return Shader