local lume = require('lib.lume')

---@class shep.EventManager
---@field private events table<string, table<function>>
local EventManager = Object:extend()

--- Creates a new EventManager instance.
function EventManager:new()
    self.events = {}
end

--- Adds a new event.
---@param eventName string
function EventManager:addEvent(eventName)
    if (self.events[eventName] ~= nil) then
        error("Event already exists with name " .. eventName, 2)
    end

    self.events[eventName] = {}
end

--- Removes an event.
---@param eventName string
function EventManager:removeEvent(eventName)
    self.events[eventName] = nil
end

--- Hooks a callback to an event.
---@param eventName string
---@param callback function
---@param shouldReplace boolean|nil
function EventManager:hook(eventName, callback, shouldReplace)
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

--- Unhooks a callback from an event.
---@param eventName string
---@param callback function
function EventManager:unhook(eventName, callback)
    if (self.events[eventName] == nil) then
        error("Event not found with name " .. eventName, 2)
    end

    lume.remove(self.events[eventName], callback)
end

--- Clears all events hooks or a specific event if given a name.
---@param eventName string|nil
function EventManager:clear(eventName)
    if eventName == nil then
        self.events = {}
    else
        self.events[eventName] = {}
    end
end

--- Fires an event.
---@param eventName string
---@param ... any
function EventManager:fire(eventName, ...)
    if (self.events[eventName] == nil) then
        error("Event not found with name " .. eventName, 2)
    end

    for _, callback in ipairs(self.events[eventName]) do
        callback(...)
    end
end

return EventManager