local camera = {}
local lume = require('lib.lume')
local utils = require('lib.shep.utils')

local min = math.min

---@class shep.CameraOptions
local defaultCamOptions = {
    ---@type boolean
    resizable = false,
    ---@type boolean
    maintainAspectRatio = false,
    ---@type boolean
    center = false,
    ---@type number
    aspectRatioScale = 1,
    ---@type love.StackType
    mode = 'transform'
}

---@class shep.CameraLayerOptions
local defaultLayerOptions = {
    ---@type number -- Controls how much the layer is translated based on the layer's scale
    speedToScaleRatio = 1,
    ---@type love.StackType
    mode = 'transform'
}

---@param width number
---@param height number
---@param options shep.CameraOptions|nil
---@return shep.Camera
function camera.new(width, height, options)
    --- @class shep.Camera
    --- @field private resizable boolean
    --- @field private maintainAspectRatio boolean
    --- @field private center boolean
    --- @field private aspectRatioScale number
    --- @field private mode love.StackType
    --- @field private layers table<string, shep.CameraLayer>
    local self = {
        resizable = false,
        maintainAspectRatio = false,
        center = false,
        aspectRatioScale = 1,
        mode = 'transform',
        layers = {}
    }
    self.x = 0
    self.y = 0
    self.width = width
    self.height = height
    self.translationX = 0
    self.translationY = 0
    self.offsetX = width / 2
    self.offsetY = height / 2
    self.scale = 1
    self.rotation = 0

    lume.merge(self, options or defaultCamOptions)

    function self:update()
        if self.resizable then self:resizingFunction(self:getContainerDimensions()) end
    end

    ---@param containerW number
    ---@param containerH number
    function self:resizingFunction(containerW, containerH)
        local scaleW, scaleH = containerW / self.width, containerH / self.height

        if self.maintainAspectRatio then
            containerW, containerH = containerW - 2 * self.x, containerH - 2 * self.y
            local scale = min(scaleW, scaleH)
            self.width, self.height = scale * self.width, scale * self.height
        else
            self.width, self.height = scaleW * self.width, scaleH * self.height
        end

        self.aspectRatioScale = self.width / width
        self.offsetX, self.offsetY = self.width / 2, self.height / 2

        if self.center then
            self.offsetX = self.offsetX + (containerW - self.width) / 2
            self.offsetY = self.offsetY + (containerH - self.height) / 2
        end
    end

    function self:getContainerDimensions()
        return love.graphics.getDimensions()
    end

    ---@param name string
    ---@param scale number
    ---@param layerOptions shep.CameraLayerOptions|nil
    function self:addLayer(name, scale, layerOptions)
        --- @class shep.CameraLayer
        local layer = {}
        layer.name = name
        layer.scale = scale
        layer.speedToScaleRatio = 1
        layer.mode = self.mode
        layer.push = function()
            love.graphics.push(layer.mode)
            love.graphics.origin()
            love.graphics.translate(self.x + self.offsetX, self.y + self.offsetY)
            love.graphics.rotate(self.rotation)
            love.graphics.scale(self.scale * self.aspectRatioScale * layer.scale)
            love.graphics.translate(-self.translationX * layer.speedToScaleRatio, -self.translationY * layer.speedToScaleRatio)
        end
        layer.pop = love.graphics.pop

        lume.merge(layer, layerOptions or defaultLayerOptions)

        self.layers[name] = layer
        return layer
    end

    ---@param name string
    ---@return shep.CameraLayer
    function self:getLayer(name)
        if self.layers[name] == nil then
            error("Layer not found with name " .. name, 2)
        end

        return self.layers[name]
    end

    ---@param layer string|nil
    function self:push(layer)
        self:getLayer(layer or "main"):push()
    end

    ---@param layer string|nil
    function self:pop(layer)
        self:getLayer(layer or "main"):pop()
    end

    ---@param x number
    ---@param y number
    ---@param layer string|nil
    function self:getWorldCoordinates(x, y, layer)
        local currentLayer = self:getLayer(layer or "main")
        local scaleFactor = self.scale * self.aspectRatioScale * currentLayer.scale
        x, y = x - self.x - self.offsetX, y - self.y - self.offsetY
        x, y = utils.rotateAboutPoint(x, y, 0, 0, -self.rotation)
        x, y = x / scaleFactor, y / scaleFactor
        return x + self.translationX * currentLayer.speedToScaleRatio, y + self.translationY * currentLayer.speedToScaleRatio
    end

    ---@param x number
    ---@param y number
    ---@param layer string|nil
    function self:getScreenCoordinates(x, y, layer)
        local currentLayer = self:getLayer(layer or "main")
        local scaleFactor = self.scale * self.aspectRatioScale * currentLayer.scale
        x, y = x - self.translationX / currentLayer.speedToScaleRatio, y - self.translationY / currentLayer.speedToScaleRatio
        x, y = x * scaleFactor, y * scaleFactor
        x, y = utils.rotateAboutPoint(x, y, 0, 0, self.rotation)
        return x + self.x + self.offsetX, y + self.y + self.offsetY
    end

    ---@param layer string|nil
    function self:getMouseWorldCoordinates(layer)
        local x, y = love.mouse.getPosition()
        return self:getWorldCoordinates(x, y, layer)
    end

    ---@param ds number
    ---@param wx number|nil
    ---@param wy number|nil
    function self:increaseScaleToPoint(ds, wx, wy)
        if not wx then
            wx, wy = self:getMouseWorldCoordinates()
        end

        local tx, ty = self.translationX, self.translationY
        self:increaseScale(ds)
        self:increaseTranslation((wx - tx) * ds / self.scale, (wy - ty) * ds / self.scale)
    end

    ---@param ds number
    ---@param wx number|nil
    ---@param wy number|nil
    function self:scaleToPoint(ds, wx, wy)
        if not wx then
            wx, wy = self:getMouseWorldCoordinates()
        end

        local tx, ty = self.translationX, self.translationY
        self:scaleBy(ds)
        self:increaseTranslation((wx - tx) * (1 - 1 / ds), (wy - ty) * (1 - 1 / ds))
    end

    ---@param dx number
    ---@param dy number
    function self:increaseTranslation(dx, dy)
        self.translationX, self.translationY = self.translationX + dx, self.translationY + dy
    end

    ---@param dr number
    function self:increaseRotation(dr)
        self.rotation = self.rotation + dr
    end

    ---@param ds number
    function self:increaseScale(ds)
        self.scale = self.scale + ds
    end

    ---@param ds number
    function self:scaleBy(ds)
        self.scale = self.scale * ds
    end

    self.translate = self.increaseTranslation
    self.rotate = self.increaseRotation

    self:addLayer("main", 1)

    if self.center then
        local containerW, containerH = self:getContainerDimensions()
        self.offsetX = self.offsetX + (containerW - self.width) / 2
        self.offsetY = self.offsetY + (containerH - self.height) / 2
    end

    return self
end

return camera