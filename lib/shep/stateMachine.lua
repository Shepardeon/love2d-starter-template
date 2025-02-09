--- @class shep.StateFlow
local StateFlow = Object:extend()

---@param normalState function
---@param enterState function|nil
---@param exitState function|nil
function StateFlow:new(normalState, enterState, exitState)
    self.normalState = normalState
    self.enterState = enterState
    self.exitState = exitState
end

--- @class shep.StateMachine
--- @field states table<function, shep.StateFlow>
--- @field currentState function|nil
local StateMachine = Object:extend()

function StateMachine:new()
    self.states = {}
    self.currentState = nil
end

---@param normalState function
---@param enterState function|nil
---@param exitState function|nil
function StateMachine:addState(normalState, enterState, exitState)
    self.states[normalState] = StateFlow(normalState, enterState, exitState)
end

---@param toState function
function StateMachine:changeState(toState)
    local stateFlows = self.states[toState]

    if stateFlows then
        self:setState(stateFlows)
    end
end

---@param initialState function
function StateMachine:setInitialState(initialState)
    local stateFlows = self.states[initialState]

    if stateFlows then
        self:setState(stateFlows)
    end
end

function StateMachine:update(dt)
    if self.currentState then
        self.currentState(dt)
    end
end

---@private
---@param stateFlows shep.StateFlow
function StateMachine:setState(stateFlows)
    if self.currentState and self.states[self.currentState].exitState then
        self.states[self.currentState].exitState()
    end

    self.currentState = stateFlows.normalState

    if stateFlows.enterState then
        stateFlows.enterState()
    end
end

return StateMachine