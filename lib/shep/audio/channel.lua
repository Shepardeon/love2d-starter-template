---@class shep.audio.Channel
---@field private volume number
---@field private sources table<string, love.Source>
local Channel = Object:extend()

---@param volume number|nil
function Channel:new(volume)
    self.volume = volume or 1
    self.sources = {}
end

---@param volume number
function Channel:setVolume(volume)
    self.volume = volume
    self:setAllVolumes()
end

function Channel:mute()
    self:setVolume(0)
end

---@param key string
---@param source love.Source
function Channel:add(key, source)
    source:setVolume(self.volume)
    self.sources[key] = source
end

function Channel:play(key)
    local source = self.sources[key]
    if source then
        source:play()
    end
end

function Channel:stop(key)
    local source = self.sources[key]
    if source then
        source:stop()
    end
end

---@private
function Channel:setAllVolumes()
    for _, value in ipairs(self.sources) do
        self.sources:setVolume(self.volume)
    end
end
