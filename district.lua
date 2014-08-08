--[[
	Author: Eric Ames
	Last Updated: August 3rd, 2014
	Purpose: O2 file for districts. Districts act as a kind of template-holder. The game world is composed of tiles, but
		to determine the placement of those tiles, the world is first built of different city districts. Each district has certain
		pre-built tile collections, called TEMPLATES, that can be assigned in the world. So, in summary,

		Here's an example: 

		Game World
			-District A (Slums)
				-Template A (Seedy bar)
				-Template B (Hovel)
				-Template C (Larger Hovel)
				-Template D (Refuse Heap)
			-District B (Market)
				-Template A (Shopping Avenue)
				-Template B (Bar)
				-Template C (Run-down market stall)
]]

district = {}
district.name = "None"
district.templates = {}

function district:new( name )
	new_dist = {}
	setmetatable( new_dist, self )
	self.__index = self
	new_dist.name = name
	return new_dist
end

function district:add( template )
	self.district[ template.name ] = template
end