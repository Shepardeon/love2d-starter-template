local shep = { _version = "1.0.0" }

-- Global scope
Object = require("lib.classic")
-- Load all the modules

-- Modules
shep.debug = require("lib.shep.debug")
shep.loader = require("lib.shep.loader")
shep.utils = require("lib.shep.utils")

-- Classes
shep.Animator = require('lib.shep.animator')
shep.Atlas = require("lib.shep.atlas")
shep.Camera = require("lib.shep.camera")
shep.Entity = require("lib.shep.entity")
shep.EventManager = require("lib.shep.eventManager")
shep.Game = require("lib.shep.game")
shep.InputManager = require("lib.shep.inputManager")
shep.Renderer = require("lib.shep.renderer")
shep.Scene = require("lib.shep.scene")
shep.StateMachine = require("lib.shep.stateMachine")
shep.Shader = require("lib.shep.shader")

return shep