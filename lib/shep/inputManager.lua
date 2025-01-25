local inputManager = {}
local lume = require('lib.lume')

inputManager.all_keys = {
    " ", "return", "escape", "backspace", "tab", "space", "!", "\"", "#", "$", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4",
    "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "[", "\\", "]", "^", "", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "capslock", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "printscreen",
    "scrolllock", "pause", "insert", "home", "pageup", "delete", "end", "pagedown", "right", "left", "down", "up", "numlock", "kp/", "kp*", "kp-", "kp+", "kpenter",
    "kp0", "kp1", "kp2", "kp3", "kp4", "kp5", "kp6", "kp7", "kp8", "kp9", "kp.", "kp,", "kp=", "application", "power", "f13", "f14", "f15", "f16", "f17", "f18", "f19",
    "f20", "f21", "f22", "f23", "f24", "execute", "help", "menu", "select", "stop", "again", "undo", "cut", "copy", "paste", "find", "mute", "volumeup", "volumedown",
    "alterase", "sysreq", "cancel", "clear", "prior", "return2", "separator", "out", "oper", "clearagain", "thsousandsseparator", "decimalseparator", "currencyunit",
    "currencysubunit", "lctrl", "lshift", "lalt", "lgui", "rctrl", "rshift", "ralt", "rgui", "mode", "audionext", "audioprev", "audiostop", "audioplay", "audiomute",
    "mediaselect", "brightnessdown", "brightnessup", "displayswitch", "kbdillumtoggle", "kbdillumdown", "kbdillumup", "eject", "sleep", "mouse1", "mouse2", "mouse3",
    "mouse4", "mouse5", "wheelup", "wheeldown", "fdown", "fup", "fleft", "fright", "back", "guide", "start", "leftstick", "rightstick", "l1", "r1", "l2", "r2", "dpup",
    "dpdown", "dpleft", "dpright", "leftx", "lefty", "rightx", "righty",
}

