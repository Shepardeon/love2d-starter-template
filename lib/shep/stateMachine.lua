--- @class shep.StateFlow
local StateFlow = Object:extend()

---@param subject any
---@param normalState function
---@param enterState function|nil
---@param exitState function|nil
function StateFlow:new(subject, normalState, enterState, exitState)
    self.subject = subject
    self.normalState = normalState
    self.enterState = enterState
    self.exitState = exitState
end

--- @class shep.StateMachine
--- @field states table<function, shep.StateFlow>
--- @field currentState function|nil
local StateMachine = Object:extend()

--- Initializes a new StateMachine instance.
function StateMachine:new()
    self.states = {}
    self.currentState = nil
end

--- Adds a new state to the state machine.
--- @param subject any The subject associated with the state.
--- @param normalState function The function representing the normal state.
--- @param enterState function|nil The function to call when entering the state.
--- @param exitState function|nil The function to call when exiting the state.
function StateMachine:addState(subject, normalState, enterState, exitState)
    self.states[normalState] = StateFlow(subject, normalState, enterState, exitState)
end

--- Changes the current state to the specified state.
--- @param toState function The function representing the state to change to.
function StateMachine:changeState(toState)
    local stateFlows = self.states[toState]

    if stateFlows then
        self:setState(stateFlows)
    end
end

--- Sets the initial state of the state machine.
--- @param initialState function The function representing the initial state.
function StateMachine:setInitialState(initialState)
    local stateFlows = self.states[initialState]

    if stateFlows then
        self:setState(stateFlows)
    end
end

--- Updates the current state.
--- @param dt number The delta time since the last update.
function StateMachine:update(dt)
    if self.currentState then
        self.currentState(self.states[self.currentState].subject, dt)
    end
end

--- Sets the current state to the specified state flow.
--- @private
--- @param stateFlows shep.StateFlow The state flow to set as the current state.
function StateMachine:setState(stateFlows)
    if self.currentState then
        ---@type shep.StateFlow
        local currentState = self.states[self.currentState]

        if currentState.exitState then
            currentState.exitState(currentState.subject)
        end
    end

    self.currentState = stateFlows.normalState

    if stateFlows.enterState then
        stateFlows.enterState(stateFlows.subject)
    end
end

return StateMachine