--[[
	Author: Eric Ames
	Last Updated: August 3rd, 2014
	Purpose: Deals with map generation and other pre-game world setup.

			Here's an example of future world generation: 

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


package.path = "Ogmios/sub_objects/?.lua"


local map = {}
local map_settings = {	90, 0, 5, 5 } --enter probabilities in order corresponding to tile names from main.lua
local TS = 32
map.config = {}
map.tile_images = {}
--world = require("world"):new()
map.world = {}


--============ Actual Functions ===========================

function map.get_type( tile_names )
	local sum = 0;

	for i,v in ipairs( tile_names ) do		--tie probs and tile types together.
		map.config[ v ] = map_settings[ i ]
	end

	table.sort( map.config )

	for k,v in pairs( map.config ) do
		sum = sum + v
		map.config[ k ] = sum
	end

end


function map.load_map_tiles( tileset_width_in_pixels, tileset_height_in_pixels, tile_size, tile_names )
	local tileset_height_in_tiles = tileset_height_in_pixels / TS
	local tileset_width_in_tiles = tileset_width_in_pixels / TS

		for y=0,tileset_height_in_tiles-1 do			--for each tile in height and width, load the 16x16 quad
			for x=0,tileset_width_in_tiles-1 do

				index = ( y * 4 ) + x
				if index >= #tile_names then
					break
				else
					local tile = tile_names[ index + 1 ]
					map.tile_images[ tile ] = love.graphics.newQuad( x*TS, y*TS, tile_size, tile_size,
																 tileset_width_in_pixels, tileset_height_in_pixels )
				end

			end
		end
end


function map:create_world( world_width_in_tiles, world_height_in_tiles )
	local tile = require( "tile" )

	for i=0,world_width_in_tiles-1 do
		self.world[ i ] = {}
		for j=0,world_height_in_tiles-1 do
			choice = math.random() * 100
			for k,v in pairs( map.config ) do
				if choice <= v then 
					self.world[ i ][ j ] = tile:new( k )
					break
				end
			end

			if i == 0 or j == 0 or i == world_width_in_tiles-1 or j == world_height_in_tiles-1 then 			--prototype code for boundary marking
				self.world[ i ][ j ] = tile:new( "sea" )
			end

		end
	end

	self.world.height_tiles = world_height_in_tiles
	self.world.width_tiles = world_width_in_tiles

end


function map:build_tileset_batch( display, TS )			--used to more efficiently store tiles for drawing - GREATLY increases FPS!  
	self.tileset_batch:bind()
	self.tileset_batch:clear()

	for i=-1,( display.width  ) do
		for j=-1,( display.height ) do
			x_map_pos = i + display.xpos
			y_map_pos = j + display.ypos

			if self:in_bounds( x_map_pos, y_map_pos ) then		--Check added b/c of drawing a +/-1 buffer for x and y
				self.tileset_batch:add( self.tile_images[ self.world[ x_map_pos ][ y_map_pos ].type ], x_map_pos*TS, y_map_pos*TS )
			end
		end
	end
	self.tileset_batch:unbind()
end


function map:get_tile_obj( dir, char )			--move as map.world.lua functoin?
	if dir == 'n' then
		return self.world[ char.world_x ][ char.world_y - 1]
	elseif dir == "s" then
		return self.world[ char.world_x ][ char.world_y + 1]
	elseif dir == "w" then
		return self.world[ char.world_x - 1][ char.world_y ]
	elseif dir == "e" then
		return self.world[ char.world_x + 1][ char.world_y ]
	end
end



function map:get_tile_resident( dir, char )		--move as map.world.lua function?
	value = self:get_tile_obj( dir, char ).holds
	return value
end


function map:in_bounds( x, y )
	return ( x < self.world.width_tiles and x >= 0 and y < self.world.height_tiles and y >= 0 )
end



function map:set_tile_ocpied( npc )
	if npc then map.world[ npc.world_x ][ npc.world_y ]:set_ocpied( npc ) end
end



return map