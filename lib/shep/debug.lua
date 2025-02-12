---@diagnostic disable: undefined-field, redundant-parameter

local utils = require("lib.shep.utils")
local lume = require("lib.lume")

---@class shep.Debug
local debug = {}

debug.config = {
    targetFps = 60,
    maxDataPoints = 250,

    shadowColor = {0, 0, 0, 0.5},
    shadowOffset = { x = 1, y = 1 },

    drawGraph = false,
    drawDebug = true,
}

debug.stats = {
    avgUpdateTime = 0,
    avgDrawTime = 0,

    avgUpdateTimePercent = 0,
    avgDrawTimepercent = 0,
}

---@type string[]
debug.info = {}

local frameTime = 1/debug.config.targetFps * 1000

debug.dataPoints = {}

--- Function to replace love.run.
function debug.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0
    local startTime = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

        local dataPoint = {}

		-- Update dt, as we'll be passing it to update
		if love.timer then
            dt = love.timer.step()
            startTime = love.timer.getTime() * 1000
        end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        if love.timer then
            dataPoint.updateTime = love.timer.getTime() * 1000 - startTime
        end

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

            if love.timer then
                startTime = love.timer.getTime() * 1000
            end

			if love.draw then love.draw() end

            if love.timer then
                dataPoint.drawTime = love.timer.getTime() * 1000 - startTime
            end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end

        table.insert(debug.dataPoints, dataPoint)
	end
end

--- Updates the debug data.
function debug.update()
    if (#debug.dataPoints >= debug.config.maxDataPoints) then
        utils.shiftTable(debug.dataPoints)
    end

    debug.stats.avgUpdateTime = utils.avgTable(lume.map(debug.dataPoints, function(v) return v.updateTime end))
    debug.stats.avgDrawTime = utils.avgTable(lume.map(debug.dataPoints, function(v) return v.drawTime end))

    debug.stats.avgUpdateTimePercent = debug.stats.avgUpdateTime / frameTime * 100
    debug.stats.avgDrawTimePercent = debug.stats.avgDrawTime / frameTime * 100

    local stats = love.graphics.getStats()
    local ram = collectgarbage("count")
    local ramUnit = "KB"
    local vram = stats.texturememory / 1024
    local vramUnit = "KB"

    if ram > 1024 then
        ram = ram / 1024
        ramUnit = "MB"
    end

    if vram > 1024 then
        vram = vram / 1024
        vramUnit = "MB"
    end

    debug.info = {
        "FPS: " .. love.timer.getFPS(),
        "Draw Time: " .. lume.round(debug.stats.avgDrawTime, .001) .. "ms (" .. lume.round(debug.stats.avgDrawTimePercent, 0.1) .. "%)",
        "Update Time: " .. lume.round(debug.stats.avgUpdateTime, .001) .. "ms (" .. lume.round(debug.stats.avgUpdateTimePercent, 0.1) .. "%)",
        "RAM: " .. lume.round(ram, .01) .. ramUnit,
        "VRAM: " .. lume.round(vram, .01) .. vramUnit,
        "Draw calls: " .. stats.drawcalls,
        "Images: " .. stats.images,
        "Canvases: " .. stats.canvases,
        "\tSwitches: " .. stats.canvasswitches,
        "Shader Switches: " .. stats.shaderswitches,
        "Fonts: " .. stats.fonts,
    }
end

---@private
---@param x number
---@param y number
---@param barScale number
---@param barWidth number
function debug.drawGraph(x, y, barScale, barWidth)
    local barSize = 100 * barScale

    for i, v in ipairs(debug.dataPoints) do
        love.graphics.setColor(0, 0, 1, 1)
        love.graphics.rectangle('fill',
            x + (i * barWidth),
            y + barSize,
            barWidth,
            -barSize
        )

        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle('fill',
            x + (i * barWidth),
            y + barSize,
            barWidth,
            -v.updateTime / frameTime * barSize
        )

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle('fill',
            x + (i * barWidth),
            y - v.updateTime / frameTime * barSize + barSize,
            barWidth,
            -v.drawTime / frameTime * barSize
        )

        love.graphics.setColor(1, 1, 1, 1)
    end
end

--- Draws the debug information.
---@param x number|nil
---@param y number|nil
---@param barScale number|nil
---@param barWidth number|nil
function debug.draw(x, y, barScale, barWidth)
    x = x or 0
    y = y or 0
    barScale = barScale or 1
    barWidth = barWidth or 1

    if not debug.config.drawDebug then return end

    -- We must update the debug infos during the render frame
    -- otherwise we won't get the correct frame data
    debug.update()

    for _, info in ipairs(debug.info) do
        love.graphics.setColor(debug.config.shadowColor)
        love.graphics.print(info, x + debug.config.shadowOffset.x, y + debug.config.shadowOffset.y)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(info, x, y)
        y = y + 15
    end

    if debug.config.drawGraph then
        debug.drawGraph(x, y, barScale, barWidth)
    end
end

return debug