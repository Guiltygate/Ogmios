--[[
	Main configuration file for Love
--]]


function love.conf(t)			--General love settings. Look up this when in doubt.
    t.window.width = 1824
    t.window.height = 1056
    t.window.fullscreen = false
    t.window.vsync = true
    t.window.title = "Ogmios 0.1.00"

    t.window.fsaa = 0

    t.modules.physics = false


end

