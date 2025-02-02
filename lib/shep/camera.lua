local camera = {}
local lume = require('lib.lume')
local utils = require('lib.shep.utils')

local min = math.min

camera.smoothingFunctions = {
    none = function()
        return function(dt, dx, dy) return dx,dy end
    end,

    linear = function(speed)
        return function(dt, dx, dy, s)
            local d = utils.length(dx, dy)
            local dts = min((s or speed) * dt, d)
            if d > 0 then
                dx, dy = dx / d, dy / d
            end

            return dx * dts, dy * dts
        end
    end,

    damped = function(stiffness)
        return function(dt, dx, dy, s)
            local dts = dt * (s or stiffness)
            return dx * dts, dy * dts
        end
    end
}

camera.shake = {}

---@param amplitude number
---@param frequency number
---@param duration number
function camera.shake.new(amplitude, frequency, duration)
    --- @class shep.Shake
    --- @field private amplitude number
    --- @field private frequency number
    --- @field private duration number
    --- @field private samples table<number>
    --- @field private startTime number
    --- @field private t number
    --- @field private shaking boolean
    local self = {}
    self.amplitude = amplitude
    self.frequency = frequency
    self.duration = duration * 1000

    local sampleCount = (self.duration / 1000) * frequency
    self.samples = {}
    for i = 1 , sampleCount do
        self.samples[i] = lume.random(-1, 1)
    end

    self.startTime = love.timer.getTime()*1000
    self.t = 0
    self.shaking = true

    function self:update()
        self.t = love.timer.getTime()*1000 - self.startTime
        if self.t > self.duration then
            self.shaking = false
        end
    end

    ---@param t number|nil
    function self:getAmplitude(t)
        if not t then
            if not self.shaking then return 0 end
            t = self.t
        end

        local rawSamples = (t / 1000) * self.frequency
        local sample0 = math.floor(rawSamples)
        local sample1 = sample0 + 1
        local decay = self:decay(t)

        return self.amplitude * (self:noise(sample0) + (rawSamples - sample0) * (self:noise(sample1) - self:noise(sample0))) * decay
    end

    ---@private
    ---@param sample number
    function self:noise(sample)
        return sample < #self.samples and self.samples[sample] or 0
    end

    ---@private
    ---@param t number
    function self:decay(t)
        return t <= self.duration and (self.duration - t) / self.duration or 0
    end

    return self
end

---@class shep.CameraOptions
local defaultCamOptions = {
    ---@type boolean|nil
    maintainAspectRatio = false,
    ---@type boolean|nil
    center = false,
    ---@type number|nil
    aspectRatioScale = 1,
    ---@type love.StackType|nil
    mode = 'transform',
    ---@type function|nil
    smoothingFunction = camera.smoothingFunctions.none()
}

---@class shep.CameraLayerOptions
local defaultLayerOptions = {
    ---@type number|nil -- Controls how much the layer is translated based on the layer's scale
    speedToScaleRatio = 1,
    ---@type love.StackType|nil
    mode = 'transform'
}

