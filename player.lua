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

	print( disp:is_moving(), self:is_moving() )

	if not disp:is_moving() and not self:is_moving() then
	   if love.keyboard.isDown( 'up' ) or love.keyboard.isDown( 'w' ) then
		   	self.ori = 'n'												--change orientation

		   	if map:get_tile_obj( self ):pass() then	--if passable, move
		   		if disp.world_y > 0 and self.from_center_y == 0 then
		   			map:set_tile_ocpied( self, true )
		   			build = true

		   		elseif self.from_center_y > -self.offset_y then
		   			map:set_tile_ocpied( self, true )
		   			self.from_center_y = self.from_center_y - 1
		   			move = true

		   		end

		   		if move or build then self.world_y = self.world_y - 1; map:set_tile_ocpied( self ) end

		   	end

	   elseif love.keyboard.isDown( 'down' ) or love.keyboard.isDown( 's' ) then
	   		self.ori = 's'

	   		if map:get_tile_obj( self ):pass() then
		   		if disp.world_y < ( height - self.offset_y*2 ) and self.from_center_y == 0 then
					map:set_tile_ocpied( self, true )
			      	build = true

			    elseif self.from_center_y < self.offset_y-1 then
		   			map:set_tile_ocpied( self, true )
			    	self.from_center_y = self.from_center_y + 1
			    	move = true

			    end

		   		if move or build then self.world_y = self.world_y + 1; map:set_tile_ocpied( self ) end

			end

	   elseif love.keyboard.isDown( 'left' ) or love.keyboard.isDown( 'a' ) then
	   		self.ori = 'w'
	   		if map:get_tile_obj( self ):pass() then
		   		if disp.world_x > 0 and self.from_center_x == 0 then
		   			map:set_tile_ocpied( self, true )
		   			build = true

		   		elseif self.from_center_x > -self.offset_x then
		   			map:set_tile_ocpied( self, true )
		   			self.from_center_x = self.from_center_x - 1
		   			move = true

		   		end

		   		if move or build then self.world_x = self.world_x - 1; map:set_tile_ocpied( self ) end

		   	end

	   elseif love.keyboard.isDown( 'right' ) or love.keyboard.isDown( 'd' ) then
	   		self.ori = 'e'

	   		if map:get_tile_obj( self ):pass() then
		   		if disp.world_x < ( width - self.offset_x*2 ) and self.from_center_x == 0 then		      
		   			map:set_tile_ocpied( self, true )
			      	build = true

			    elseif self.from_center_x < self.offset_x-1 then
		   			map:set_tile_ocpied( self, true )
			    	self.from_center_x = self.from_center_x + 1
			    	move = true

			    end

		   		if move or build then self.world_x = self.world_x + 1; map:set_tile_ocpied( self ) end

			end
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
	local npc = map:get_tile_obj( pc )

	for i,v in ipairs( player.current_party ) do	--testing only, remove
		print( i, v.name )
	end

	if map:get_tile_obj( pc ):is_ocpied() and map:get_tile_obj( pc ):is_friendly( self ) then
		self.current_party[ npc.name ] = npc
		manager.remove_npc( npc )
	end

	for i,v in ipairs( player.current_party ) do	--testing only, remove
		print( i, v.name )
	end

end

function player:remove_from_party( npc, manager )
	manager.add_npc( false, npc )
	self.current_party[ npc.name ] = nil
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