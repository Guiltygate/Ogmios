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

player.offset_x = 0
player.offset_y = 0

player.is_attacking = false
player.name = 'savior'
player.stats={ fang=5, rflx=3, lung=2, inst=1, mind=1, snout=3, aura=1, blood=3, fur=1, paw=1 }

player.ori = 's'
player.given_move_comm = false

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

function player:update_self( dt, TS, map, disp )
	local build, move = self:move( map, disp )
	self:update_pixel( dt, TS )
	return build, move
end

function player:draw( TS, scale )
	love.graphics.draw( self.image, self.icon, (( self.offset_x * TS ) + self.pixel_x ) * scale, (( self.offset_y * TS ) + self.pixel_y - (TS / 2) ) * scale, 0, scale, scale )
end



function player:move( map, disp )
	local build = false;	local move = false

	if not disp:is_moving() and not self:is_moving() and self.given_move_comm then

		if self.given_move_comm == 'up' or self.given_move_comm == 'w' then
			self.ori = 'n';
		elseif self.given_move_comm == 'down' or self.given_move_comm == 's' then
			self.ori = 's';
		elseif self.given_move_comm == 'right' or self.given_move_comm == 'd' then
			self.ori = 'e';
		elseif self.given_move_comm == 'left' or self.given_move_comm == 'a' then
			self.ori = 'w';
		end

		local npc = map:get_resident( self )

		if (map:get_passable( self ) or ( npc and npc:pushed( self.ori, map ) )) and self.given_move_comm then

			if self:disp_should_move( disp, map.world, self.ori ) then
				map:set_tile_ocpied( self, true )
				build = true
			elseif self:player_should_move() then
				map:set_tile_ocpied( self, true )
				x,y = get_tile_at_ori( self )
				self.from_center_y = self.from_center_y + y
				self.from_center_x = self.from_center_x + x
				move = true
			end
		end

		if move or build then
			local x,y = get_tile_at_ori( self )
			self.world_x = self.world_x + x
			self.world_y = self.world_y + y
			map:set_tile_ocpied( self )
		end
	end 

	self.given_move_comm = nil

   return build, move
end


function player:update_pixel( dt, TS )
	local move_slice = math.ceil( dt * 100 )

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

function player:is_moving_x() return self.pixel_x  ~= self.from_center_x*TS end
function player:is_moving_y() return self.pixel_y ~= self.from_center_y*TS end
function player:is_moving() return self:is_moving_y() or self:is_moving_x() end

function player:get_displacement( char )	--returns positive for +xy
	if char == 'x' then return (self.from_center_x*TS) - self.pixel_x
	elseif char == 'y' then return ( self.from_center_y*TS ) - self.pixel_y end
end

function player:attacking( set )
	player.is_attacking = ( set or false )
end

function player:trigger_move( key ) self.given_move_comm = key end

function player:disp_should_move( disp, world, ori )
	if ori == 'n' then
		return disp.world_y > 0 and self.from_center_y == 0
	elseif ori == 's' then
		return disp.world_y < (world.height_tiles - (self.offset_y*2)) and self.from_center_y == 0
	elseif ori == 'w' then
		return disp.world_x > 0 and self.from_center_x == 0
	elseif ori == 'e' then
		return disp.world_x < (world.width_tiles - (self.offset_x*2)) and self.from_center_x == 0 
	end
end

function player:player_should_move()
	if self.ori == 'n' or self.ori == 's' then
		return self.from_center_y > -self.offset_y and self.from_center_y < self.offset_y - 1
	elseif self.ori == 'e' or self.ori == 'w' then
		return self.from_center_x > -self.offset_x and self.from_center_x < self.offset_x - 1 end
end
--==================================================



return player