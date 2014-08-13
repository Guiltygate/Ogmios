--[[

No time, I'm drunk.
display.lua!

]]

package.path = "Ogmios/sub_objects/?.lua"

disp = {}
msg_box = require( "msg_box" )


function disp:new( height, width, window_height, window_width )
	new_disp = {}
	setmetatable( new_disp, self )
	self.__index = self

	new_disp.xpos = 0
	new_disp.ypos = 0
	new_disp.xpos_pixel = 0
	new_disp.ypos_pixel = 0
	new_disp.height = height
	new_disp.width = width
	new_disp.offset_x = 0
	new_disp.offset_y = 0

	disp.text = msg_box:new( window_height, window_width)

	return new_disp
end

function disp:show_text( text )
	self.text:show_text( text )
end

function disp:draw_text()
	self.text:draw()
end

function disp:update( dt, TS, speed)

	self.xpos_pixel = self.xpos_pixel - ( (self.xpos_pixel - (self.xpos*TS) ) * dt * speed )
	self.ypos_pixel = self.ypos_pixel - ( (self.ypos_pixel - (self.ypos*TS) ) * dt * speed )

end

function disp:draw( TS, tileset_batch, scale )
	love.graphics.draw( tileset_batch, -self.xpos_pixel*scale , -self.ypos_pixel*scale , 0, scale, scale )			--Now with SpriteBatch, this draws the entire world!
end


return disp