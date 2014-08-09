--[[
	Author: Eric AMes
	Last Updated: August 3rd, 2014
	Purpose: Object for player character, to neaten up main.lua
--]]

player = {}
player.disp_pixel_x = 0
player.disp_pixel_y = 0
player.from_center_x = 0
player.from_center_y = 0

player.image = ""
player.icon = ""

player.world_x = 0
player.world_y = 0
player.offset_x = 0
player.offset_y = 0

player.ori = 's'

function player:new( icon, image, off_x, off_y, TS )
	new_player = {}
	setmetatable( new_player, self )
	self.__index = self

	new_player.image = image
	new_player.icon = icon
	new_player.offset_x = off_x
	new_player.offset_y = off_y

	return new_player
end



function player:draw( TS, scale )
	love.graphics.draw( self.image, self.icon, (( self.offset_x * TS ) + self.disp_pixel_x) * scale, (( self.offset_y * TS ) + self.disp_pixel_y) * scale, 0, scale, scale )
end



function player:update_loc( disp_x, disp_y )
	self.world_x = offset_x + self.from_center_x + disp_x
	self.world_y = self.offset_y + self.from_center_y + disp_y
end



function player:move( key, world, disp_x, disp_y, world_height, world_width)
	local build = false
	local move = false


   if ( key == 'up' or key == "w" ) then
	   	self.ori = 'n'												--change orientation

	   	if world[ self.world_x ][ self.world_y - 1 ]:pass() then	--if passable, move
	   		if disp_y > 0 and self.from_center_y == 0 then
	   			disp_y = disp_y - 1
	   			build = true
	   		elseif self.from_center_y > -self.offset_y then
	   			self.from_center_y = self.from_center_y - 1
	   			move = true
	   		end
	   	end

   elseif ( key == 'down' or key == "s" ) then
   		self.ori = 's'

   		if world[ self.world_x ][ self.world_y + 1 ]:pass() then
	   		if disp_y < ( world_height - self.offset_y*2 ) and self.from_center_y == 0 then
		      disp_y = disp_y + 1
		      build = true
		    elseif self.from_center_y < self.offset_y-1 then
		    	self.from_center_y = self.from_center_y + 1
		    	move = true
		    end
		end

   elseif ( key == 'left' or key == "a" ) then
   		self.ori = 'w'
   		if world[ self.world_x - 1 ][ self.world_y ]:pass() then
	   		if disp_x > 0 and self.from_center_x == 0 then
	   			disp_x = disp_x - 1
	   			build = true
	   		elseif self.from_center_x > -self.offset_x then
	   			self.from_center_x = self.from_center_x - 1
	   			move = true
	   		end
	   	end

   elseif ( key == 'right' or key == "d" ) then
   		self.ori = 'e'

   		if world[ self.world_x + 1 ][ self.world_y ]:pass() then
	   		if disp_x < ( world_width - self.offset_x*2 ) and self.from_center_x == 0 then
		      disp_x = disp_x + 1
		      build = true
		    elseif self.from_center_x < self.offset_x-1 then
		    	self.from_center_x = self.from_center_x + 1
		    	move = true
		    end
		end
   end

   return disp_x, disp_y, build, move
end


function player:pixel_move( dt, TS )
	self.disp_pixel_x = self.disp_pixel_x - ( (self.disp_pixel_x - (self.from_center_x*TS) ) * dt * 10 )
	self.disp_pixel_y = self.disp_pixel_y - ( (self.disp_pixel_y - (self.from_center_y*TS) ) * dt * 10 )

end


return player