local lume = require('lib.lume')
local utils = require('lib.shep.utils')

local min = math.min

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
--- @field private origWidth number
--- @field private height number
--- @field private translationX number
--- @field private translationY number
--- @field private offsetX number
--- @field private offsetY number
--- @field private scale number
--- @field private rotation number
--- @field private shakes { x: table<shep.Shake>, y: table<shep.Shake> }
--- @field private viewportShakes { x: table<shep.Shake>, y: table<shep.Shake> }
local Camera = Object:extend()

Camera.smoothingFunctions = {
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
    smoothingFunction = Camera.smoothingFunctions.none()
}

---@class shep.CameraLayerOptions
local defaultLayerOptions = {
    ---@type number|nil -- Controls how much the layer is translated based on the layer's scale
    speedToScaleRatio = 1,
    ---@type love.StackType|nil
    mode = 'transform'
}

--- Creates a new Camera instance.
---@param width number
---@param height number
---@param options shep.CameraOptions|nil
function Camera:new(width, height, options)
    self.layers = {}
    self.x = 0
    self.y = 0
    self.width = width
    self.origWidth = width
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
    self.maintainAspectRatio = options.maintainAspectRatio
    self.center = options.center
    self.aspectRatioScale = options.aspectRatioScale
    self.mode = options.mode
    self.smoothingFunction = options.smoothingFunction

    self.translate = self.increaseTranslation
    self.rotate = self.increaseRotation

    Camera.addLayer(self, "main", 1)

    if self.center then
        local containerW, containerH = Camera.getContainerDimensions(self)
        self.offsetX = self.offsetX + (containerW - self.width) / 2
        self.offsetY = self.offsetY + (containerH - self.height) / 2
    end

    return self
end

---@private
---@param shakes table<shep.Shake>
---@return number
function Camera:sumShakes(shakes)
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

--- Updates the camera.
function Camera:update()
    local xShakeAmount, yShakeAmount = self:sumShakes(self.shakes.x), self:sumShakes(self.shakes.y)
    local xViewportShakeAmount, yViewportShakeAmount = self:sumShakes(self.viewportShakes.x), self:sumShakes(self.viewportShakes.y)

    self:move(xShakeAmount, yShakeAmount)
    self:moveViewport(xViewportShakeAmount, yViewportShakeAmount)
end

--- Shakes the camera.
---@param amplitude number
---@param frequency number
---@param duration number
function Camera:shake(amplitude, frequency, duration)
    self:shakeX(amplitude, frequency, duration)
    self:shakeY(amplitude, frequency, duration)
end

--- Shakes the camera on the X axis.
---@param amplitude number
---@param frequency number
---@param duration number
function Camera:shakeX(amplitude, frequency, duration)
    table.insert(self.shakes.x, Camera.Shake(amplitude, frequency, duration))
end

--- Shakes the camera on the Y axis.
---@param amplitude number
---@param frequency number
---@param duration number
function Camera:shakeY(amplitude, frequency, duration)
    table.insert(self.shakes.y, Camera.Shake(amplitude, frequency, duration))
end

--- Shakes the camera viewport.
---@param amplitude number
---@param frequency number
---@param duration number
function Camera:shakeViewport(amplitude, frequency, duration)
    self:shakeViewportX(amplitude, frequency, duration)
    self:shakeViewportY(amplitude, frequency, duration)
end

--- Shakes the camera viewport on the X axis.
---@param amplitude number
---@param frequency number
---@param duration number
function Camera:shakeViewportX(amplitude, frequency, duration)
    table.insert(self.viewportShakes.x, Camera.Shake(amplitude, frequency, duration))
end

--- Shakes the camera viewport on the Y axis.
---@param amplitude number
---@param frequency number
---@param duration number
function Camera:shakeViewportY(amplitude, frequency, duration)
    table.insert(self.viewportShakes.y, Camera.Shake(amplitude, frequency, duration))
end

