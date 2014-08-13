--Not sure...

package.path = "Ogmios/sub_objects/?.lua"
--all_npcs = require( "npc_load_file" )

manager = {}
manager.npcs = {}
manager.TS = 32


function manager:add( given_npc, create )	--can either create a new npc, or take a given npc and add it
	local new_npc

	if create then
		--self:create_random_npc()
	elseif given_npc then
		new_npc = npc:new( given_npc, self.TS ) 
		self.npcs[ new_npc.name ] = new_npc
	else print("No npc passed in...") end

end


function manager:load_npcs( file )
	load = require( file )
	for i,v in ipairs( load ) do
		self:add( v )
	end

end


function manager:draw( TS, scale, display )
	for k,v in pairs( self.npcs ) do
		v:draw( TS, scale, display )
	end
end


return manager