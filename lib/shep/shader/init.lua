local shader = {}
shader.effects = require('lib.shep.shader.effects')

---@param buffer fun(): love.Canvas, love.Canvas
---@param shaderObj love.Shader
function shader.draw(buffer, shaderObj)
    local front, back = buffer()
    love.graphics.setCanvas(front)
    love.graphics.clear()
    if shader ~= love.graphics.getShader() then
        love.graphics.setShader(shaderObj)
    end
    love.graphics.draw(back)
end

---@param effect shep.Effect|fun():shep.Effect
---@param width number|nil
---@param height number|nil
function shader.new(effect, width, height)
    if height == nil then
        width, height = love.window.getMode()
    end

    local front, back = love.graphics.newCanvas(width --[[@as number]], height), love.graphics.newCanvas(width --[[@as number]], height)
    local buffer = function()
        back, front = front, back
        return front, back
    end

    ---@class shep.ShaderPipeline
    ---@field private effects table<number, shep.Effect>
    ---@field private disabled table<string, boolean>
    ---@field private state table
    local self = {}
    self.effects = {}
    self.disabled = {}

    ---@param w number
    ---@param h number
    function self:resize(w, h)
        front, back = love.graphics.newCanvas(w,h), love.graphics.newCanvas(w,h)
        return self
    end

    ---@param mEffect shep.Effect|fun():shep.Effect
    function self:next(mEffect)
        if type(mEffect) == 'function' then
            mEffect = mEffect()
        end

        table.insert(self.effects, mEffect)
        return self
    end

    self.state = {}
    function self:push()
       -- save states
        self.state.canvas = love.graphics.getCanvas()
        self.state.shader = love.graphics.getShader()
        self.state.fg_r, self.state.fg_g, self.state.fg_b, self.state.fg_a = love.graphics.getColor()

        -- allow to draw scene to front buffer
        love.graphics.setCanvas((buffer())) -- set back buffer as the current canvas
        love.graphics.clear(love.graphics.getBackgroundColor()) -- clear the back buffer

        -- User draws here before calling :pop()
    end

    function self:pop()
        -- User has drawn to the back buffer here

        -- save more states
        self.state.blendmode = love.graphics.getBlendMode()

        -- draw effects
        love.graphics.setColor(self.state.fg_r, self.state.fg_g, self.state.fg_b, self.state.fg_a)
        love.graphics.setBlendMode("alpha", "premultiplied")
        for _, eff in ipairs(self.effects) do
            if not self.disabled[eff.name] then
                (eff.draw or shader.draw)(buffer, eff.shader)
            end
        end

        -- present result
        love.graphics.setShader()
        love.graphics.setCanvas(self.state.canvas)
        love.graphics.draw(front)

        -- restore states
        love.graphics.setBlendMode(self.state.blendmode)
        love.graphics.setShader(self.state.shader)
    end

    ---@param name string -- Name of the effect to disable
    ---@param ... string -- Additional names to disable
    ---@return shep.ShaderPipeline
    function self:disable(name, ...)
        if name then
            self.disabled[name] = true
            return self:disable(...)
        end

        return self
    end

    ---@param name string -- Name of the effect to enable
    ---@param ... string -- Additional names to enable
    ---@return shep.ShaderPipeline
    function self:enable(name, ...)
        if name then
            self.disabled[name] = nil
            return self:enable(...)
        end

        return self
    end

    ---@param effectName string -- Name of the effect
    ---@param param string -- Name of the parameter to set
    ---@param value any -- Value to set the parameter to
    ---@return shep.ShaderPipeline
    function self:send(effectName, param, value)
        for _, eff in ipairs(self.effects) do
            if eff.name == effectName then
                eff.setters[param](value)
            end
        end

        return self
    end

    return self:next(effect)
end

return shader