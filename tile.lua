--[[
	Author: Eric Ames
	Last Updated: August 3rd, 2014
	Purpose: O2 object for tiles in ogmios map creation.
]]

local tile = {}
tile.holds = { name = "Nobody" }
tile.passable = true
tile.type = "nope"
tile.all_names = { "path", "nope", "brick", "sea"}
tile.all_types = { path = { passable = true,	prob = 90},
				 nope 	= { passable = false,	prob = 0},
				 brick 	= { passable = false,	prob = 5}, 
				 sea 	= { passable = false,	prob = 5} }


function tile:new( type )
	new_tile = {}
	setmetatable( new_tile, self )
	self.__index = self
	new_tile.type = type
	new_tile.passable = self.all_types[ type ].passable
	return new_tile
end


function tile:set_ocpied( npc, clear )
	if clear then
		self.holds = { name = "Nobody" }
		self.passable = true
	else
		self.holds = npc
		self.passable = false
	end
		
end


function tile:type() return self.type end

function tile:passable() return self.passable end

function tile:get_resident() return self.holds end


return tile