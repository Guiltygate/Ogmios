--[[
	Author: Eric Ames
	Last Updated: August 3rd
	Purpose: NPC object.
]]

default_anims = { 
   	down_static={	delay=0.6, x=0, y=0 }, down_move={	delay=0.2, x=2, y=0}
  	,left_static={	delay=0.6, x=0, y=1}, left_move={	delay=0.2, x=2, y=1}
	,up_static={		delay=0.6, x=0, y=2}, up_move={		delay=0.2, x=2, y=2}
 	,right_static={	delay=0.6, x=0, y=3}, right_move={	delay=0.2, x=2, y=3}

}

npc = {}
npc.name = "None"
npc.animations = {}
npc.world_x = 0; npc.world_y = 0
npc.pixel_x = 0; npc.pixel_y = 0

npc.roams = false
npc.current_anim = 'down_static'
npc.ori = 's'

npc.dt = 1 --(math.random() * 4) + 1
npc.counter = 0
npc.move_slice_x = 0
npc.move_slice_y = 0

npc.catch_up = false
npc.in_battle = false
npc.in_party = false
npc.mood = 'agressive' --passive
npc.faction = 'neutral'


function npc:new( param_table, TS )
	new_npc = param_table
	setmetatable( new_npc, self )
	self.__index = self

	new_npc.pixel_x = new_npc.world_x * TS
	new_npc.pixel_y = new_npc.world_y * TS

	new_npc.animations = {}

	for name,anim in pairs( default_anims ) do
		setup_animations( name, new_npc, TS )
	end

	map:set_tile_ocpied( new_npc )

	return new_npc
end


function npc:draw( TS, scale, display )
	self.animations[ self.current_anim ]:draw( (self.pixel_x - display.pixel_x)*scale,
							 (self.pixel_y - display.pixel_y - (TS/2))*scale, 0, scale, scale )
	self:blurb( display, scale )
end

function npc:update_self( dt, TS, map, disp, pc )

	self:roam( map, dt)
	self:follow_char( pc, map )

	self:update_pixel( dt, TS )

		--[[
		if v:is_injured() and not v:is_critical() then
			v:attack_nearest_foe()
		end

		if v:is_critical() then
			--v:flee()
			print("Fleeing test.")
		end--]]

end


function npc:roam( map, dt )
	if not self.roams then return end

	chance = math.random() * 100
	self.counter = self.counter + dt

	if chance < 92 then 
		return
	elseif self.counter > self.dt then
		if chance < 94 then
			self.ori = 'n'
		elseif chance < 96 then
			self.ori = 's'
		elseif chance < 98 then
			self.ori = 'w'
		elseif chance < 100 then
			self.ori = 'e'
		end
		self:move( map )

		self.counter = 0

	end

end


function npc:move( map )
	if map:get_passable( self ) and map:in_bounds( self ) and not self:is_moving() then 
		map:set_tile_ocpied( self, true )

		x,y = get_tile_at_ori( self )
		self.world_y = self.world_y + y
		self.world_x = self.world_x + x

		map:set_tile_ocpied( self )
	end
end


function npc:update_pixel( dt, TS )
	local move_slice = math.ceil( dt * 100 )

	if self:get_displacement( 'x' ) < 0 or self:get_displacement( 'y' ) < 0 then	--set direction
		move_slice = move_slice * -1
	end


	if self:is_moving_x() then 
		if math.abs( self:get_displacement('x')) < move_slice then
			move_slice = self:get_displacement( 'x' ); print( "x displacement" )
		end
		self.pixel_x = self.pixel_x + move_slice end
	if self:is_moving_y() then 
		if math.abs( self:get_displacement('y')) < move_slice then
			move_slice = self:get_displacement( 'y' ); print( "y displacement" )
		end
		self.pixel_y = self.pixel_y + move_slice end


	if not self:is_moving() and self.was_pushed then self.was_pushed = false end

	self:update_current_animation()
	self.animations[ self.current_anim ]:update( dt )

end

function npc:enter_player_party()
	self.roams = false
	self.in_party = true
