--[[
	Author: Eric Ames
	Last Updated: August 3rd, 2014
	Purpose: O2 object for tiles in ogmios map creation.
]]

local tile = {}
tile.ocpied = false
tile.holds = { name = "Nobody" }
tile.passable = true
tile.type = "nope"
tile.all_names = { "path", "nope", "brick", "sea"}
tile.all_types = { path = { passable = true,	prob = 70},
				 nope 	= { passable = false,	prob = 0},
				 brick 	= { passable = false,	prob = 30}, 
				 sea 	= { passable = false,	prob = 0} }


function tile:new( type )
	new_tile = {}
	setmetatable( new_tile, self )
	self.__index = self
	new_tile.type = type
	new_tile.passable = self.all_types[ type ].passable
	return new_tile
end


function tile:set_ocpied( npc )
	self.holds = npc or { name = "Nobody" }
	if npc then self.ocpied = true end
end


function tile:is_ocpied() return self.ocpied end

function tile:type() return self.type end

function tile:pass() return (self.passable and not self.ocpied) end


return tile