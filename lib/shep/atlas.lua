local atlas = {}
local lume = require('lib.lume')

---@class shep.AtlasOptions
local defaultOptions = {
    ---@type number|nil
    tileWidth = 32,
    ---@type number|nil
    tileHeight = 32,
    ---@type number|nil
    spacingX = 0, -- Space between sprites in X
    ---@type number|nil
    spacingY = 0, -- Space between sprites in Y
    ---@type number|nil
    paddingX = 0, -- Global image padding in X
    ---@type number|nil
    paddingY = 0, -- Global image padding in Y
    ---@type number|nil -- Maximum number of sprites the attached sprite batch can hold, autogrows if exceeded in LÖVE ^11.0
    batchLimit = 50
}

---@param image string|love.Image
---@param options shep.AtlasOptions|nil
function atlas.new(image, options)
    ---@class shep.Atlas
    ---@field private image love.Image
    ---@field private sourceImage table
    ---@field private quads table<string, love.Quad>
    ---@field private options shep.AtlasOptions
    ---@field private quadsInBatch table<number, string>
    local self = {}
    self.quads = {}
    self.quadsInBatch = {}
    self.options = lume.merge(defaultOptions, options or {})

    if type(image) == 'string' then
        self.image = love.graphics.newImage(image)
    else
        self.image = image
    end

    self.sourceImage = {
        width = self.image:getWidth(),
        height = self.image:getHeight()
    }

    self.spriteBatch = love.graphics.newSpriteBatch(self.image, self.options.batchLimit)

    --- Registers a quad in the atlas
    ---@param name string -- The name of the quad
    ---@param posX number -- The row position (will be multiplied internally by the tileWidth)
    ---@param posY number -- The column position (will be multiplied internally by the tileHeight)
    ---@param mulW number|nil -- Multiplier for the tileWidth (defaults to 1)
    ---@param mulH number|nil -- Multiplier for the tileHeight (defaults to 1)
    function self:addQuad(name, posX, posY, mulW, mulH)
        if self.quads[name] then
            error("Quad with name '" .. name .. "' already exists", 2)
        end

        local spacingX = self.options.spacingX * posX + self.options.paddingX
        local spacingY = self.options.spacingY * posY + self.options.paddingY

        self.quads[name] = love.graphics.newQuad(
            posX * self.options.tileWidth + spacingX,
            posY * self.options.tileHeight + spacingY,
            (mulW or 1) * self.options.tileWidth,
            (mulH or 1) * self.options.tileHeight,
            self.sourceImage.width,
            self.sourceImage.height
        )
    end

    --- Registers a quad in the atlas without any calculations
    --- 
    --- Useful for when you have a sprite sheet with different sized sprites
    ---@param name string -- The name of the quad
    ---@param x number -- The row position
    ---@param y number -- The column position
    ---@param w number -- The width of the quad
    ---@param h number -- The height of the quad
    function self:addQuadRaw(name, x, y, w, h)
        if self.quads[name] then
            error("Quad with name '" .. name .. "' already exists", 2)
        end

        self.quads[name] = love.graphics.newQuad(
            x,
            y,
            w,
            h,
            self.sourceImage.width,
            self.sourceImage.height
        )
    end

    --- Draws only a quad from the atlas
    ---@param name string
    ---@param x number
    ---@param y number
    ---@param r number|nil
    ---@param sx number|nil
    ---@param sy number|nil
    ---@param ox number|nil
    ---@param oy number|nil
    ---@param kx number|nil
    ---@param ky number|nil
    function self:drawQuad(name, x, y, r, sx, sy, ox, oy, kx, ky)
        if not self.quads[name] then
            error("Quad with name '" .. name .. "' does not exist", 2)
        end

        love.graphics.draw(self.image, self.quads[name], x, y, r, sx, sy, ox, oy, kx, ky)
    end

        ---@param name string
        ---@param x number
        ---@param y number
        ---@param r number|nil
        ---@param sx number|nil
        ---@param sy number|nil
        ---@param ox number|nil
        ---@param oy number|nil
        ---@param kx number|nil
        ---@param ky number|nil
        ---@return number -- The index of the quad in the sprite batch
    function self:addToBatch(name, x, y, r, sx, sy, ox, oy, kx, ky)
        if not self.quads[name] then
            error("Quad with name '" .. name .. "' does not exist", 2)
        end

        local idx = self.spriteBatch:add(self.quads[name], x, y, r, sx, sy, ox, oy, kx, ky)
        self.quadsInBatch[idx] = name

        return idx
    end

    ---@param idx number -- The index of the quad in the sprite batch
    ---@param name string
    ---@param x number
    ---@param y number
    ---@param r number|nil
    ---@param sx number|nil
    ---@param sy number|nil
    ---@param ox number|nil
    ---@param oy number|nil
    ---@param kx number|nil
    ---@param ky number|nil
    function self:updateBatch(idx, name, x, y, r, sx, sy, ox, oy, kx, ky)
        if not self.quadsInBatch[idx] then
            error("Nothing to update in the batch with id " .. idx, 2)
        end

        -- Switch the quad only if it actually changed, otherwise just update its position
        if not self.quadsInBatch[idx] == name then
            self.spriteBatch:set(idx, x, y, r, sx, sy, ox, oy, kx, ky)
        else
            self.spriteBatch:set(idx, self.quads[name], x, y, r, sx, sy, ox, oy, kx, ky)
        end

    end

    ---@param idx number -- The index of the quad in the sprite batch
    function self:removeFromBatch(idx)
        if not self.quadsInBatch[idx] then
            error("Nothing to update in the batch with id " .. idx, 2)
        end

        -- Hack to fakely remove something from the spritebatch without
        -- actually removing it, so we don't have to rebuild the full
        -- spritebatch
        self.spriteBatch:set(idx, 0, 0, 0, 0, 0)
    end

    function self:clearBatch()
        self.spriteBatch:clear()
    end

    --- Draws the content of the sprite batch
    function self:draw()
        love.graphics.draw(self.spriteBatch)
    end

    return self
end

return atlas