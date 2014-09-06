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

npc.stats = { str=0, grc=0, awr=0, lng=0}
npc.mood = 'agressive' --passive
npc.faction = 'neutral'
npc.in_combat = false

npc.world_x = 0; npc.world_y = 0
npc.pixel_x = 0; npc.pixel_y = 0

npc.roams = false
npc.current_anim = 'down_static'
npc.ori = 's'

npc.dt = (math.random() * 3) + 1
npc.counter = 0
npc.move_slice_x = 0
npc.move_slice_y = 0



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
end

function npc:roam( world, time, dt )
	--need to update world tile location, clear last tile, mark new tile
	--need to set world_x and world_y

	chance = math.random() * 100
	self.counter = self.counter + dt

	if chance < 92 then 
		return
	elseif self.counter > self.dt then
			map:set_tile_ocpied( self, true )		--clear current tile of occupation status
		if chance < 94 and self.world_y > 0 and map:get_tile_obj( self ):pass() then
			self.world_y = self.world_y - 1;
			self.ori = 'n'
		elseif chance < 96 and self.world_y < map.world.height_tiles and map:get_tile_obj( self ):pass() then
			self.world_y = self.world_y + 1
			self.ori = 's'
		elseif chance < 98 and self.world_x > 0 and map:get_tile_obj( self ):pass() then
			self.world_x = self.world_x - 1
			self.ori = 'w'
		elseif chance < 100 and self.world_x < map.world.width_tiles and map:get_tile_obj( self ):pass() then
			self.world_x = self.world_x + 1
			self.ori = 'e'
		end
		map:set_tile_ocpied( self )				--set new (or possibly old) tile as occupied

		self.move_slice_x = self.world_x  - self.pixel_x/32
		self.move_slice_y = self.world_y  - self.pixel_y/32

		self.counter = 0

	end

end


function npc:update_pixel( dt, TS )

	if self:is_moving() then
		self.pixel_x = self.pixel_x + self.move_slice_x
		self.pixel_y = self.pixel_y + self.move_slice_y
	end

	if self.ori == 's' then
		if self:is_moving() then self.current_anim = 'down_move'
		else self.current_anim = 'down_static' end

	elseif self.ori == 'n' then
		if self:is_moving() then self.current_anim = 'up_move'
		else self.current_anim = 'up_static' end

	elseif self.ori == 'w' then
		if self:is_moving() then self.current_anim = 'left_move'
		else self.current_anim = 'left_static' end

	elseif self.ori == 'e' then
		if self:is_moving() then self.current_anim = 'right_move'
		else self.current_anim = 'right_static' end
	end

	self.animations[ self.current_anim ]:update( dt )

end

--[[
function npc:attack_nearest_foe()
	foe = map:find_nearest_foe()
	if foe then
		attack
	end
--]]


--======================== HELPERS ==========================

function setup_animations( name, npc, TS)
	npc.animations[ name ] = newAnimation( npc.image, TS, TS, default_anims[ name ].delay, 2, default_anims[ name ].x, default_anims[ name ].y )
	npc.animations[ name ]:setMode( "loop" )
end

function npc:is_moving()
	return math.abs( self.pixel_x - self.world_x*TS) > 1 or math.abs(self.pixel_y - self.world_y*TS) > 1
end


function npc:is_friendly( person ) return self.faction == person.faction end
function npc:is_neutral( person ) return self.faction == 'neutral' end
function npc:is_foe( person ) return ( not self:is_friendly( person ) and not self:is_neutral( person ) ) end
function npc:is_injured() return ( self.stats.hp < self.stats.lung*self.stats.blood ) end
function npc:is_critical() return ( self.stats.hp < (self.stats.lung*self.stats.str)/4 ) end	


 return npc