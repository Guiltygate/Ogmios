--[[
	Author: Eric Ames
	Last Updated: August 3rd, 2014
	Purpose: O2 object for tiles in ogmios map creation.
]]

local tile = {}
tile.holds = nil
tile.is_passable = false
tile.is_ocpied = false
tile.type = "nope"
tile.all_names = { "path", "nope", "brick", "sea"}
tile.all_types = { path = { is_passable = true,	prob = 90},
				 nope 	= { is_passable = false,	prob = 0},
				 brick 	= { is_passable = false,	prob = 5}, 
				 sea 	= { is_passable = false,	prob = 5} }


function tile:new( type )
	new_tile = {}
	setmetatable( new_tile, self )
	self.__index = self
	new_tile.type = type
	new_tile.is_passable = self.all_types[ type ].is_passable
	new_tile.is_ocpied = false
	return new_tile
end


function tile:set_ocpied( npc, clear )
	if clear then
		self.holds = { name = "Nobody" }
		self.is_ocpied = false
	else
		self.holds = npc
		self.is_ocpied = true
	end
		
end


function tile:type() return self.type end

function tile:passable() return self.is_passable and not self.is_ocpied end

function tile:ocpied() return self.is_ocpied end

function tile:get_resident() return self.holds end

function tile:get_speech() return self.holds:get_speech() end


return tile