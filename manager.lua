--Not sure...

package.path = "Ogmios/sub_objects/?.lua"
--all_npcs = require( "npc_load_file" )

manager = {}
manager.npcs = {}
manager.npcs_by_rflx = {}
manager.TS = 32


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

function manager:remove_npc( npc ) manager.npcs[ npc.name ] = nil end


function manager:update( dt, TS, world, time )

	for i,name in ipairs( self.npcs_by_rflx ) do
		print( name )
		v = self.npcs[ name ];
		if v.roams then 
			v:roam( world, time, dt )
		end
		--[[
		if v:is_injured() and not v:is_critical() then
			v:attack_nearest_foe()
		end

		if v:is_critical() then
			--v:flee()
			print("Fleeing test.")
		end--]]

		v:update_pixel( dt, TS )

	end
	
end


function manager:load_npcs( file, player )
	local load = require( file )
	for i,v in ipairs( load ) do
		self:add_npc( true, v )
	end
	self:build_rflx( player )
	load = nil --just to ensure space is freed
end


function manager:draw( TS, scale, display, pc, map ) --draws all characters, including player
	local x = display.world_x;	local y = display.world_y


	for i=y,( y + display.height - 1 ) do
		for j=x, ( x + display.width - 1 ) do
			if map:get_tile( j, i ):is_ocpied() then
				map:get_resident( j, i ):draw( TS, scale, display )
			end
		end

		if pc.world_y == i then pc:draw( TS, scale ) end

	end

end









--=========== HELPERS ===========================


function manager:build_rflx( player ) --sets list of characters by speed ranking, for turn order
	max = find_max( self.npcs, 'stats', 'rflx' )
	repeat
		for k,v in pairs( self.npcs ) do	--add in npcs
			if v.stats.rflx == max then table.insert( self.npcs_by_rflx, v.name ) end
		end

		if pc.stats.rflx == max then table.insert( self.npcs_by_rflx, pc.name ) end	--add in player

		for k,v in pairs( pc.current_party ) do
			if v.stats.rflx == max then table.insert( self.npcs_by_rflx, v.name ) end	--add in party members
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