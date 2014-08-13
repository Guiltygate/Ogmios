-- Once this file is included as a "require" statement, the script at the bottom executes, creating an npc_table for each template here,
-- and packaging this into the all_npc table for loading by a manager.

all_npcs = {}

img_dir = "images/"
TS = 32
parameter = { "name", "image", "world_x", "world_y", "speech" }

local npcs = {
	{ "Elder Knight", "knight", 5, 5, "Hail!" },
	{ "Middling Knight", "knight", 12, 12, "Sire?" },
	{ "Younger Knight", "knight", 8, 16, "....." },
	{ "Gabriel", "knight", 13, 3, "Prepare thyself."}

}


function self_packager()

	for i,npc in ipairs( npcs ) do
		new_npc = {}

		for j,value in ipairs( npc ) do
			if j == 2 then
				new_npc[ parameter[ j ] ] = love.graphics.newImage( img_dir..npc[ j ]..".png" )
				new_npc.image:setFilter( "nearest", "nearest" )
				new_npc.quad = love.graphics.newQuad( 0, 0, TS, TS, new_npc.image:getWidth(), new_npc.image:getHeight() )
			else
				new_npc[ parameter[ j ] ] = npc[ j ]
			end

		end

		table.insert( all_npcs, new_npc )

	end
end

--=====Main execution======
--The moment

self_packager()


return all_npcs