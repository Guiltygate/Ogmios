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
player.stats={ 2, 3, 2, 1, 1, 3, 1, 3, 1, 1 }

player.ori = 's'

player.current_orders = nil
player.old_orders = nil

player.current_party = {}
--==============================




function player:new( icon, image, offset, TS, coll_world , stats_master )
	new_player = {}
	setmetatable( new_player, self )
	self.__index = self

	new_player.image = image
	new_player.icon = icon
	new_player.offset_x = offset.x*TS
	new_player.offset_y = offset.y*TS

	new_player.width_margin = 2
	new_player.height_margin = 2

	local stats = {}
	for i,v in ipairs( stats_master ) do
		stats[ v ] = player.stats[ i ]
	end
	player.stats = stats

	rules:setup_base_calcs( new_player )
	new_player.weapon = weapon:new( {name="Savior's Blade", damage=2, type='sword'} )

	return new_player
end


function player:info_dump()
	parameters = { "name", "image", "world_x", "world_y", "weapon", "speech", "roams", "faction", "stats" }
	local clone = {}

 	for i,v in ipairs( parameters ) do
		if self[ v ] ~= nil then
			clone[ v ] = self[ v ]
		end
	end

	clone.name = 'Ogmios'
	clone.speech = ""
	clone.roams = false
	return clone
end


function player:update_self( dt, TS, map, disp ) --HEY LISTEN
	local build, move = false,false

	if exploration_mode then
		build, move = self:move( map, disp, dt )
		local x,y = self:get_abs_pixel_position( disp )
		self.world_x , self.world_y = self:pt_to_tile( x , y )
	end

	return build, move
end



function player:draw( TS, scale )	--for health bar, max is 20px
	local draw_position_x, draw_position_y = (self.offset_x + self.pixel_x), (self.offset_y + self.pixel_y - 16)
	love.graphics.draw( self.image , self.icon , draw_position_x * scale , draw_position_y * scale , 0 , scale , scale )

	if self:is_injured() then
		local health_fill = math.ceil( (self.current_hp / self.max_hp) * 20 )
		local G = 200 * ( health_fill / 20 ); local R = 200 - G;
		set_color( R, G, 10, 255 )
		love.graphics.rectangle( 'fill', (draw_position_x+TS)*scale , draw_position_y*scale , 2*scale, health_fill*scale)
		set_color( 'white' )
	end

end


function player:attack( map )
	if self:attacking() > 0 then 
		ruleset:attack( self, map )
		self.is_attacking = self.is_attacking + 1 		--increase attack frame by 1

		if self.is_attacking > self.weapon:num_of_hits() then 	--if all frames are complete, set to 0
			self.is_attacking = 0
		end
	end
end


function player:move( map, disp , dt )
	local build,move = false,false
	local move_slice = math.ceil( dt * 100 )

	--if not attacking?
		local direction = { n=false , e=false , w=false , s=false }

		if love.keyboard.isDown( 'w' , 'up' ) then direction.n = true; end
		if love.keyboard.isDown( 'a' , 'left' ) then direction.w = true; end
		if love.keyboard.isDown( 'd' , 'right' ) then direction.e = true; end
		if love.keyboard.isDown( 's' , 'down' ) then direction.s = true; end

		for key,value in pairs( direction ) do
			if value then
				self.ori = tostring( key )
				--local npc = map:get_resident( self )  npc and love.keyboard.isDown('lshift') and npc:pushed( self.ori, map ) )
				local x,y = get_tile_at_ori( self )
				if self:world_passable( x*move_slice , y*move_slice , disp ) then--map:get_passable( self ) ) then
					if self:disp_should_move( disp , map.world , self.ori ) then
						disp:explore_move( x , y , move_slice )
						build = true

					elseif self:player_should_move() then
						self.pixel_x = self.pixel_x + x*move_slice; self.pixel_y = self.pixel_y + y*move_slice
						self.from_center_x = self.from_center_x + x*move_slice
						self.from_center_y = self.from_center_y + y*move_slice
						move = true
					end
				end
			end
		end
	--end
	return build, move
end


function player:add_to_party( map, disp, manager )
	target = map:get_resident( self:get_facing_tile( disp ) )
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

function player:get_party() return self.current_party end

function player:follow_orders()
	local order = self.current_order
	local path
	
	if order then
		if order.type == 'move' then
			path = get_path( { x=self.world_x , y=world_y } , { order.x , order.y } )
			for i,v in ipairs( path ) do
				print( i , v.x , v.y )
			end
		end
	end
