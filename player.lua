--[[
	Author: Eric AMes
	Last Updated: August 3rd, 2014
	Purpose: Object for player character, to neaten up main.lua
--]]

player = {}

player.pixel_x = 0
player.pixel_y = 0
player.from_center_x = 0
player.from_center_y = 0

player.faction = 'ally'
player.in_combat = false

player.image = ""
player.icon = ""

player.move_slice_x = 0
player.move_slice_y = 0

player.offset_x = 0
player.offset_y = 0

player.is_attacking = false
player.name = 'savior'
player.stats={ fang=5, rflx=3, lung=2, inst=1, mind=1, snout=3, aura=1, blood=3, fur=1, paw=1 }

player.ori = 's'

--=== NPC API, since the manager handles the player now =====
player.roams = false
player.in_party = false
--==============================

player.current_party = {}

function player:new( icon, image, offset, TS )
	new_player = {}
	setmetatable( new_player, self )
	self.__index = self

	new_player.image = image
	new_player.icon = icon
	new_player.offset_x = offset.x
	new_player.offset_y = offset.y

	new_player.world_x = offset.x
	new_player.world_y = offset.y

	return new_player
end



function player:draw( TS, scale )
	love.graphics.draw( self.image, self.icon, (( self.offset_x * TS ) + self.pixel_x ) * scale, (( self.offset_y * TS ) + self.pixel_y - (TS / 2) ) * scale, 0, scale, scale )
end



function player:move( map, disp )
	local build = false;	local move = false
	local world = map.world
	local height = world.height_tiles;	local width = world.width_tiles

	if not disp:is_moving() and not self:is_moving() then

	   if love.keyboard.isDown( 'up' ) or love.keyboard.isDown( 'w' ) then
		   	self.ori = 'n'											--change orientation
		   	if map:get_passable( self ) then	--if passable, move
		   		if disp.world_y > 0 and self.from_center_y == 0 then
		   			map:set_tile_ocpied( self, true )
		   			build = true

		   		elseif self.from_center_y > -self.offset_y then
		   			map:set_tile_ocpied( self, true )
		   			self.from_center_y = self.from_center_y - 1
		   			move = true
		   		end
		   	end

	   elseif love.keyboard.isDown( 'down' ) or love.keyboard.isDown( 's' ) then
	   		self.ori = 's'
	   		if map:get_passable( self ) then
		   		if disp.world_y < ( height - self.offset_y*2 ) and self.from_center_y == 0 then
					map:set_tile_ocpied( self, true )
			      	build = true

			    elseif self.from_center_y < self.offset_y-1 then
		   			map:set_tile_ocpied( self, true )
			    	self.from_center_y = self.from_center_y + 1
			    	move = true

			    end
			end

	   elseif love.keyboard.isDown( 'left' ) or love.keyboard.isDown( 'a' ) then
	   		self.ori = 'w'
	   		if map:get_passable( self ) then
		   		if disp.world_x > 0 and self.from_center_x == 0 then
		   			map:set_tile_ocpied( self, true )
		   			build = true

		   		elseif self.from_center_x > -self.offset_x then
		   			map:set_tile_ocpied( self, true )
		   			self.from_center_x = self.from_center_x - 1
		   			move = true

		   		end
		   	end

	   elseif love.keyboard.isDown( 'right' ) or love.keyboard.isDown( 'd' ) then
	   		self.ori = 'e'
	   		if map:get_passable( self ) then
		   		if disp.world_x < ( width - self.offset_x*2 ) and self.from_center_x == 0 then		      
		   			map:set_tile_ocpied( self, true )
			      	build = true

			    elseif self.from_center_x < self.offset_x-1 then
		   			map:set_tile_ocpied( self, true )
			    	self.from_center_x = self.from_center_x + 1
			    	move = true

			    end
			end
	   end

		if move or build then
			local x,y = get_tile_at_ori( self )
			self.world_x = self.world_x + x
			self.world_y = self.world_y + y
			map:set_tile_ocpied( self )
		end
	end

   return build, move
end


function player:update_pixel( dt, TS )

	if self:started_moving() then
		self.move_slice_x = self.from_center_x - self.pixel_x/32
		self.move_slice_y = self.from_center_y - self.pixel_y/32
	end

	if self:is_moving() then
		self.pixel_x = self.pixel_x + self.move_slice_x
		self.pixel_y = self.pixel_y + self.move_slice_y
	end

end


function player:add_to_party( map, display, manager )
	if map:get_ocpied( self ) then
		local res = map:get_resident( self )
		if res:is_friendly( self ) then
			self.current_party[ res.name ] = res
			res:enter_player_party()
		end
	end

end

function player:remove_from_party( res, manager )
	self.current_party[ res.name ] = nil
end











--=============== HELPERS =========================

function player:is_moving()
	return math.abs( self.pixel_x  - self.from_center_x*TS ) > 1 or math.abs( self.pixel_y - self.from_center_y*TS ) > 1
end

function player:started_moving()
	return math.abs( self.pixel_x - self.from_center_x*TS) > 31 or math.abs(self.pixel_y - self.from_center_y*TS) > 31
end

function player:attacking( set )
	player.is_attacking = ( set or false )
end
--==================================================

return player