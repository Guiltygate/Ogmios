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


local map = {}
local map_settings = {	90, 0, 5, 5 } --enter probabilities in order corresponding to tile names from main.lua
local TS = 32
map.config = {}
map.tile_images = {}
--[[
local map_settings = {}
count = 1

for k,v in pairs( tile.all_type ) do
	map_settings[ count ]
--]]

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


function map.play_god( world_width_in_tiles, world_height_in_tiles )
	local world = {}
	local tile = require( "tile" )

	for i=0,world_width_in_tiles-1 do
		world[ i ] = {}
		for j=0,world_height_in_tiles-1 do
			choice = math.random() * 100
			for k,v in pairs( map.config ) do
				if choice <= v then 
					world[ i ][ j ] = tile:new( k )
					break
				end
			end

			if i == 0 or j == 0 or i == world_width_in_tiles-1 or j == world_height_in_tiles-1 then 			--prototype code for boundary marking
				world[ i ][ j ] = tile:new( "sea" )
			end

		end
	end
	return world
end

return map