---@return InputManager
function inputManager.new()
    ---@class InputManager
    ---@field private state table<string, boolean>
    ---@field private prevState table<string, boolean>
    ---@field private repeatState table<string, {pressed: boolean, pressed_time: number, delay: number, interval: number, delayStage: boolean}>
    ---@field private binds table<string, table<string>>
    ---@field private functions table<string, fun()>
    ---@field private joystick table<love.Joystick>
    ---@field private sequences any
    local self = {}
    self.state = {}
    self.prevState = {}
    self.repeatState = {}
    self.binds = {}
    self.functions = {}
    self.sequences = {}
    self.joystick = love.joystick.getJoysticks()

    local callbacks = { "keypressed", "keyreleased", "mousepressed", "mousereleased", "gamepadpressed", "gamepadreleased", "gamepadaxis", "wheelmoved" }
    local oldFunctions = {}
    local emptyFn = function() end

    for _, callback in ipairs(callbacks) do
        oldFunctions[callback] = love[callback] or emptyFn
        love[callback] = function(...)
            oldFunctions[callback](...)
            self[callback](self, ...)
        end
    end

    --- Binds a key to an action
    ---@param key string
    ---@param action function|string
    function self:bind(key, action)
        if type(action) == "function" then
            self.functions[key] = action
            return
        end

        if not self.binds[action] then
            self.binds[action] = {}
        end

        table.insert(self.binds[action], key)
    end

    --- Returns true when action was just pressed
    ---@param action string|nil
    function self:pressed(action)
        if action then
            for _, key in ipairs(self.binds[action]) do
                if self.state[key] and not self.prevState[key] then
                    return true
                end
            end
        else
            for _, key in ipairs(inputManager.all_keys) do
                if self.state[key] and not self.prevState[key] then
                    if self.functions[key] then
                        self.functions[key]()
                    end
                end
            end
        end
    end

    --- Returns true when action was just released
    ---@param action string
    function self:released(action)
        for _, key in ipairs(self.binds[action]) do
            if not self.state[key] and self.prevState[key] then
                return true
            end
        end
    end

    --- Checks for a sequence of inputs to start an actions
    ---@param ... string
    function self:sequence(...)
        local sequence = {...}
        if #sequence <= 1 then error("Sequence must have at least 2 actions, use :pressed when checking for one action") end
        if type(sequence[#sequence]) ~= "string" then
            error("Last argument must be an action")
        end
        if #sequence % 2 == 0 then
            error("Sequence must have an odd number of arguments")
        end

        local sequenceKey = ''
        for _, seq in ipairs(sequence) do
            sequenceKey = sequenceKey .. tostring(seq)
        end

        if not self.sequences[sequenceKey] then
            self.sequences[sequenceKey] = { sequence = sequence, currentIndex = 1 }
        else
            if self.sequences[sequenceKey].currentIndex == 1 then
                local action = self.sequences[sequenceKey].sequence[self.sequences[sequenceKey].currentIndex]
                for _, key in ipairs(self.binds[action]) do
                    if self.state[key] and not self.prevState[key] then
                        self.sequences[sequenceKey].lastPressed = love.timer.getTime()
                        self.sequences[sequenceKey].currentIndex = self.sequences[sequenceKey].currentIndex + 1
                    end
                end
            else
                local delay = self.sequences[sequenceKey].sequence[self.sequences[sequenceKey].currentIndex]
                local action = self.sequences[sequenceKey].sequence[self.sequences[sequenceKey].currentIndex + 1]

                if (love.timer.getTime() - self.sequences[sequenceKey].lastPressed) > delay then
                    self.sequences[sequenceKey] = nil
                end

                for _, key in ipairs(self.binds[action]) do
                    if self.state[key] and not self.prevState[key] then
                        if (love.timer.getTime() - self.sequences[sequenceKey].lastPressed) <= delay then
                            if self.sequences[sequenceKey].currentIndex+1 == #self.sequences[sequenceKey].sequence then
                                self.sequences[sequenceKey] = nil
                                return true
                            else
                                self.sequences[sequenceKey].last_pressed = love.timer.getTime()
                            self.sequences[sequenceKey].current_index = self.sequences[sequenceKey].current_index + 2
                            end
                        else
                            self.sequences[sequenceKey] = nil
                        end
                    end
                end
            end
        end
    end

    local keyToButton = {mouse1 = '1', mouse2 = '2', mouse3 = '3', mouse4 = '4', mouse5 = '5'} 
    local gamepadToButton = {fdown = 'a', fup = 'y', fleft = 'x', fright = 'b', back = 'back', guide = 'guide', start = 'start',
                            leftstick = 'leftstick', rightstick = 'rightstick', l1 = 'leftshoulder', r1 = 'rightshoulder',
                            dpup = 'dpup', dpdown = 'dpdown', dpleft = 'dpleft', dpright = 'dpright'}
    local axisToButton = {leftx = 'leftx', lefty = 'lefty', rightx = 'rightx', righty = 'righty', l2 = 'triggerleft', r2 = 'triggerright'}

    local function isKeyboardKey(key)
        return not (keyToButton[key] or gamepadToButton[key] or axisToButton[key])
    end

    --- Returns true when action is being held down with optional interval and delay
    ---@param action string
    ---@param interval number
    ---@param delay number
    ---@return boolean
    function self:down(action, interval, delay)
        if action and interval and delay then
            for _, key in ipairs(self.binds[action]) do
                if self.state[key] and not self.prevState[key] then
                    self.repeatState[key] = { pressed_time = love.timer.getTime(), delay = delay, interval = interval, delayStage = true }
                    return true
                elseif self.repeatState[key] then
                    return self.repeatState[key].pressed
                end
            end
        elseif action and interval and not delay then
            for _, key in ipairs(self.binds[action]) do
                if self.state[key] and not self.prevState[key] then
                    self.repeatState[key] = {pressed_time = love.timer.getTime(), delay = 0, interval = interval, delay_stage = false}
                    return true
                elseif self.repeatState[key] then
                    return self.repeatState[key].pressed
                end
            end
        elseif action and not interval and not delay then
            for _, key in ipairs(self.binds[action]) do
                if (isKeyboardKey(key) and love.keyboard.isDown(key)) or (keyToButton[key] and love.mouse.isDown(keyToButton[key])) then
                    return true
                end

                -- Support only 1 joystick for now
                if self.joystick[1] then
                    if axisToButton[key] then
                        return self.state[key]
                    elseif gamepadToButton[key] then
                        return self.joystick[1]:isGamepadDown(gamepadToButton[key])
                    end
                end
            end
        end

        return false
    end

    --- Unbinds a key from an action
    ---@param key string
    function self:unbind(key)
        for action, keys in pairs(self.binds) do
            for i = #keys, 1, -1 do
                if key == self.binds[action][i] then
                    table.remove(self.binds[action], i)
                end
            end
        end

        if self.functions[key] then
            self.functions[key] = nil
        end
    end

    --- Unbinds all keys from all actions
    function self:unbindAll()
        self.binds = {}
        self.functions = {}
    end

    --- Returns the next input that was pressed
    --- @return string|nil
    function self:getNextInputPressed()
        for _, key in ipairs(inputManager.all_keys) do
            if self.state[key] and not self.prevState[key] then
                return key
            end
        end

        return nil
    end

    function self:update()
        self:pressed()
        self.prevState = lume.clone(self.state)
        self.state["wheelup"] = false
        self.state["wheeldown"] = false

        for _, v in pairs(self.repeatState) do
            if v then
                v.pressed = false
                local t = love.timer.getTime() - v.pressed_time
                if v.delayStage then
                    if t > v.delay then
                        v.pressed = true
                        v.pressed_time = love.timer.getTime()
                        v.delayStage = false
                    end
                else
                    if t > v.interval then
                        v.pressed = true
                        v.pressed_time = love.timer.getTime()
                    end
                end
            end
        end
    end

    --#region Love2D callbacks

    ---@private
    function self:keypressed(key)
        self.state[key] = true
    end

    ---@private
    function self:keyreleased(key)
        self.state[key] = false
        self.repeatState[key] = nil
    end

    local buttonToKey = {
        [1] = "mouse1", [2] = "mouse2", [3] = "mouse3", [4] = "mouse4", [5] = "mouse5",
        ["l"] = "mouse1", ["r"] = "mouse2", ["m"] = "mouse3", ["x1"] = "mouse4", ["x2"] = "mouse5"
    }

    ---@private
    function self:mousepressed(x, y, button)
        self.state[buttonToKey[button]] = true
    end

    ---@private
    function self:mousereleased(x, y, button)
        self.state[buttonToKey[button]] = false
        self.repeatState[buttonToKey[button]] = nil
    end

    ---@private
    function self:wheelmoved(x, y)
        if y > 0 then self.state["wheelup"] = true
        elseif y < 0  then self.state["wheeldown"] = true end
    end

    local buttonToGamepad = {a = 'fdown', y = 'fup', x = 'fleft', b = 'fright', back = 'back', guide = 'guide', start = 'start',
                           leftstick = 'leftstick', rightstick = 'rightstick', leftshoulder = 'l1', rightshoulder = 'r1',
                           dpup = 'dpup', dpdown = 'dpdown', dpleft = 'dpleft', dpright = 'dpright'}

    ---@private
    function self:gamepadpressed(joystick, button)
        self.state[buttonToGamepad[button]] = true
    end

    ---@private
    function self:gamepadreleased(joystick, button)
        self.state[buttonToGamepad[button]] = false
        self.repeatState[buttonToGamepad[button]] = nil
    end

    local buttonToAxis = {leftx = 'leftx', lefty = 'lefty', rightx = 'rightx', righty = 'righty', triggerleft = 'l2', triggerright = 'r2'}

    ---@private
    function self:gamepadaxis(joystick, axis, newValue)
        self.state[buttonToAxis[axis]] = newValue
    end

    --#endregion

    return self
end

return inputManager