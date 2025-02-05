---@diagnostic disable: undefined-field, redundant-parameter

local utils = require("lib.shep.utils")
local lume = require("lib.lume")

---@class shep.Debug
local debug = {}

local targetFps = 60
local frameTime = 1/targetFps * 1000

local dataPoints = {}
local maxDataPoints = 100
local avgUpdateTime = 0
local avgDrawTime = 0

-- Function to replace love.run
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

        table.insert(dataPoints, dataPoint)
        debug.update()
	end
end

function debug.update()
    if (#dataPoints >= maxDataPoints) then
        utils.shiftTable(dataPoints)
    end

    avgUpdateTime = utils.avgTable(lume.map(dataPoints, function(v) return v.updateTime end))
    avgDrawTime = utils.avgTable(lume.map(dataPoints, function(v) return v.drawTime end))
end

---@param x number|nil
---@param y number|nil
function debug.draw(x, y, barScale, barWidth)
    x = x or 0
    y = y or 0
    barScale = barScale or 1
    barWidth = barWidth or 1

    love.graphics.print(string.format("Update time: %.2f (%.2f percent of frame time)", avgUpdateTime, (avgUpdateTime/frameTime)*100), x,  y + 10)
    love.graphics.print(string.format("Draw time: %.2f (%.2f percent of frame time)", avgDrawTime, (avgDrawTime/frameTime)*100), x,  y + 25)

    for i, v in ipairs(dataPoints) do
        love.graphics.setColor(0, 0, 1, 1)
        love.graphics.rectangle('fill',
            x + (i * barWidth),
            y + 40 + 100 * barScale,
            barWidth,
            -100 * barScale
        )

        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle('fill',
            x + (i * barWidth),
            y + 40 + 100 * barScale,
            barWidth,
            -v.updateTime / frameTime * 100 * barScale
        )

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle('fill',
            x + (i * barWidth),
            y + 40 - v.updateTime / frameTime * 100 * barScale + 100 * barScale,
            barWidth,
            -v.drawTime / frameTime * 100 * barScale
        )

        love.graphics.setColor(1, 1, 1, 1)
    end
end

return debug