--- Resizes the camera.
---@param containerW number
---@param containerH number
function Camera:resize(containerW, containerH)
    local scaleW, scaleH = containerW / self.width, containerH / self.height

    if self.maintainAspectRatio then
        containerW, containerH = containerW - 2 * self.x, containerH - 2 * self.y
        local scale = min(scaleW, scaleH)
        self.width, self.height = scale * self.width, scale * self.height
    else
        self.width, self.height = scaleW * self.width, scaleH * self.height
    end

    self.aspectRatioScale = self.width / self.origWidth
    self.offsetX, self.offsetY = self.width / 2, self.height / 2

    if self.center then
        self.offsetX = self.offsetX + (containerW - self.width) / 2
        self.offsetY = self.offsetY + (containerH - self.height) / 2
    end
end

--- Gets the container dimensions.
---@return number, number
function Camera:getContainerDimensions()
    return love.graphics.getDimensions()
end

--- Adds a layer to the camera.
---@param name string
---@param scale number
---@param layerOptions shep.CameraLayerOptions|nil
---@return shep.CameraLayer
function Camera:addLayer(name, scale, layerOptions)
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

--- Gets a layer from the camera.
---@param name string
---@return shep.CameraLayer
function Camera:getLayer(name)
    if self.layers[name] == nil then
        error("Layer not found with name " .. name, 2)
    end

    return self.layers[name]
end

--- Pushes the camera state.
---@param layer string|nil
function Camera:push(layer)
    self:getLayer(layer or "main"):push()
end

--- Pops the camera state.
---@param layer string|nil
function Camera:pop(layer)
    self:getLayer(layer or "main"):pop()
end

--- Gets the world coordinates from screen coordinates.
---@param x number
---@param y number
---@param layer string|nil
---@return number, number
function Camera:getWorldCoordinates(x, y, layer)
    local currentLayer = self:getLayer(layer or "main")
    local scaleFactor = self.scale * self.aspectRatioScale * currentLayer.scale
    x, y = x - self.x - self.offsetX, y - self.y - self.offsetY
    x, y = utils.rotateAboutPoint(x, y, 0, 0, -self.rotation)
    x, y = x / scaleFactor, y / scaleFactor
    return x + self.translationX * currentLayer.speedToScaleRatio, y + self.translationY * currentLayer.speedToScaleRatio
end

--- Gets the screen coordinates from world coordinates.
---@param x number
---@param y number
---@param layer string|nil
---@return number, number
function Camera:getScreenCoordinates(x, y, layer)
    local currentLayer = self:getLayer(layer or "main")
    local scaleFactor = self.scale * self.aspectRatioScale * currentLayer.scale
    x, y = x - self.translationX / currentLayer.speedToScaleRatio, y - self.translationY / currentLayer.speedToScaleRatio
    x, y = x * scaleFactor, y * scaleFactor
    x, y = utils.rotateAboutPoint(x, y, 0, 0, self.rotation)
    return x + self.x + self.offsetX, y + self.y + self.offsetY
end

--- Gets the mouse world coordinates.
---@param layer string|nil
---@return number, number
function Camera:getMouseWorldCoordinates(layer)
    local x, y = love.mouse.getPosition()
    return self:getWorldCoordinates(x, y, layer)
end

--- Moves the camera.
---@param dx number
---@param dy number
function Camera:move(dx, dy)
    self.translationX, self.translationY = self.translationX + dx, self.translationY + dy
end

--- Moves the camera viewport.
---@param dx number
---@param dy number
function Camera:moveViewport(dx, dy)
    self.x, self.y = self.x + dx, self.y + dy
end

--- Follows a target on the X axis.
---@param dt number
---@param x number
---@param smoothingFunction function|nil -- Defaults to none
---@param ... any -- Additional arguments for the smoothing function
function Camera:followX(dt, x, smoothingFunction, ...)
    local dx, dy = (smoothingFunction or self.smoothingFunction)(dt, x - self.translationX, self.translationY, ...)
    self.translationX = self.translationX + dx
end

--- Follows a target on the Y axis.
---@param dt number
---@param y number
---@param smoothingFunction function|nil -- Defaults to none
---@param ... any -- Additional arguments for the smoothing function
function Camera:followY(dt, y, smoothingFunction, ...)
    local dx, dy = (smoothingFunction or self.smoothingFunction)(dt, self.translationX, y - self.translationY, ...)
    self.translationY = self.translationY + dy
end

--- Follows a target.
---@param dt number
---@param x number
---@param y number
---@param smoothingFunction function|nil -- Defaults to none
---@param ... any -- Additional arguments for the smoothing function
function Camera:follow(dt, x, y, smoothingFunction, ...)
    self:move((smoothingFunction or self.smoothingFunction)(dt, x - self.translationX, y - self.translationY, ...))
