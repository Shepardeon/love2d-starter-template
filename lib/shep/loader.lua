local channelPrefix = 'shepLoader_'

-- Will be set to true when we are on the loader thread
local isThread = ...

if isThread == true then
    --TODO: Do thread work
else
    ---@class shep.Loader
    ---@field private pending table
    ---@field private callbacks { oneLoaded: fun(), allLoaded: fun() }
    ---@field private loadedCount number
    ---@field private resourceCount number
    ---@field private thread love.Thread
    local loader = {}
    loader.pending = {}
    loader.callbacks = {}
    loader.loadedCount = 0
    loader.resourceCount = 0
    loader.thread = nil

    ---@param oneLoadedCb fun()
    ---@param allLoadedCb fun()
    function loader:start(oneLoadedCb, allLoadedCb)
        self.callbacks.oneLoaded = oneLoadedCb
        self.callbacks.allLoaded = allLoadedCb

        -- Here isThread will be the file current path
        local pathToFile = (isThread):gsub("%.", "/") .. ".lua"

        self.thread = love.thread.newThread(pathToFile)
        self.loadedCount = 0
        self.resourceCount = #self.pending
        self.thread:start(true)
    end

    function loader:update()
        --TODO: Implement
    end

    return loader
end