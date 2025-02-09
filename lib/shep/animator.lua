local Atlas = require("lib.shep.atlas")
local utils = require("lib.shep.utils")

---@class shep.Animator
---@field private atlas shep.Atlas
---@field private animations table<string, shep.Animation>
---@field private currentAnimation shep.Animation|nil
---@field private useSpriteBatch boolean
---@field private batchIndex number|nil
local Animator = Object:extend()

---@param atlasOptions shep.AtlasOptions|nil
---@param image string|love.Image|nil
---@param sharedAtlas shep.Atlas|nil
function Animator:new(sharedAtlas, image, atlasOptions)
    if not sharedAtlas and not image then
        error("Either sharedAtlas or image must be provided", 2)
    end

    self.atlas = sharedAtlas or Atlas(image --[[@as string|love.Image]], atlasOptions)
    self.animations = {}
    self.currentAnimation = nil
    self.useSpriteBatch = sharedAtlas and true or false
    self.batchIndex = nil
end

---@param name string
---@param ... number|number[]
---@return string[]
function Animator:getFrames(name, ...)
    local frames = ...

    if not (type(frames) == 'table') then
        frames = {...}
    end

    if not (#frames % 2 == 0) then
        error("Number of arguments must be even", 2)
    end

    local groupedFrames = {}
    for i = 1, #frames, 2 do
        table.insert(groupedFrames, {frames[i], frames[i + 1]})
    end

    local finalFrames = {}
    for i = 1, #groupedFrames do
        local frame = groupedFrames[i]
        local col = frame[1]
        local row = frame[2]

        if type(col) ~= 'number' or type(row) ~= 'number' then
            error("Frame coordinates must be numbers", 2)
        end

        self.atlas:addQuad(name .. i, col, row)
        table.insert(finalFrames, name .. i)
    end

    return finalFrames
end

---@param name string
---@param frames string[]
---@param durations number|number[]
---@param onLoop fun(anim: shep.Animation, loops: number)|string|nil -- If passed 'pauseOnLoop', the animation will pause on loop
function Animator:addAnimation(name, frames, durations, onLoop)
    if self.animations[name] then
        error("Animation with name '" .. name .. "' already exists", 2)
    end

    if type(durations) == 'number' then
        durations = utils.repeatTable(durations, #frames)
    else
        if #durations ~= #frames then
            error("Number of durations must match number of frames", 2)
        end
    end

    ---@param anim shep.Animation
    ---@param loops number
    local function onLoopPause(anim, loops)
        anim.paused = true
    end

    if onLoop == 'pauseOnLoop' then
        onLoop = onLoopPause
    end

    ---@class shep.Animation
    ---@field frames string[]
    ---@field durations number[]
    ---@field onLoop fun(anim: shep.Animation, loops: number)|nil
    ---@field currentFrame string
    ---@field currentTime number
    ---@field paused boolean
    self.animations[name] = {
        frames = frames,
        durations = durations,
        onLoop = type(onLoop) == 'function' and onLoop or nil,
        loops = 0,
        currentFrameIndex = 1,
        currentFrame = frames[1],
        currentTime = 0,
        paused = false,
    }
end

---@param name string
function Animator:setAnimation(name)
    if not self.animations[name] then
        error("Animation with name '" .. name .. "' does not exist", 2)
    end

    self.currentAnimation = self.animations[name]
    self.currentAnimation.currentFrame = self.currentAnimation.frames[1]
    self.currentAnimation.currentTime = 0
    self.currentAnimation.loops = 0
    self.currentAnimation.paused = false
end

---@param dt number
function Animator:update(dt)
    if self.currentAnimation and not self.currentAnimation.paused then
        self.currentAnimation.currentTime = self.currentAnimation.currentTime + dt

        if self.currentAnimation.currentTime >= self.currentAnimation.durations[self.currentAnimation.currentFrameIndex] then
            self.currentAnimation.currentTime = 0
            self.currentAnimation.currentFrameIndex = self.currentAnimation.currentFrameIndex + 1

            if self.currentAnimation.currentFrameIndex > #self.currentAnimation.frames then
                self.currentAnimation.currentFrameIndex = 1

                if self.currentAnimation.onLoop then
                    self.currentAnimation.onLoop(self.currentAnimation, self.currentAnimation.loops)
                end
            end

            self.currentAnimation.currentFrame = self.currentAnimation.frames[self.currentAnimation.currentFrameIndex]
        end
    end
end

---@param x number
---@param y number
---@param r number|nil
---@param sx number|nil
---@param sy number|nil
---@param ox number|nil
---@param oy number|nil
---@param kx number|nil
---@param ky number|nil
function Animator:draw(x, y, r, sx, sy, ox, oy, kx, ky)
    if self.currentAnimation then
        if self.useSpriteBatch then
            if self.batchIndex == nil then
                self.batchIndex = self.atlas:addToBatch(self.currentAnimation.frames[self.currentAnimation.currentFrameIndex],
                x, y, r, sx, sy, ox, oy, kx, ky)
            else
                self.atlas:updateBatch(self.batchIndex,
                    self.currentAnimation.frames[self.currentAnimation.currentFrameIndex],
                    x, y, r, sx, sy, ox, oy, kx, ky)
            end
            -- Shared atlas must be drawn by the final user
        else
            self.atlas:drawQuad(self.currentAnimation.frames[self.currentAnimation.currentFrameIndex],
                x, y, r, sx, sy, ox, oy, kx, ky)
        end
    end
end

return Animator