end

--- Locks the camera as long as the x and y values are within the min and max values.
---@param dt number
---@param x number
---@param y number
---@param minX number -- The minimum x value the camera can move to
---@param minY number -- The minimum y value the camera can move to
---@param maxX number -- The maximum x value the camera can move to
---@param maxY number -- The maximum y value the camera can move to
---@param smoothingFunction function|nil -- Defaults to none
---@param ... any -- Additional arguments for the smoothing function
function Camera:followLockScreenInside(dt, x, y, minX, minY, maxX, maxY, smoothingFunction, ...)
    local dx, dy = 0, 0

    if x < minX or x > maxX then
        dx = x - (x < minX and minX or maxX) - self.translationX
    end

    if y < minY or y > maxY then
        dy = y - (y < minY and minY or maxY) - self.translationY
    end

    self:move((smoothingFunction or self.smoothingFunction)(dt, dx, dy, ...))
end

--- Locks the camera when the x and y values are outside the min and max values.
---@param dt number
---@param x number
---@param y number
---@param minX number -- The minimum x value the camera can move to
---@param minY number -- The minimum y value the camera can move to
---@param maxX number -- The maximum x value the camera can move to
---@param maxY number -- The maximum y value the camera can move to
---@param smoothingFunction function|nil -- Defaults to none
---@param ... any -- Additional arguments for the smoothing function
function Camera:followLockScreenOutside(dt, x, y, minX, minY, maxX, maxY, smoothingFunction, ...)
    local dx, dy = 0, 0

    if x >= minX and x <= maxX then
        dx = x - self.translationX
    end

    if y >= minY and y <= maxY then
        dy = y - self.translationY
    end

    self:move((smoothingFunction or self.smoothingFunction)(dt, dx, dy, ...))
end

--- Increases the camera scale to a point.
---@param ds number
---@param wx number|nil
---@param wy number|nil
function Camera:increaseScaleToPoint(ds, wx, wy)
    if not wx then
        wx, wy = self:getMouseWorldCoordinates()
    end

    local tx, ty = self.translationX, self.translationY
    self:increaseScale(ds)
    self:increaseTranslation((wx - tx) * ds / self.scale, (wy - ty) * ds / self.scale)
end

--- Scales the camera to a point.
---@param ds number
---@param wx number|nil
---@param wy number|nil
function Camera:scaleToPoint(ds, wx, wy)
    if not wx then
        wx, wy = self:getMouseWorldCoordinates()
    end

    local tx, ty = self.translationX, self.translationY
    self:scaleBy(ds)
    self:increaseTranslation((wx - tx) * (1 - 1 / ds), (wy - ty) * (1 - 1 / ds))
end

--- Increases the camera translation.
---@param dx number
---@param dy number
function Camera:increaseTranslation(dx, dy)
    self.translationX, self.translationY = self.translationX + dx, self.translationY + dy
end

--- Increases the camera rotation.
---@param dr number
function Camera:increaseRotation(dr)
    self.rotation = self.rotation + dr
end

--- Increases the camera scale.
---@param ds number
function Camera:increaseScale(ds)
    self.scale = self.scale + ds
end

--- Scales the camera by a factor.
---@param ds number
function Camera:scaleBy(ds)
    self.scale = self.scale * ds
end

--#region Shake
--- @class shep.Shake
--- @field private amplitude number
--- @field private frequency number
--- @field private duration number
--- @field private samples table<number>
--- @field private startTime number
--- @field private t number
--- @field private shaking boolean
Camera.Shake = Object:extend()

---@param amplitude number
---@param frequency number
---@param duration number
function Camera.Shake:new(amplitude, frequency, duration)
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
end

function Camera.Shake:update()
    self.t = love.timer.getTime()*1000 - self.startTime
    if self.t > self.duration then
        self.shaking = false
    end
end

---@param t number|nil
function Camera.Shake:getAmplitude(t)
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
function Camera.Shake:noise(sample)
    return sample < #self.samples and self.samples[sample] or 0
end

---@private
---@param t number
function Camera.Shake:decay(t)
    return t <= self.duration and (self.duration - t) / self.duration or 0
end
--#endregion

return Camera