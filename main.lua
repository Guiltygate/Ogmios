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
local disp_height = 11; local disp_width = 19;
local img_dir = "images/"
local start_coord = {x=10, y=6}

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
	map:build_tileset_batch( display, TS )
	manager:load_npcs( "std_npc_load", pc )



end


function love.draw()
	display:draw( TS, map.tileset_batch, scale )

	manager:draw( TS, scale, display, pc, map )

	display:draw_text()
	--display:draw_high_layer()			--add later, for passable tiles that are "sticking up", must be drawn over characters; e.g. walls, fog, etc.

	debug()

end

--[
function love.keypressed(key, isrepeat)

	if key == "e" then interact() end	--move interact as player.lua function

	if key == 'f' then pc:attacking( true ) end

	if key == 'v' then pc:add_to_party( map, display, manager ) end

end
--]]


function love.update( dt )
	build, move = pc:move( map, display )

	if move or build then display:show_text() end	--Clear text box if player moves

	manager:update( dt, TS, map, pc )

	if build then
		map:build_tileset_batch( display, TS )
		build = false
	end

	display:update_pixel( dt, TS, 6, pc )		--TODO decide on variable for disp / player / npc speed, don't leave magic

end

function interact()						--move as player.lua function

	if map:get_tile_obj( pc ):is_ocpied() then
		display:show_text( map:get_tile_resident( pc.ori, pc ).speech )
	end

end









--========== Utility Functions ================

function load_libraries()
	map = require( "map" );				tile = require( "tile" )
	aal = require( "AnAL" );			template = require( "area_template" )
	district = require( "district" );	player = require( "player" )
	npc = require( "npc" );				manager = require( "manager" )
	display = require( "disp" ):new( disp_height, disp_width, window_height, window_width )
end

function load_images()
	pc_image = love.graphics.newImage( img_dir.."fox.png" )
	pc_image:setFilter( "nearest" )
	pc_icon = love.graphics.newQuad( 0, 0, TS, TS, pc_image:getWidth(), pc_image:getHeight() )
	local offset = { x = ((display.width/2)+0.5), y = ((display.height/2)+0.5) }
	pc = player:new( pc_icon, pc_image, offset, TS )

	map_tileset = love.graphics.newImage( img_dir.."map_tile_placeholders2.png" )
	map_tileset:setFilter( "nearest" )
	map.tileset_batch = love.graphics.newSpriteBatch( map_tileset, (display.height + 2) * (display.width + 2) )

end


function debug()
	love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
  	love.graphics.print("Pos: "..display.world_x.." "..display.world_y, 10, 40)
  	love.graphics.print("Self Pos: "..pc.from_center_x.." "..pc.from_center_y, 10, 60)
  	love.graphics.print("Self World: "..pc.world_x.." "..pc.world_y, 10, 80)
end