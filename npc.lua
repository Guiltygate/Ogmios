--[[
	Author: Eric Ames
	Last Updated: September 26th, 2014
	Purpose: NPC object.
]]

default_anims = { 
   	down_static={	delay=0.6, x=0, y=0 }, down_move={	delay=0.2, x=2, y=0}
  	,left_static={	delay=0.6, x=0, y=1}, left_move={	delay=0.2, x=2, y=1}
	,up_static={	delay=0.6, x=0, y=2}, up_move={		delay=0.2, x=2, y=2}
 	,right_static={	delay=0.6, x=0, y=3}, right_move={	delay=0.2, x=2, y=3}

}

npc = {}
npc.name = "None"
npc.animations = {}
npc.world_x = 0; npc.world_y = 0
npc.pixel_x = 0; npc.pixel_y = 0

npc.roams = false
npc.is_roaming = false
npc.current_anim = 'down_static'
npc.ori = 's'

npc.dt = 1 --(math.random() * 4) + 1
npc.counter = 0

npc.catch_up = false
npc.in_party = false
npc.is_attacking = 0

npc.current_order = nil
npc.old_order = nil
npc.path = nil
-- stats, weapon, faction, mood, and speech are loader-only. See npc_loader.lua


--============================


--============= CORE FUNCTIONS ======================
function npc:new( param_table, TS )
	new_npc = param_table
	setmetatable( new_npc, self )
	self.__index = self

	new_npc.pixel_x = new_npc.world_x * TS
	new_npc.pixel_y = new_npc.world_y * TS

	rules:setup_base_calcs( new_npc )

	new_npc.animations = {}
	new_npc.is_roaming = new_npc.roams

	for name,anim in pairs( default_anims ) do
		setup_animations( name, new_npc, TS )
	end

	map:set_tile_ocpied( new_npc )

	return new_npc
end


function npc:draw( TS, scale, display )
	local draw_position_x, draw_position_y = (self.pixel_x - display.pixel_x), (self.pixel_y - 16 - display.pixel_y)

	self.animations[ self.current_anim ]:draw( draw_position_x*scale, draw_position_y*scale, 0, scale, scale )
	self:blurb( display , scale )
	self:health_bar()

end

function npc:update_self( dt, TS, map, disp, pc )

	if exploration_mode then
		self:roam( map , dt , disp )
		self:follow_char( pc, map , disp )
	elseif combat_mode and resolution_phase and not self:is_moving() then
		self:follow_orders( map , disp )
	end

	self:update_pixel( dt, TS )

end

function npc:update_pixel( dt, TS )
	local move_slice = math.ceil( dt * 100 )
	local x,y = get_tile_at_ori( self )
	x,y = x*move_slice,y*move_slice


	if self:is_moving_x() then
		local delta = self:get_displacement( 'x' ) 
		if math.abs( delta ) < math.abs( x ) then
			x = delta
		end
		self.pixel_x = self.pixel_x + x
	end

	if self:is_moving_y() then 
		local delta = self:get_displacement( 'y' )
		if math.abs( delta ) < math.abs( y ) then
			y = delta
		end
		self.pixel_y = self.pixel_y + y
	end


	--if not self:is_moving() and self.was_pushed then self.was_pushed = false end

	self:update_current_animation()
	self.animations[ self.current_anim ]:update( dt ) --uses AnAL (no jokes)

end

function npc:new_order( tile , x , y )
	--three cases (for now), tile is either occupied by foe (ATTACK), ally (ASSIST), or empty (MOVE)
	if self.current_order then self.old_order = self.current_order end

	local npc = tile:get_resident()
	if npc then
		if npc:is_friendly( self ) then
			self.current_order = { type='assist' , npc=npc }
		elseif npc:is_foe( self ) then
			self.current_order = { type='attack' , npc=npc }
		end
	elseif tile:passable() then
		self.current_order = { type='move' , x=x , y=y }
	end
end




--=============== ACTION FUNCTIONS ====================

function npc:roam( map, dt , disp )
	if not self.is_roaming then return end

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
		self:move( map , disp )
		self.counter = 0
	end
end


function npc:move( map , disp )
	if map:get_passable( self ) and not self:is_moving() and ( combat_mode or not self:collision( self , pc , disp ) ) then 
		map:set_tile_ocpied( self, true )

		local x,y = get_tile_at_ori( self )
		self.world_y = self.world_y + y
		self.world_x = self.world_x + x

		map:set_tile_ocpied( self )
	end
end

function npc:enter_player_party()
	self.is_roaming = false
	self.in_party = true
end

function npc:blurb( display, scale )
	if self.was_pushed then
		lprint( "Argh!", (self.pixel_x - display.pixel_x)*scale , (self.pixel_y - display.pixel_y - 16 )*scale )
	end
	if self.bad_move then
		lprint( "Um?..." , (self.pixel_x - display.pixel_x)*scale , (self.pixel_y - display.pixel_y - 16 )*scale )
	end
end

function npc:collision( mover , target , disp ) 		--right now assumes target is always pc, otherwise breaks!
	local x,y = get_tile_at_ori( mover )
	local target_bound = target:get_points( disp )
	
	if x == 0 then x = self.pixel_x + TS/2
	elseif x > 0 then x = self.pixel_x + TS + 27
	else x = self.pixel_x - 27
	end

	if y == 0 then y = self.pixel_y + TS/2
	elseif y > 0 then y = self.pixel_y + TS + 27
	else y = self.pixel_y - 27
	end

	npx,npy = x,y

	if target_bound.x0 < x and x < target_bound.x1 and
				target_bound.y0 < y and y < target_bound.y1 then
		return true
	else
		return false
	end
end