---@param width number
---@param height number
---@param options shep.CameraOptions|nil
---@return shep.Camera
function camera.new(width, height, options)
    --- @class shep.Camera
    --- @field private maintainAspectRatio boolean
    --- @field private center boolean
    --- @field private aspectRatioScale number
    --- @field private mode love.StackType
    --- @field private layers table<string, shep.CameraLayer>
    --- @field private smoothingFunction function
    --- @field private x number
    --- @field private y number
    --- @field private width number
    --- @field private height number
    --- @field private translationX number
    --- @field private translationY number
    --- @field private offsetX number
    --- @field private offsetY number
    --- @field private scale number
    --- @field private rotation number
    --- @field private shakes { x: table<shep.Shake>, y: table<shep.Shake> }
    --- @field private viewportShakes { x: table<shep.Shake>, y: table<shep.Shake> }
    local self = {}

    self.layers = {}
    self.x = 0
    self.y = 0
    self.width = width
    self.height = height
    self.translationX = 0
    self.translationY = 0
    self.offsetX = 0
    self.offsetY = 0
    self.scale = 1
    self.rotation = 0

    self.shakes = { x = {}, y = {} }
    self.viewportShakes = { x = {}, y = {} }

    options = lume.merge(defaultCamOptions, options or {})
    self = lume.merge(options, self)

    ---@private
    ---@param shakes table<shep.Shake>
    ---@return number
    function self:sumShakes(shakes)
        local shakeAmount = 0

        for i = #shakes, 1, -1 do
            shakes[i]:update()
            shakeAmount = shakeAmount + shakes[i]:getAmplitude()

            if not shakes[i].shaking then
                table.remove(shakes, i)
            end
        end

        return shakeAmount
    end

    function self:update()
        local xShakeAmount, yShakeAmount = self:sumShakes(self.shakes.x), self:sumShakes(self.shakes.y)
        local xViewportShakeAmount, yViewportShakeAmount = self:sumShakes(self.viewportShakes.x), self:sumShakes(self.viewportShakes.y)

        self:move(xShakeAmount, yShakeAmount)
        self:moveViewport(xViewportShakeAmount, yViewportShakeAmount)
    end

    ---@param amplitude number
    ---@param frequency number
    ---@param duration number
    function self:shake(amplitude, frequency, duration)
        self:shakeX(amplitude, frequency, duration)
        self:shakeY(amplitude, frequency, duration)
    end

    ---@param amplitude number
    ---@param frequency number
    ---@param duration number
    function self:shakeX(amplitude, frequency, duration)
        table.insert(self.shakes.x, camera.shake.new(amplitude, frequency, duration))
    end

    ---@param amplitude number
    ---@param frequency number
    ---@param duration number
    function self:shakeY(amplitude, frequency, duration)
        table.insert(self.shakes.y, camera.shake.new(amplitude, frequency, duration))
    end

    ---@param amplitude number
    ---@param frequency number
    ---@param duration number
    function self:shakeViewport(amplitude, frequency, duration)
        self:shakeViewportX(amplitude, frequency, duration)
        self:shakeViewportY(amplitude, frequency, duration)
    end

    ---@param amplitude number
    ---@param frequency number
    ---@param duration number
    function self:shakeViewportX(amplitude, frequency, duration)
        table.insert(self.viewportShakes.x, camera.shake.new(amplitude, frequency, duration))
    end

    ---@param amplitude number
    ---@param frequency number
    ---@param duration number
    function self:shakeViewportY(amplitude, frequency, duration)
        table.insert(self.viewportShakes.y, camera.shake.new(amplitude, frequency, duration))
    end

    ---@param containerW number
    ---@param containerH number
    function self:resize(containerW, containerH)
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
            love.graphics.translate(-self.x + self.offsetX, self.y + self.offsetY)
            love.graphics.rotate(self.rotation)
            love.graphics.scale(layer.scale)
            love.graphics.translate(-self.translationX * layer.speedToScaleRatio, -self.translationY * layer.speedToScaleRatio)
        end
        layer.pop = love.graphics.pop

        layerOptions = lume.merge(defaultLayerOptions, layerOptions or {})
        layer = lume.merge(layerOptions, layer)

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

    ---@param dx number
    ---@param dy number
    function self:move(dx, dy)
        self.translationX, self.translationY = self.translationX + dx, self.translationY + dy
    end

    ---@param dx number
    ---@param dy number
    function self:moveViewport(dx, dy)
        self.x, self.y = self.x + dx, self.y + dy
    end

    ---@param dt number
    ---@param x number
    ---@param smoothingFunction function|nil -- Defaults to none
    ---@param ... any -- Additional arguments for the smoothing function
    function self:followX(dt, x, smoothingFunction, ...)
        local dx, dy = (smoothingFunction or self.smoothingFunction)(dt, x - self.translationX, self.translationY, ...)
        self.translationX = self.translationX + dx
    end

    ---@param dt number
    ---@param y number
    ---@param smoothingFunction function|nil -- Defaults to none
    ---@param ... any -- Additional arguments for the smoothing function
    function self:followY(dt, y, smoothingFunction, ...)
        local dx, dy = (smoothingFunction or self.smoothingFunction)(dt, self.translationX, y - self.translationY, ...)
        self.translationY = self.translationY + dy
    end

    ---@param dt number
    ---@param x number
    ---@param y number
    ---@param smoothingFunction function|nil -- Defaults to none
    ---@param ... any -- Additional arguments for the smoothing function
    function self:follow(dt, x, y, smoothingFunction, ...)
        self:move((smoothingFunction or self.smoothingFunction)(dt, x - self.translationX, y - self.translationY, ...))
    end

    --- Locks the camera as long as the x and y values are within the min and max values
    ---@param dt number
    ---@param x number
    ---@param y number
    ---@param minX number -- The minimum x value the camera can move to
    ---@param minY number -- The minimum y value the camera can move to
    ---@param maxX number -- The maximum x value the camera can move to
    ---@param maxY number -- The maximum y value the camera can move to
    ---@param smoothingFunction function|nil -- Defaults to none
    ---@param ... any -- Additional arguments for the smoothing function
    function self:followLockScreenInside(dt, x, y, minX, minY, maxX, maxY, smoothingFunction, ...)
        local dx, dy = 0, 0

        if x < minX or x > maxX then
            dx = x - (x < minX and minX or maxX) - self.translationX
        end

        if y < minY or y > maxY then
            dy = y - (y < minY and minY or maxY) - self.translationY
        end

        self:move((smoothingFunction or self.smoothingFunction)(dt, dx, dy, ...))
    end

    --- Locks the camera when the x and y values are outside the min and max values
    ---@param dt number
    ---@param x number
    ---@param y number
    ---@param minX number -- The minimum x value the camera can move to
    ---@param minY number -- The minimum y value the camera can move to
    ---@param maxX number -- The maximum x value the camera can move to
    ---@param maxY number -- The maximum y value the camera can move to
    ---@param smoothingFunction function|nil -- Defaults to none
    ---@param ... any -- Additional arguments for the smoothing function
    function self:followLockScreenOutside(dt, x, y, minX, minY, maxX, maxY, smoothingFunction, ...)
        local dx, dy = 0, 0

        if x >= minX and x <= maxX then
            dx = x - self.translationX
        end

        if y >= minY and y <= maxY then
            dy = y - self.translationY
        end

        self:move((smoothingFunction or self.smoothingFunction)(dt, dx, dy, ...))
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