local stateMachine = {}

function stateMachine.new()
    local stateFlow = {}

    ---@param normalState function
    ---@param enterState function|nil
    ---@param exitState function|nil
    function stateFlow.new(normalState, enterState, exitState)
        --- @class shep.StateFlow
        local self = {}
        self.normalState = normalState
        self.enterState = enterState
        self.exitState = exitState
        return self
    end

    --- @class shep.StateMachine
    --- @field states table<function, shep.StateFlow>
    --- @field currentState function|nil
    local self = {}
    self.states = {}
    self.currentState = nil

    ---@param normalState function
    ---@param enterState function|nil
    ---@param exitState function|nil
    function self:addState(normalState, enterState, exitState)
        self.states[normalState] = stateFlow.new(normalState, enterState, exitState)
    end

    ---@param toState function
    function self:changeState(toState)
        local stateFlows = self.states[toState]

        if stateFlows then
            self:setState(stateFlows)
        end
    end

    ---@param initialState function
    function self:setInitialState(initialState)
        local stateFlows = self.states[initialState]

        if stateFlows then
            self:setState(stateFlows)
        end
    end

    function self:update(dt)
        if self.currentState then
            self.currentState(dt)
        end
    end

    ---@private
    ---@param stateFlows shep.StateFlow
    function self:setState(stateFlows)
        if self.currentState and self.states[self.currentState].exitState then
            self.states[self.currentState].exitState()
        end

        self.currentState = stateFlows.normalState

        if stateFlows.enterState then
            stateFlows.enterState()
        end
    end

    return self
end

return stateMachine