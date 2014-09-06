--[[

No time, I'm drunk.
display.lua!

]]

package.path = "Ogmios/sub_objects/?.lua"

disp = {}
msg_box = require( "msg_box" )
disp.move_slice_x = 0
disp.move_slice_y = 0


function disp:new( height, width, window_height, window_width )
	new_disp = {}
	setmetatable( new_disp, self )
	self.__index = self

	new_disp.world_x = 0; new_disp.world_y = 0
	new_disp.pixel_x = 0; new_disp.pixel_y = 0
	new_disp.height = height; new_disp.width = width
	new_disp.offset_x = 0; new_disp.offset_y = 0

	disp.text = msg_box:new( window_height, window_width)

	return new_disp
end

function disp:show_text( text )
	self.text:show_text( text )
end

function disp:draw_text()
	self.text:draw()
end

function disp:update_pixel( dt, TS, speed, pc)


	self.world_x = pc.world_x - pc.from_center_x - pc.offset_x
	self.world_y = pc.world_y - pc.from_center_y - pc.offset_y
	
	if self:started_moving() then
		self.move_slice_x = self.world_x - self.pixel_x/32
		self.move_slice_y = self.world_y - self.pixel_y/32
	end


	if self:is_moving() then
		self.pixel_x = self.pixel_x + self.move_slice_x
		self.pixel_y = self.pixel_y + self.move_slice_y
	end

end

function disp:draw( TS, tileset_batch, scale )
	love.graphics.draw( tileset_batch, -self.pixel_x*scale, -self.pixel_y*scale , 0, scale, scale )			--Now with SpriteBatch, this draws the entire world!
end





--===================== HELPERS =================================

function disp:is_moving()
	return math.abs( self.pixel_x - self.world_x*TS) > 1 or math.abs(self.pixel_y - self.world_y*TS) > 1
end

function disp:started_moving()
	return math.abs( self.pixel_x - self.world_x*TS) > 31 or math.abs(self.pixel_y - self.world_y*TS) > 31
end
--=================================================================


return disp