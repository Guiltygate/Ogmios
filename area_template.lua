
--[[
	Author: Eric Ames
	Last Updated: August 3rd, 2014
	Purpose: O2 file for templates. Templates are pre-set 2D tables, defining things such as buildings, roads, 
		cemetaries, etc. Future world generation will build using these preset templates, along with districts.
]]

area_template = {}
area_template.name = "None"
area_template.grid = {}

function area_template:new( name, grid )
	new_temp = {}
	setmetatable( new_temp, self )
	self.__index = self
	new_temp.name = name
	new_temp.grid = grid

	return new_temp
end