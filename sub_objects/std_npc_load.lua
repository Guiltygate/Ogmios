-- Once this file is included as a "require" statement, the script at the bottom executes, creating an npc_table for each template here,
-- and packaging this into the all_npc table for loading by a manager.

--	Stat list:
--		Fang, Reflex, Lung, Instinct, Mind, Snout, Aura, Blood, Fur, Paw
--		Turn order is determined 50% by Reflex, 25% by Paw, and 25% by Snout
--		for now just reflex though...

all_npcs = {}

img_dir = "images/"
TS = 32
parameter = { "name", "image", "world_x", "world_y", "speech", "roams", "faction", "stats" }

local npcs = {
	{ "Elder Knight", "w_knight", 5, 5, "Hail!", true }
	,{ "Middling Knight", "w_knight", 12, 12, "Sire?", true }
	,{ "Younger Knight", "w_knight", 8, 16, ".....", true }
	,{ "Gabriel", "vagabond", 13, 3, "Prepare thyself.", true }
	--,{ "Flamer", "flame", 16, 8, "S'up?", false}

}


local role_templates = {
	w_knight = { stats={ fang=5, rflx=3, lung=2, inst=1, mind=1, snout=3, aura=1, blood=3, fur=1, paw=1 }, faction='ally' }
	,f_knight = {}
	,vagabond = { stats={ fang=3, rflx=4, lung=2, inst=1, mind=1, snout=3, aura=1, blood=2, fur=1, paw=3 }, faction='foe' }
}


function self_packager()
	template = nil

	for i,npc in ipairs( npcs ) do
		new_npc = {}

		for j,value in ipairs( parameter ) do
			if value == 'image' then
				new_npc.image = love.graphics.newImage( img_dir .. npc[ j ] .. ".png" )
				new_npc.image:setFilter( "nearest", "nearest" )
				template = npc[j]
			elseif j > 6 then
				new_npc[ value ] = role_templates[ template ][ value ]
			else
				new_npc[ value ] = npc[ j ]
			end

		end

		table.insert( all_npcs, new_npc )

	end
end




--=====Main execution======

self_packager()


return all_npcs