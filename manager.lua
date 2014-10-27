--[[
	Manager for npcs. Loads them at beginning, restricts them to acting in order, etc.
	Might be expanded for weapons, haven't decided.
]]



package.path = "Ogmios/sub_objects/?.lua"
npc_loader = require( "npc_loader" )

manager = {}
manager.npcs = {}
manager.npcs_by_rflx = {}
manager.TS = 32
manager.weapon_list = {}
manager.player_clone = nil


function manager:add_npc( create, given_npc )	--can either create a new npc, or take a given npc and add it
	local new_npc
	if not given_npc and not create then self.npcs = {}; print("Clearing...") end	--if no npc, clear current list

	if create and not given_npc then
		--self:create_random_npc()
	elseif given_npc and not create then
		self.npcs[ given_npc.name ] = given_npc
	else
		new_npc = npc:new( given_npc, self.TS ) 
		self.npcs[ new_npc.name ] = new_npc				--npcs sorted by name
	end
end


function manager:remove_npc( npc , map )
	map:set_tile_ocpied( npc , true )
	self.npcs[ npc.name ] = nil
end


function manager:update( dt, TS, map, disp )
	local build, move, tmp1, tmp2

	for i,name in ipairs( self.npcs_by_rflx ) do
		v = self.npcs[ name ] 							--Give each NPC a weapon from the manager's list
		tmp1, tmp2 = v:update_self( dt, TS, map, disp, self.npcs.savior )
		if tmp1 then build = tmp1 end; if tmp2 then move = tmp2 end;--one of these chars is the pc, and we need only him to update build/move
	end

	return build, move
end


function manager:load_npcs( file, player )
	load = npc_loader:package( file , stats_master )			--call npc_loader and package all npcs for creation

	for i,v in ipairs( load ) do
		v.weapon = self.weapon_list[ v.weapon ]
		self:add_npc( true, v )					--Create npcs from flatfile
	end

	self:add_npc( false, player )				--add player to "npc" list

	for k,v in pairs( player.current_party ) do	--add in npcs in player's current party
		self:add_npc( false, value )
	end

	self:build_rflx()
	load = nil --just to ensure space is freed
end


function manager:load_weapons()
	local loaded_wpns = require( "weapon_loader" )

	for i,v in ipairs( loaded_wpns ) do
		new_wpn = weapon:new( v )
		self.weapon_list[ new_wpn.name ] = new_wpn
	end
end


function manager:draw( TS, scale, display, pc, map ) --draws all characters, including player
	local x = display.world_x;	local y = display.world_y

	if y > 0 then y = y - 1 end	--for drawing coming-in-to-sight npcs at -y
	if x > 0 then x = x - 1 end --same, -x

	for i=y,( y + display.height + 2 ) do
		if i >= map.world.height_tiles then i = map.world.height_tiles - 1 end	--to keep from looking for npcs beyond the edge
		for j=x, ( x + display.width + 1 ) do
			if j >= map.world.width_tiles then j = map.world.width_tiles - 1 end
			target = map:get_resident( j, i )
			if target then
				target:draw( TS, scale, display )
			end
		end

		if exploration_mode and pc.world_y == i then pc:draw( TS, scale ) end

	end
end

function manager:modify_player_npc( pc , map )
	if pc then
		self.player_clone = pc:info_dump()
		self:add_npc( true , self.player_clone )
		self:build_rflx()
	else
		self:remove_npc( self.player_clone , map )
		self:build_rflx()
	end
	--print( self.npcs[ 'savior' ])
end




--=========== HELPERS ===========================


function manager:build_rflx( player ) --sets list of characters by speed ranking, for turn order
	self.npcs_by_rflx = {}
	max = find_max( self.npcs, 'stats', 'Reflex' )
	repeat
		for k,v in pairs( self.npcs ) do	--add in npcs

			if v.stats.Reflex == max then table.insert( self.npcs_by_rflx, v.name ) end
		end

		max = max - 1
	until max == 0
end


function find_max( passed_table, param1, param2 )
	max = 0
	for k,v in pairs( passed_table ) do
		if v[ param1 ][ param2 ] > max then
			max = v[ param1 ][ param2 ]
		end
	end
	return max
end



return manager