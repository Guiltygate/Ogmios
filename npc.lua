--[[
	Author: Eric Ames
	Last Updated: August 3rd
	Purpose: NPC object.
]]


npc = {}
npc.name = "None"
npc.image = nil
npc.quad = nil
npc.world_x = 0
npc.world_y = 0
npc.pixel_x = 0
npc.pixel_y = 0
npc.speech = "FHATAGHN"

function npc:new( name, image, quad, x, y, TS, speech)
	new_npc = {}
	setmetatable( new_npc, self )
	self.__index = self

	new_npc.name = name
	new_npc.image = image
	new_npc.quad = quad
	new_npc.world_x = x
	new_npc.world_y = y
	new_npc.speech = speech

	new_npc.pixel_x = new_npc.world_x * TS
	new_npc.pixel_y = new_npc.world_y * TS

	return new_npc
end


function npc:draw( TS, scale, display )
	love.graphics.draw( self.image, self.quad, ( self.pixel_x - display.xpos_pixel )*scale, ( self.pixel_y - display.ypos_pixel )*scale, 0, scale, scale )
end

function npc:move()
end

 return npc