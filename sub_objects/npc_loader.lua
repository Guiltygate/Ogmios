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


npc_loader.role_templates = {
	w_knight = { stats={ fang=5, rflx=3, lung=3, inst=1, mind=1, snout=3, aura=1, blood=3, fur=1, paw=1 }, faction='ally' }
	,f_knight = {}
	,vagabond = { stats={ fang=3, rflx=4, lung=2, inst=1, mind=1, snout=3, aura=1, blood=4, fur=1, paw=3 }, faction='foe' }
}


function npc_loader:package( file )
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
			else
				new_npc[ value ] = npc[ j ]
			end
		end
		table.insert( loaded_npcs, new_npc )
	end

	return loaded_npcs
end




return npc_loader