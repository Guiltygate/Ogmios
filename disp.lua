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

function disp:update_pixel( dt, TS, pc)
	local move_slice = math.ceil( dt * 100 )
	self.world_x = pc.world_x - pc.from_center_x - pc.offset_x
	self.world_y = pc.world_y - pc.from_center_y - pc.offset_y

	if self:get_displacement( 'x' ) < 0 or self:get_displacement( 'y' ) < 0 then	--set direction
		move_slice = move_slice * -1
	end


	if self:is_moving_x() then 
		if math.abs( self:get_displacement('x')) < move_slice then
			move_slice = self:get_displacement( 'x' ); print( "x displacement" )
		end
		self.pixel_x = self.pixel_x + move_slice
	end

	if self:is_moving_y() then 
		if math.abs( self:get_displacement('y')) < move_slice then
			move_slice = self:get_displacement( 'y' ); print( "y displacement" )
		end
		self.pixel_y = self.pixel_y + move_slice
	end
end



function disp:draw( TS, tileset_batch, scale )
	love.graphics.draw( tileset_batch, -self.pixel_x*scale, -self.pixel_y*scale , 0, scale, scale )			--Now with SpriteBatch, this draws the entire world!
end





--===================== HELPERS =================================

function disp:is_moving_x() return self.pixel_x  ~= self.world_x*TS end
function disp:is_moving_y() return self.pixel_y ~= self.world_y*TS end
function disp:is_moving() return self:is_moving_y() or self:is_moving_x() end

function disp:get_displacement( char )	--returns positive for +xy
	if char == 'x' then return (self.world_x*TS) - self.pixel_x
	elseif char == 'y' then return ( self.world_y*TS ) - self.pixel_y end
end

--=================================================================


return disp