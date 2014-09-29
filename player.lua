--[[
	Author: Eric Ames
	Last Updated: September 26th, 2014
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

player.is_attacking = 0
player.name = 'savior'
player.stats={ fang=2, rflx=3, lung=2, inst=1, mind=1, snout=3, aura=1, blood=3, fur=1, paw=1 }

player.ori = 's'
player.given_move_comm = false

player.current_party = {}
--==============================




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

	rules:setup_base_calcs( new_player )

	new_player.weapon = weapon:new( {name="Savior's Blade", damage=2, type='sword'} )

	return new_player
end


function player:update_self( dt, TS, map, disp )

	local build, move = self:move( map, disp )
	self:attack( disp, map )
	self:update_pixel( dt, TS )

	return build, move
end



function player:draw( TS, scale )	--for health bar, max is 20px
	local draw_position_x, draw_position_y = (self.offset_x*TS + self.pixel_x), (self.offset_y*TS + self.pixel_y - 16)
	love.graphics.draw( self.image , self.icon , draw_position_x * scale , draw_position_y * scale , 0 , scale , scale )

	if self:is_injured() then
		local health_fill = math.ceil( (self.current_hp / self.max_hp) * 20 )
		local G = 200 * ( health_fill / 20 ); local R = 200 - G;
		love.graphics.setColor( R, G, 10, 255 )
		love.graphics.rectangle( 'fill', (draw_position_x+TS)*scale , draw_position_y*scale , 2*scale, health_fill*scale)
		love.graphics.setColor( 255, 255, 255, 255 )
	end

end


function player:attack( disp, map )
	if self:attacking() > 0 then 
		ruleset:attack( self, disp, map )
		self.is_attacking = self.is_attacking + 1 		--increase attack frame by 1

		if self.is_attacking > self.weapon:num_of_hits() then 	--if all frames are complete, set to 0
			self.is_attacking = 0
		end
	end

end


function player:move( map, disp )
	local build = false;	local move = false
	local switch_dir_only = false;

	if not disp:is_moving() and not self:is_moving() and self.given_move_comm and self:attacking() == 0 then

		if self.given_move_comm == 'up' or self.given_move_comm == 'w' then
			if self.ori ~= 'n' then switch_dir_only = true end
			self.ori = 'n';
		elseif self.given_move_comm == 'down' or self.given_move_comm == 's' then
			if self.ori ~= 's' then switch_dir_only = true end
			self.ori = 's';
		elseif self.given_move_comm == 'right' or self.given_move_comm == 'd' then
			if self.ori ~= 'e' then switch_dir_only = true end
			self.ori = 'e';
		elseif self.given_move_comm == 'left' or self.given_move_comm == 'a' then
			if self.ori ~= 'w' then switch_dir_only = true end
			self.ori = 'w';
		end

		if switch_dir_only then switch_dir_only = false; self.give_move_comm = nil; return end

		local npc = map:get_resident( self )

		if self.given_move_comm and (map:get_passable( self ) or ( npc and love.keyboard.isDown('lshift') and npc:pushed( self.ori, map ) )) then

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
	target = map:get_resident( self )
	if target then
		if target:is_friendly( self ) then
			self.current_party[ target.name ] = target
			target:enter_player_party()
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

function player:attacking( set, value )
	if set then self.is_attacking = value end
	return self.is_attacking
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

function player:is_injured() return ( self.current_hp < self.max_hp ) end
function player:is_critical() return ( self.current_hp < self.max_hp / 4 ) end

function player:player_should_move()
	if self.ori == 'n' or self.ori == 's' then
		return self.from_center_y > -self.offset_y and self.from_center_y < self.offset_y - 1
	elseif self.ori == 'e' or self.ori == 'w' then
		return self.from_center_x > -self.offset_x and self.from_center_x < self.offset_x - 1 end
end
--==================================================



return player