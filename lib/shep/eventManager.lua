local eventManager = {}
local lume = require('lib.lume')

---@return EventManager
function eventManager.new()
    ---@class EventManager
    ---@field private events table<string, table<function>>
    local self = {}
    self.events = {}

    ---@param eventName string
    function self:addEvent(eventName)
        if (self.events[eventName] ~= nil) then
            error("Event already exists with name " .. eventName, 2)
        end

        self.events[eventName] = {}
    end

    ---@param eventName string
    function self:removeEvent(eventName)
        self.events[eventName] = nil
    end

    ---@param eventName string
    ---@param callback function
    ---@param shouldReplace boolean|nil
    function self:hook(eventName, callback, shouldReplace)
        if (self.events[eventName] == nil) then
            error("Event not found with name " .. eventName, 2)
        end

        if (lume.find(self.events[eventName], callback) ~= nil) then
            error("Given callback already exists for event " .. eventName, 2)
        end

        shouldReplace = shouldReplace or false

        if shouldReplace then
            self.events[eventName] = { callback }
        else
            table.insert(self.events[eventName], callback)
        end
    end

    ---@param eventName string
    ---@param callback function
    function self:unhook(eventName, callback)
        if (self.events[eventName] == nil) then
            error("Event not found with name " .. eventName, 2)
        end

        lume.remove(self.events[eventName], callback)
    end

    --- Clears all events hooks or a specific event if given a name
    ---@param eventName string|nil
    function self:clear(eventName)
        if eventName == nil then
            self.events = {}
        else
            self.events[eventName] = {}
        end
    end

    ---@param eventName string
    ---@param ... any
    function self:fire(eventName, ...)
        if (self.events[eventName] == nil) then
            error("Event not found with name " .. eventName, 2)
        end

        for _, callback in ipairs(self.events[eventName]) do
            callback(...)
        end
    end

    return self
end

return eventManager