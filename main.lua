--[[

	Author: Eric Ames
	Last Updated: August 3rd, 2014
	Purpose: main lua file for Ogmios game project.

	General rule of thumb: all dimensions are in pixels or tiles.
	Tiles are 32 x 32 pixels, stored in the TS variable.
	display is a table that holds the dimensions of the PORTION of the TOTAL WORLD currently being shown in TILES
	pc is player character
	window is the actual size of the game window, in pixels. It's only used to build a scale factor, so the game will
		run the same regardless of the player's choice of window size.

	at some point, need to seperate Map and Display as seperate O2s, to keep main.lua clean.

--]]

--============ Globals =================

local window_height, window_width			--dimensions of the window in pixels as chosen by player
local TS = 32
local world_height_tiles = 360; local world_width_tiles = 640
local world_height = world_height_tiles * TS; local world_width = world_width_tiles * TS
local build = false
local disp_height = 18; local disp_width = 32;
local img_dir = "images/"

--======================================

function love.load()							--as far as I can tell, these are all global.
	window_height = love.window.getHeight();			window_width = love.window.getWidth();	--window size
	load_libraries()

	scale = window_height / ( display.height * TS )
	offset_x = display.width / 2;						offset_y = display.height / 2 			--TILES

	math.randomseed( os.time() )				--set random seed value for map generation

	load_images()

	tile_names = tile.all_names
	map.get_type( tile_names )		--Grab generation probabilities for map tiles
	map.load_map_tiles( map_tileset:getWidth(), map_tileset:getHeight(), TS, tile_names )
	world = map.play_god( world_width_tiles, world_height_tiles )
	build_tileset_batch()


	--
	knight = npc:new( "Elder Knight", knight_image, knight_icon, 5, 5, TS, "Hail!")
	print( world[ 5 ][ 5 ]:set_ocpied( knight ) )

	knight1 = npc:new( "Middling Knight", knight_image, knight_icon, 12, 12, TS, "Sire?")
	print( world[ 12 ][ 12 ]:set_ocpied( knight1 ) )

	knight2 = npc:new( "Youngest Knight", knight_image, knight_icon, 8, 16, TS, "Fox!")
	print( world[ 8 ][ 16 ]:set_ocpied( knight2 ) )
	--


end


function love.draw()
	love.graphics.draw( tileset_batch, -display.xpos_pixel*scale , -display.ypos_pixel*scale , 0, scale, scale )			--Now with SpriteBatch, this draws the entire world!

	pc:draw( TS, scale )
	knight:draw( TS, scale, display )
	knight1:draw( TS, scale, display )
	knight2:draw( TS, scale, display )
	display:draw_text()
	--npcs:draw()

  	love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
  	love.graphics.print("Pos: "..display.xpos.." "..display.ypos, 10, 40)
  	love.graphics.print("Self Pos: "..pc.from_center_x.." "..pc.from_center_y, 10, 60)

end


function love.keypressed(key, isrepeat)
	build = false
	move = false

	display.xpos, display.ypos, build, move = pc:move( key, world, display.xpos, display.ypos, world_height_tiles, world_width_tiles )

	if move or build then display:show_text() end


	if key == 'u' and scale < 4 then scale = scale * 1.5
   	elseif key == 'i' and scale > 1 then scale = scale / 1.5
   	end

	if key == "e" then interact() end	--move interact as player.lua function

end



function love.update( dt )
	pc:update_loc( display.xpos, display.ypos)
	pc:pixel_move( dt, TS )
	
	if build then
		build_tileset_batch()
		build = false
	end

	display:update( dt, TS, 10 )

end


function build_tileset_batch()			--used to more efficiently store tiles for drawing - GREATLY increases FPS!  
	tileset_batch:bind()
	tileset_batch:clear()

	for i=-1,( display.width  ) do
		for j=-1,( display.height ) do
			x_map_pos = i + display.xpos
			y_map_pos = j + display.ypos

			if in_bounds( x_map_pos, y_map_pos ) then		--Check added b/c of drawing a +/-1 buffer for x and y
				tileset_batch:add( map.tile_images[ world[ x_map_pos ][ y_map_pos ].type ], x_map_pos*TS, y_map_pos*TS )
			end
		end
	end
	tileset_batch:unbind()
end


function interact()						--move as player.lua function

	if world_get( pc.ori, pc ):is_ocpied() then
		display:show_text( get_resident( pc.ori, pc ).speech )
	end

end



--========== Utility Functions ================

function load_libraries()
	map = require( "map" );				tile = require( "tile" )
	aal = require( "AnAL" );			template = require( "area_template" )
	district = require( "district" );	player = require( "player" )
	npc = require( "npc" );				
	display = require( "disp" ):new( disp_height, disp_width, window_height, window_width )
end

function load_images()
	pc_image = love.graphics.newImage( img_dir.."fox.png" )
	pc_image:setFilter( "nearest", "nearest" )
	pc_icon = love.graphics.newQuad( 0, 0, TS, TS, pc_image:getWidth(), pc_image:getHeight() )
	pc = player:new( pc_icon, pc_image, display.width / 2, display.height / 2, TS )

	map_tileset = love.graphics.newImage( img_dir.."map_tile_placeholders2.png" )
	map_tileset:setFilter( "nearest", "nearest")
	tileset_batch = love.graphics.newSpriteBatch( map_tileset, (display.height + 2) * (display.width + 2) )

	knight_image = love.graphics.newImage( img_dir.."knight.png" )	
	knight_image:setFilter( "nearest", "nearest")
	knight_icon = love.graphics.newQuad( 0, 0, TS, TS, knight_image:getWidth(), knight_image:getHeight() )
end

function in_bounds( x, y )
	return ( x < world_width_tiles and x >= 0 and y < world_height_tiles and y >= 0 )
end

function world_get( dir, char )			--move as map.world.lua functoin?
	if dir == 'n' then
		return world[ char.world_x ][ char.world_y - 1]
	elseif dir == "s" then
		return world[ char.world_x ][ char.world_y + 1]
	elseif dir == "w" then
		return world[ char.world_x - 1][ char.world_y ]
	elseif dir == "e" then
		return world[ char.world_x + 1][ char.world_y ]
	end
end

function get_resident( dir, char )		--move as map.world.lua function?
	value = world_get( dir, char ).holds
	print( value.speech )
	return value
end