end







--=============== HELPERS =========================
--[[]
function player:snap_x( disp )
	local pixel = self.pixel_x + self.offset_x*TS
	if pixel > TS/2 + ( self.world_x - disp.world_x )*TS then return 1
	elseif pixel < ( self.world_x - disp.world_x )*TS - TS/2 then return -1
	else return nil end
end
function player:snap_y( disp )
	local pixel = self.pixel_y + self.offset_y*TS
	if pixel > TS/2 + ( self.world_y - disp.world_y )*TS then return 1
	elseif pixel < ( self.world_y - disp.world_y )*TS - TS/2 then return -1
	else return nil end
end
function player:snap_to_grid( disp )
	local x = self:snap_x( disp )
	local y = self:snap_y( disp )

	local world_x = self.world_x + x
	local world_y = self.world_y + y

	return world_x , world_y
end--]]


function player:attacking( set, value )
	if set then self.is_attacking = value end
	return self.is_attacking
end
function player:is_injured() return ( self.current_hp < self.max_hp ) end
function player:is_critical() return ( self.current_hp < self.max_hp / 4 ) end

function player:disp_should_move( disp, world, ori )
	if ori == 'n' then
		return disp.world_y > 0 and self.from_center_y < 2 and self.from_center_y > -3
	elseif ori == 's' then
		return disp.world_y <= (world.height_tiles - (self.offset_y*2/TS)) and self.from_center_y < 2 and self.from_center_y > -3
	elseif ori == 'w' then
		return disp.world_x > 0 and self.from_center_x < 2 and self.from_center_x > -3
	elseif ori == 'e' then
		return disp.world_x <= (world.width_tiles - (self.offset_x*2/TS)) and self.from_center_x < 2 and self.from_center_x > -3
	end
end

function player:player_should_move()
	if self.ori == 'n' or self.ori == 's' then
		return self.from_center_y > -self.offset_y and self.from_center_y < self.offset_y - 1
	elseif self.ori == 'e' or self.ori == 'w' then
		return self.from_center_x > -self.offset_x and self.from_center_x < self.offset_x - 1
	end
end


function player:world_passable( mov_x , mov_y , disp )
	local pts = self:get_points( disp , mov_x , mov_y )


	tlx,tly = self:pt_to_tile( pts.x0 , pts.y0 )
	trx,try = self:pt_to_tile( pts.x1 , pts.y0 )
	blx,bly = self:pt_to_tile( pts.x0 , pts.y1 )
	brx,bry = self:pt_to_tile( pts.x1 , pts.y1 )

	if self.ori == 'n' then
		return map:get_passable( tlx , tly ) and map:get_passable( trx , try )
	elseif self.ori == 's' then
		return map:get_passable( blx , bly ) and map:get_passable( brx , bry )
	elseif self.ori == 'e' then
		return map:get_passable( trx , try ) and map:get_passable( brx , bry )
	elseif self.ori == 'w' then
		return map:get_passable( tlx , tly ) and map:get_passable( blx , bly )
	end

	return nil
end


function player:get_facing_tile( disp )
	local pts = self:get_points( disp )
	local half_pt, third_pt = TS/2 , math.floor( TS/3 )

	if self.ori == 'n' then
		return self:pt_to_tile( pts.x0+half_pt , pts.y0-half_pt )
	elseif self.ori == 's' then
		return self:pt_to_tile( pts.x0+half_pt , pts.y1+half_pt )
	elseif self.ori == 'e' then
		return self:pt_to_tile( pts.x1+half_pt , pts.y0+half_pt )
	elseif self.ori == 'w' then
		return self:pt_to_tile( pts.x0-half_pt , pts.y0+half_pt )
	end	
end


function player:get_points( disp , dx , dy )
	if not dx then dx = 0 end
	if not dy then dy = 0 end
	local x,y = self:get_abs_pixel_position( disp )
	return { x0=x+dx+self.width_margin , x1=x+TS+dx-self.width_margin , y0=y+dy+self.height_margin , y1=y+TS+dy-self.height_margin }
end

function player:get_abs_pixel_position( disp ) return self.pixel_x+self.offset_x+disp.pixel_x , self.pixel_y+self.offset_y+disp.pixel_y end	
function player:pt_to_tile( x , y ) return math.floor( x / 32 ) , math.floor( y / 32 ) end








return player