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

	at some point, need to seperate Map, to keep main.lua clean.

--]]

--============ Globals =================

local window_height, window_width			--dimensions of the window in pixels as chosen by player
local TS = 32
local chosen_world_height = 360; local chosen_world_width = 640
local build = false
local disp_height = 18; local disp_width = 32;
local img_dir = "images/"

--======================================

function love.load()							--as far as I can tell, these are all global.
	window_height = love.window.getHeight();			window_width = love.window.getWidth();	--window size

	load_libraries()
	love.graphics.setNewFont( 25 )

	scale = window_height / ( display.height * TS )

	math.randomseed( os.time() )				--set random seed value for map generation

	load_images()

	tile_names = tile.all_names
	map.get_type( tile_names )		--Grab generation probabilities for map tiles
	map.load_map_tiles( map_tileset:getWidth(), map_tileset:getHeight(), TS, tile_names )

	map:create_world( chosen_world_width, chosen_world_height )
	map:build_tileset_batch( display, TS 
		)
	npc_manager:load_npcs( "std_npc_load" )


	--npc_manager:add( false, knight ); npc_manager:add( false, knight1 ); npc_manager:add( false, knight2 );
	--


end


function love.draw()
	display:draw( TS, map.tileset_batch, scale )

	pc:draw( TS, scale )
	display:draw_text()
	npc_manager:draw( TS, scale, display )

	debug()

end


function love.keypressed(key, isrepeat)
	build = false
	move = false

	display.xpos, display.ypos, build, move = pc:move( key, map.world, display.xpos, display.ypos, map.world.height_tiles, map.world.width_tiles )

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
		map:build_tileset_batch( display, TS )
		build = false
	end

	display:update( dt, TS, 10 )

end

function interact()						--move as player.lua function

	if map:get_tile_obj( pc.ori, pc ):is_ocpied() then
		display:show_text( map:get_tile_resident( pc.ori, pc ).speech )
	end

end









--========== Utility Functions ================

function load_libraries()
	map = require( "map" );				tile = require( "tile" )
	aal = require( "AnAL" );			template = require( "area_template" )
	district = require( "district" );	player = require( "player" )
	npc = require( "npc" );				npc_manager = require( "manager" )
	display = require( "disp" ):new( disp_height, disp_width, window_height, window_width )
end

function load_images()
	pc_image = love.graphics.newImage( img_dir.."fox.png" )
	pc_image:setFilter( "nearest", "nearest" )
	pc_icon = love.graphics.newQuad( 0, 0, TS, TS, pc_image:getWidth(), pc_image:getHeight() )
	pc = player:new( pc_icon, pc_image, display.width / 2, display.height / 2, TS )

	map_tileset = love.graphics.newImage( img_dir.."map_tile_placeholders2.png" )
	map_tileset:setFilter( "nearest", "nearest")
	map.tileset_batch = love.graphics.newSpriteBatch( map_tileset, (display.height + 2) * (display.width + 2) )

end


function debug()
	love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
  	love.graphics.print("Pos: "..display.xpos.." "..display.ypos, 10, 40)
  	love.graphics.print("Self Pos: "..pc.from_center_x.." "..pc.from_center_y, 10, 60)
end