end



function npc:pushed( ori, map )
	self.was_pushed = true
	if ori == 'e' then self.ori = 'n'
	elseif ori == 'n' then self.ori = 'w'
	elseif ori == 'w' then self.ori = 's'
	elseif ori == 's' then self.ori = 'e' end
	self:move( map )
	if self:is_moving() then return true
	else self.was_pushed = false; return false end
end



function npc:blurb( display, scale )
	if self.was_pushed then
	love.graphics.print( "Argh!", (self.pixel_x - display.pixel_x)*scale, (self.pixel_y - display.pixel_y - 16)*scale )
	end
end


function npc:follow_char( char, map )
	if not self.in_party or self.in_battle then return end

	dx,dy = self:dist_to_char( char )
	abs_dx,abs_dy = self:dist_to_char( char, true )

	if not self:is_moving() then
		if (abs_dx >= 3 or self.catch_up) and abs_dx >= abs_dy then
			self.catch_up = true
			if dx > 0 then self.ori = 'e'
			elseif dx < 0 then self.ori = 'w' end

			self:move( map )
			if not self:is_moving() then self.ori = 's'; self:move( map );
				if not self:is_moving() then self.ori = 'n'; self:move( map );
			end end

		elseif (abs_dy >= 3 or self.catch_up) then
			self.catch_up = true
			if dy > 0 then self.ori = 's'
			elseif dy < 0 then self.ori = 'n' end

			self:move( map )
			if not self:is_moving() then self.ori = 'e'; self:move( map );
				if not self:is_moving() then self.ori = 'w'; self:move( map );
			end end
		end
	end

	if self:dist_to_char_x( char, true ) <= 2 and self:dist_to_char_y( char, true ) <= 2 then self.catch_up = false end

end



--======================== HELPERS ==========================
	
function setup_animations( name, npc, TS)
	npc.animations[ name ] = newAnimation( npc.image, TS, TS, default_anims[ name ].delay, 2, default_anims[ name ].x, default_anims[ name ].y )
	npc.animations[ name ]:setMode( "loop" )
end

function npc:update_current_animation()
	if self.ori == 's' then
		new_anim = { 'down_move', 'down_static' }

	elseif self.ori == 'n' then
		new_anim = { 'up_move' , 'up_static' }

	elseif self.ori == 'w' then
		new_anim = { 'left_move' , 'left_static' }

	elseif self.ori == 'e' then
		new_anim = { 'right_move' , 'right_static' }
	end

	if self:is_moving() then self.current_anim = new_anim[ 1 ]
		else self.current_anim = new_anim[ 2 ] end

end
	
function npc:is_moving_x() return self.pixel_x  ~= self.world_x*TS end
function npc:is_moving_y() return self.pixel_y ~= self.world_y*TS end
function npc:is_moving() return self:is_moving_y() or self:is_moving_x() end

function npc:get_displacement( char )	--returns positive for +xy
	if char == 'x' then return (self.world_x*TS) - self.pixel_x
	elseif char == 'y' then return ( self.world_y*TS ) - self.pixel_y end
end

function npc:is_friendly( person ) return self.faction == person.faction end
function npc:is_neutral( person ) return self.faction == 'neutral' end
function npc:is_foe( person ) return ( not self:is_friendly( person ) and not self:is_neutral( person ) ) end
function npc:is_injured() return ( self.stats.hp < self.stats.lung*self.stats.blood ) end
function npc:is_critical() return ( self.stats.hp < (self.stats.lung*self.stats.str)/4 ) end
function npc:get_speech() return self.speech end


function npc:dist_to_char_x( char, abs ) 
	if not abs then return char.world_x - self.world_x
	else return math.abs( char.world_x - self.world_x ) end end
function npc:dist_to_char_y( char, abs ) 
	if not abs then return char.world_y - self.world_y
	else return math.abs( char.world_y - self.world_y ) end end
function npc:dist_to_char( char, abs ) return self:dist_to_char_x( char, abs ), self:dist_to_char_y( char, abs ) end




 return npc