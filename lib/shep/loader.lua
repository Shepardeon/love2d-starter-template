require 'love.filesystem'
require 'love.image'
require 'love.audio'
require 'love.sound'

local utils = require('lib.shep.utils')

-- Will be set to true when we are on the loader thread
local channelPrefix = 'shepLoader_'
local isThread = ...

local function passthrough(value)
    return value
end

---@type table<string, shep.Resource>
local resources = {
    ---@class shep.Resource
    ---@field requestKey string
    ---@field resourceKey string
    ---@field constructor fun(string): any, any
    ---@field postProcess fun(any, resource: shep.ResourceRequest): any
    image = {
        requestKey = 'imagePath',
        resourceKey = 'imageData',
        constructor = function (path)
            if love.image.isCompressed(path) then
                return love.image.newCompressedData(path)
            else
                return love.image.newImageData(path)
            end
        end,
        postProcess = function (data)
            return love.graphics.newImage(data)
        end
    },
    staticSource = {
        requestKey = 'staticPath',
        resourceKey = 'staticSource',
        constructor = function (path)
            return love.audio.newSource(path, 'static')
        end,
        postProcess = passthrough
    },
    font = {
        requestKey = 'fontPath',
        resourceKey = 'fontData',
        constructor = function (path)
            return love.filesystem.newFileData(path)
        end,
        postProcess = function (data, resource)
            local _, size = unpack(resource.requestParams)
            return love.graphics.newFont(data, size)
        end
    },
    BMFont = {
        requestKey = 'fontBMPath',
        resourceKey = 'fontBMData',
        constructor = function (path)
            return love.filesystem.newFileData(path)
        end,
        postProcess = function (data, resource)
            local _, glyphsPath  = unpack(resource.requestParams)
            local glyphs = love.filesystem.newFileData(glyphsPath)
            -- Cast here is false to avoid a warning however love.Data is a valid param
            return love.graphics.newFont(glyphs --[[@as string]], data)
        end
    },
    streamSource = {
        requestKey = 'streamPath',
        resourceKey = 'streamSource',
        constructor = function (path)
            return love.audio.newSource(path, 'stream')
        end,
        postProcess = passthrough
    },
    soundData = {
        requestKey = 'soundDataPathOrDecoder',
        resourceKey = 'soundData',
        constructor = love.sound.newSoundData,
        postProcess = passthrough
    },
    imageData = {
        requestKey = 'imageDataPath',
        resourceKey = 'rawImageData',
        constructor = love.image.newImageData,
        postProcess = passthrough
    },
    compressedData = {
        requestKey = 'compressedDataPath',
        resourceKey = 'compressedData',
        constructor = love.image.newCompressedData,
        postProcess = passthrough
    },
    textData = {
        requestKey = 'rawDataPath',
        resourceKey = 'rawData',
        constructor = love.filesystem.read,
        postProcess = passthrough
    }
}

if isThread == true then
    local requestParams, resource
    local isDone = false
    local doneChannel = love.thread.getChannel(channelPrefix .. 'end')

    while not isDone do

        for _, kind in pairs(resources) do
            local loader = love.thread.getChannel(channelPrefix .. kind.requestKey)
            requestParams = loader:pop()
            if requestParams then
                resource = kind.constructor(unpack(requestParams))
                local resultChannel = love.thread.getChannel(channelPrefix .. kind.resourceKey)
                resultChannel:push(resource)
            end
        end

        isDone = doneChannel:pop()
    end
