local Camera = require('lib.shep.camera')
local Shader = require('lib.shep.shader')

---@alias shep.RenderPass { pipeline: shep.ShaderPipeline, canvas: love.Canvas, draw: fun() }
local emptyDraw = function() end

---@class shep.Renderer
---@field private width number
---@field private height number
---@field private renderScale number
---@field private mainCamera shep.Camera
---@field private mainCanvas love.Canvas
---@field private renderIndex table<string, number>
---@field private renderPasses table<number, shep.RenderPass>
local Renderer = Object:extend()

--- Creates a new Renderer instance.
---@param gameWidth number
---@param gameHeight number
---@param renderScale number
---@param cameraOptions shep.CameraOptions|nil
function Renderer:new(gameWidth, gameHeight, renderScale, cameraOptions)
    self.width = gameWidth
    self.height = gameHeight
    self.renderScale = renderScale

    self.mainCamera = Camera(gameWidth, gameHeight, cameraOptions)
    self.mainCanvas = love.graphics.newCanvas(gameWidth * renderScale, gameHeight * renderScale)
    self.renderIndex = {
        _main = 1
    }
    self.renderPasses = {
        [self.renderIndex._main] = {
            pipeline = Shader(Shader.Effects.passthrough, gameWidth * renderScale, gameHeight * renderScale),
            canvas = love.graphics.newCanvas(gameWidth * renderScale, gameHeight * renderScale),
            draw = emptyDraw
        }
    }
end

--- Adds a new render pass.
---@param name string
---@param order number
---@param effect shep.Effect|fun():shep.Effect
---@param draw fun()|nil
function Renderer:addRenderPass(name, order, effect, draw)
    if self.renderIndex[name] then
        error("Render pass with name '" .. name .. "' already exists", 2)
    end

    if self.renderPasses[order] then
        error("Render pass with order '" .. order .. "' already exists", 2)
    end

    self.renderIndex[name] = order
    self.renderPasses[order] = {
        pipeline = Shader(effect, self.width * self.renderScale, self.height * self.renderScale),
        canvas = love.graphics.newCanvas(self.width * self.renderScale, self.height * self.renderScale),
        draw = draw or emptyDraw
    }
end

--- Gets a render pass by name.
---@param name string
---@return shep.RenderPass
function Renderer:getRenderPass(name)
    if not self.renderIndex[name] then
        error("Render pass with name '" .. name .. "' does not exist", 2)
    end

    return self.renderPasses[self.renderIndex[name]]
end

--- Gets a render pipeline by name.
---@param name string
---@return shep.ShaderPipeline
function Renderer:getRenderPipeline(name)
    if not self.renderIndex[name] then
        error("Render pass with name '" .. name .. "' does not exist", 2)
    end

    return self.renderPasses[self.renderIndex[name]].pipeline
end

--- Sets the draw function for a render pass.
---@param name string
---@param draw fun()
function Renderer:setDrawFunction(name, draw)
    if not self.renderIndex[name] then
        error("Render pass with name '" .. name .. "' does not exist", 2)
    end

    self.renderPasses[self.renderIndex[name]].draw = draw
end

--- Resizes the renderer.
---@param newGameWidth number
---@param newGameHeight number
---@param newRenderScale number
function Renderer:resize(newGameWidth, newGameHeight, newRenderScale)
    self.width = newGameWidth
    self.height = newGameHeight
    self.renderScale = newRenderScale

    self.mainCanvas = love.graphics.newCanvas(newGameWidth * newRenderScale, newGameHeight * newRenderScale)
    self.mainCamera:resize(newGameWidth, newGameHeight)

    for _, pass in ipairs(self.renderPasses) do
        pass.pipeline:resize(newGameWidth * newRenderScale, newGameHeight * newRenderScale)
        pass.canvas = love.graphics.newCanvas(newGameWidth * newRenderScale, newGameHeight * newRenderScale)
    end
end

--- Draws the render passes.
function Renderer:draw()
    local bg_r, bg_g, bg_b, bg_a = love.graphics.getBackgroundColor()
    love.graphics.setBackgroundColor(0, 0, 0, 0) -- Set background to transparent
    love.graphics.setCanvas(self.mainCanvas)
    love.graphics.clear()

    local drawnPasses = 0
    for _, pass in ipairs(self.renderPasses) do
        -- Draw each pass to the main canvas
        love.graphics.setCanvas(pass.canvas)
        love.graphics.clear()

        pass.pipeline:push()
            pass.draw()
        pass.pipeline:pop()

        love.graphics.setCanvas(self.mainCanvas)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.draw(pass.canvas, 0, 0, 0)
        love.graphics.setBlendMode("alpha")
        drawnPasses = drawnPasses + 1
    end

    -- Draw the canvas to screen
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(self.mainCanvas, 0, 0, 0, self.renderScale, self.renderScale)
    love.graphics.setBlendMode("alpha")
    love.graphics.setBackgroundColor(bg_r, bg_g, bg_b, bg_a)
end

--- Gets the main camera.
---@return shep.Camera
function Renderer:getCamera()
    return self.mainCamera
end

--- Gets the main canvas.
---@return love.Canvas
function Renderer:getCanvas()
    return self.mainCanvas
end

return Renderer