function npc:follow_orders( map , disp )
	local order = self.current_order
	
	if order then
		if order.type == 'move' then
			self.path = find_path( { x=self.world_x , y=self.world_y } , { x=order.x , y=order.y } )
		elseif order.type == 'attack' then
			self.path = find_path( { x=self.world_x , y=self.world_y } , { x=order.npc.world_x , y=order.npc.world_y } )
			self.target = order.npc
		end

		if not self.path then 
			self.bad_move = true
		else
			self.bad_move = false
			self.old_order = self.current_order
			self.current_order = nil
		end

	end

	if self.path and #self.path > 0 then self:follow_path( map , disp ) end

	--[[
	Thoughts:
	
	When movement order is given, plot out first 1/2 of path, save endpoint, then start moving and replot later?

	'defend' order is really a movement order + defend area stance.

	Three stances: Agressive (follow enemies ), Defend Area, and Passive (stand around doing nothing)
		Defend Area: Small (3x3), Moderate (5x5), Large (9x9).

	For attack order, store npc to attack.
		Use his world position to plot out a small path, say 1/3 of the way.
		Check size of distance to enemy, seeing if waypoints are worth it. I.e., depth!
		Every waypoint, replot to make sure the enemy hasn't moved too much.

		Once we've caught up, 

	For assist order, do about the same as attack order.
		The target may still be moving, so 


	--]]
end

function npc:follow_path( map , disp )
	local move = self.path[ #self.path ]
	local x = move.x - self.world_x
	local y = move.y - self.world_y

	print( x , y , self.world_x , self.world_y )

	if x > 0 then self.ori = 'e'
	elseif x < 0 then self.ori = 'w'
	elseif y > 0 then self.ori = 's'
	elseif y < 0 then self.ori = 'n'
	end

	self:move( map , disp ) --add if successful check, replot as needed

	self.path[ #self.path ] = nil

end



--=========== REACTION FUNCTIONS =================
function npc:pushed( ori, map )
	self.was_pushed = true
	if ori == 'e' then self.ori = 'n'
	elseif ori == 'n' then self.ori = 'w'
	elseif ori == 'w' then self.ori = 's'
	elseif ori == 's' then self.ori = 'e' end
	self:move( map , disp )
	if self:is_moving() then return true
	else self.was_pushed = false; return false end
end


function npc:talking( pc , done )
	if not done then self.is_roaming = false
	elseif not self.in_party then self.is_roaming = self.roams end

	if pc.ori == 'n' then self.ori = 's'
	elseif pc.ori == 'w' then self.ori = 'e'
	elseif pc.ori == 'e' then self.ori = 'w'
	elseif pc.ori == 's' then self.ori = 'n'
	end
end


function npc:follow_char( char, map , disp )
	if not self.in_party or self.in_battle then return end

	dx,dy = self:dist_to_char( char )
	abs_dx,abs_dy = self:dist_to_char( char, true )

	if not self:is_moving() then
		if (abs_dx >= 3 or self.catch_up) and abs_dx >= abs_dy then
			self.catch_up = true
			if dx > 0 then self.ori = 'e'
			elseif dx < 0 then self.ori = 'w' end

			self:move( map , disp )
			if not self:is_moving() then self.ori = 's'; self:move( map , disp );
				if not self:is_moving() then self.ori = 'n'; self:move( map , disp );
			end end

		elseif (abs_dy >= 3 or self.catch_up) then
			self.catch_up = true
			if dy > 0 then self.ori = 's'
			elseif dy < 0 then self.ori = 'n' end

			self:move( map , disp )
			if not self:is_moving() then self.ori = 'e'; self:move( map , disp );
				if not self:is_moving() then self.ori = 'w'; self:move( map , disp );
			end end
		end
	end

	if self:dist_to_char_x( char, true ) <= 2 and self:dist_to_char_y( char, true ) <= 2 then self.catch_up = false end
end

function npc:armor()
	local total = 0
	return 5
end

function npc:wound( dmg )
	self.current_hp = self.current_hp - dmg
	if self.current_hp < 0 then self.current_hp = 0
	end
end







--======================== HELPERS ==========================

function npc:health_bar()
	if self:is_injured() then
		local health_fill = math.ceil( (self.current_hp / self.max_hp) * 20 )
		local G = 200 * ( health_fill / 20 ); local R = 200 - G;
		love.graphics.setColor( R , G,  10 , 255 )
		love.graphics.rectangle( 'fill', (draw_position_x+TS)*scale , draw_position_y*scale , 2*scale , health_fill*scale)
		love.graphics.setColor( 255, 255, 255, 255 )
	end
end
	
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
	if char == 'x' then return math.abs( (self.world_x*TS) - self.pixel_x )
	elseif char == 'y' then return math.abs( ( self.world_y*TS ) - self.pixel_y ) end
end

function npc:is_friendly( person ) return self.faction == person.faction end
function npc:is_neutral( person ) return self.faction == 'neutral' end
function npc:is_foe( person ) return ( not self:is_friendly( person ) and not self:is_neutral( person ) ) end

function npc:is_injured() return ( self.current_hp < self.max_hp ) end
function npc:is_critical() return ( self.current_hp < self.max_hp / 4 ) end

function npc:get_speech() return self.speech end


function npc:dist_to_char_x( char, abs ) 
	if not abs then return char.world_x - self.world_x
	else return math.abs( char.world_x - self.world_x ) end end
function npc:dist_to_char_y( char, abs ) 
	if not abs then return char.world_y - self.world_y
	else return math.abs( char.world_y - self.world_y ) end end
function npc:dist_to_char( char, abs ) return self:dist_to_char_x( char, abs ), self:dist_to_char_y( char, abs ) end




 return npc