else
    ---@class shep.Loader
    ---@field pending shep.ResourceRequest[]
    ---@field private callbacks { oneLoaded: fun(kind: string, holder: table, key: string), allLoaded: fun() }
    ---@field private loadedCount number
    ---@field private resourceCount number
    ---@field private thread love.Thread
    ---@field private resourceBeingLoaded shep.ResourceRequest
    local loader = {}
    loader.pending = {}
    loader.callbacks = {}
    loader.loadedCount = 0
    loader.resourceCount = 0
    loader.thread = nil
    loader.resourceBeingLoaded = nil

    ---@private
    ---@param kind string
    ---@param holder table
    ---@param key string
    ---@param ... string
    function loader:newResource(kind, holder, key, ...)
        ---@class shep.ResourceRequest
        ---@field kind string
        ---@field holder table
        ---@field key string
        ---@field requestParams string[]
        self.pending[#self.pending + 1] = {
            kind = kind,
            holder = holder,
            key = key,
            requestParams = {...}
        }
    end

    ---@private
    function loader:getAvailableResourceFromThread()
        local data, resource
        for _, kind in pairs(resources) do
            local channel = love.thread.getChannel(channelPrefix .. kind.resourceKey)
            data = channel:pop()
            if data then
                resource = kind.postProcess(data, self.resourceBeingLoaded)
                self.resourceBeingLoaded.holder[self.resourceBeingLoaded.key] = resource
                self.loadedCount = self.loadedCount + 1
                self.callbacks.oneLoaded(self.resourceBeingLoaded.kind, self.resourceBeingLoaded.holder, self.resourceBeingLoaded.key)
                self.resourceBeingLoaded = nil
            end
        end
    end

    ---@private
    function loader:requestResourceToThread()
        self.resourceBeingLoaded = utils.arrayPop(self.pending)
        local requestKey = resources[self.resourceBeingLoaded.kind].requestKey
        local channel = love.thread.getChannel(channelPrefix .. requestKey)
        channel:push(self.resourceBeingLoaded.requestParams)
    end

    ---@private
    function loader:endThreadIfAllLoader()
        if not self.resourceBeingLoaded and #self.pending == 0 then
            love.thread.getChannel(channelPrefix .. 'end'):push(true)
            self.callbacks.allLoaded()
        end
    end

    ---@param holder table
    ---@param key string
    ---@param path string
    function loader:newImage(holder, key, path)
        self:newResource('image', holder, key, path)
    end

    ---@param holder table
    ---@param key string
    ---@param path string
    ---@param sourceType 'static' | 'stream'
    function loader:newSource(holder, key, path, sourceType)
        local kind = sourceType == 'stream' and 'streamSource' or 'staticSource'
        self:newResource(kind, holder, key, path)
    end

    ---@param holder table
    ---@param key string
    ---@param path string
    ---@param size number
    function loader:newFont(holder, key, path, size)
        self:newResource('font', holder, key, path, size)
    end

    ---@param holder table
    ---@param key string
    ---@param path string
    ---@param glyphsPath string
    function loader:newBMFont(holder, key, path, glyphsPath)
        self:newResource('BMFont', holder, key, path, glyphsPath)
    end

    ---@param holder table
    ---@param key string
    ---@param pathOrDecoder string
    function loader:newSoundData(holder, key, pathOrDecoder)
        self:newResource('soundData', holder, key, pathOrDecoder)
    end

    ---@param holder table
    ---@param key string
    ---@param path string
    function loader:newImageData(holder, key, path)
        self:newResource('imageData', holder, key, path)
    end

    function loader:newCompressedData(holder, key, path)
        self:newResource('compressedData', holder, key, path)
    end

    function loader:newRawData(holder, key, path)
        self:newResource('textData', holder, key, path)
    end

    ---@param oneLoadedCb fun(kind: string, holder: table, key: string)|nil
    ---@param allLoadedCb fun()|nil
    function loader:start(oneLoadedCb, allLoadedCb)
        self.callbacks.oneLoaded = oneLoadedCb or function() end
        self.callbacks.allLoaded = allLoadedCb or function() end

        -- Here isThread will be the file current path
        local pathToFile = (isThread):gsub('%.', '/') .. '.lua'

        self.thread = love.thread.newThread(pathToFile)
        self.loadedCount = 0
        self.resourceCount = #self.pending
        self.thread:start(true)
    end

    function loader:update()
        if self.thread then
            if self.thread:isRunning() then
                if self.resourceBeingLoaded then
                    self:getAvailableResourceFromThread()
                elseif #self.pending > 0 then
                    self:requestResourceToThread()
                else
                    self:endThreadIfAllLoader()
                    self.thread = nil
                end
            else
                local errorMessage = self.thread:getError()
                if errorMessage then
                    error(errorMessage)
                end
            end
        end
    end

    return loader
end