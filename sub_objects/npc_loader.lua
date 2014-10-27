-- Once this file is included as a "require" statement, the script at the bottom executes, creating an npc_table for each template here,
-- and packaging this into the all_npc table for loading by a manager.

--	Stat list:
--		Fang, Reflex, Lung, Instinct, Mind, Snout, Aura, Blood, Fur, Paw
--		Turn order is determined 50% by Reflex, 25% by Paw, and 25% by Snout
--		for now just reflex though...

loaded_npcs = {}
npc_loader = {}


img_dir = "images/"
TS = 32
npc_loader.parameter = { "name", "image", "world_x", "world_y", "weapon", "speech", "roams", "faction", "stats" }
--add in mood at some point?

--Fang, Reflex, Lung, Instinct, Mind, Snout, Aura, Blood, Fur, Paw
npc_loader.role_templates = {
	w_knight = { stats={ 5, 3, 3, 1, 1, 3, 1, 3, 1, 1 }, faction='ally' }
	,f_knight = {}
	,vagabond = { stats={ 3, 4, 2, 1, 1, 3, 1, 4, 1, 3 }, faction='foe' }
}


function npc_loader:package( file , stats_master )
	template = nil
	npcs = require( file )

	for i,npc in ipairs( npcs ) do
		new_npc = {}

		for j,value in ipairs( self.parameter ) do
			if value == 'image' then
				new_npc.image = love.graphics.newImage( img_dir .. npc[ j ] .. ".png" )
				new_npc.image:setFilter( "nearest", "nearest" )
				template = npc[j]
			elseif j > 7 then
				new_npc[ value ] = self.role_templates[ template ][ value ]
				if j == 9 then self:package_stats( new_npc , stats_master ) end
			else
				new_npc[ value ] = npc[ j ]
			end
		end
		table.insert( loaded_npcs, new_npc )
	end

	return loaded_npcs
end


function npc_loader:package_stats( npc , stats_master )
	local stats = {}

	for i,v in ipairs( stats_master ) do
		stats[ v ] = npc.stats[ i ]
	end
	npc.stats = stats
end




return npc_loader