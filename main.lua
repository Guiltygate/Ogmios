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

--]]

--============ Globals =================

local window_height, window_width			--dimensions of the window in pixels as chosen by player
local TS = 32
local world_height_tiles = 360; local world_width_tiles = 640
local world_height = world_height_tiles * TS; local world_width = world_width_tiles * TS
local display = { xpos = 0, ypos = 0, xpos_pixel = 0, ypos_pixel = 0, height = 18, width = 32, offset_x = 0, offset_y = 0 }	
local current_world_tile_x, current_world_tile_y
local build = false
local img_dir = "images/"

--======================================

function love.load()							--as far as I can tell, these are all global.
	load_libraries()

	window_height = love.window.getHeight();			window_width = love.window.getWidth();	--window size
	scale = window_height / ( display.height * TS )
	speech_bubble = { ypos = window_height - window_height / 6, xpos = window_width / 4, show = false, text = "",
			 width = (window_width/2), height = (window_height/4) }
	offset_x = display.width / 2;						offset_y = display.height / 2 			--TILES

	math.randomseed( os.time() )				--set random seed value for map generation

	load_images()

	tile_names = tile.all_names
	map.get_type( tile_names )		--Grab generation probabilities for map tiles
	map.load_map_tiles( map_tileset:getWidth(), map_tileset:getHeight(), TS, tile_names )
	world = map.play_god( world_width_tiles, world_height_tiles )
	build_tileset_batch()

	knight = npc:new( "Elder Knight", knight_image, knight_icon, 5, 5, TS, "Hail!")
	print( world[ 5 ][ 5 ]:set_ocpied( knight ) )

	knight1 = npc:new( "Middling Knight", knight_image, knight_icon, 12, 12, TS, "Sire?")
	print( world[ 12 ][ 12 ]:set_ocpied( knight1 ) )

	knight2 = npc:new( "Youngest Knight", knight_image, knight_icon, 8, 16, TS, "Fox!")
	print( world[ 8 ][ 16 ]:set_ocpied( knight2 ) )


end


function love.draw()
	love.graphics.draw( tileset_batch, -display.xpos_pixel*scale , -display.ypos_pixel*scale , 0, scale, scale )			--Now with SpriteBatch, this draws the entire world!
	pc:draw( TS, scale )
	knight:draw( TS, scale, display )
	knight1:draw( TS, scale, display )
	knight2:draw( TS, scale, display )
  	love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
  	love.graphics.print("Pos: "..display.xpos.." "..display.ypos, 10, 40)
  	love.graphics.print("Self Pos: "..pc.from_center_x.." "..pc.from_center_y, 10, 60)

  	if speech_bubble.show then
  		love.graphics.rectangle( "line", speech_bubble.xpos, speech_bubble.ypos,  speech_bubble.width, speech_bubble.height)
  		love.graphics.print( speech_bubble.text, speech_bubble.xpos + 50, speech_bubble.ypos+50 )
  	end

end


function love.keypressed(key, isrepeat)
	build = false
	move = false

	display.xpos, display.ypos, build, move = pc:move( key, world, display.xpos, display.ypos, world_height_tiles, world_width_tiles )

	if move or build then
		speech_bubble.show = false
	end


	if key == 'u' and scale < 4 then scale = scale * 1.5
   	elseif key == 'i' and scale > 1 then scale = scale / 1.5
   	end

	if key == "j" then	--interact_pc()
	end

	if key == "o" then
		interact()
	end

end



function love.update(dt)
	pc:update_loc( display.xpos, display.ypos)
	pc:pixel_move( dt, TS )
	
	if build then
		build_tileset_batch()
		build = false
	end

	display.xpos_pixel = display.xpos_pixel - ( (display.xpos_pixel - (display.xpos*TS) ) * dt * 10 )
	display.ypos_pixel = display.ypos_pixel - ( (display.ypos_pixel - (display.ypos*TS) ) * dt * 10 )


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


function interact()
	if pc.ori == 'n' and world[ pc.world_x ][ pc.world_y - 1 ]:is_ocpied() then
		speech_bubble.text = world[ pc.world_x ][ pc.world_y - 1 ].holds.speech
		speech_bubble.show = true

	elseif pc.ori == 's' and world[ pc.world_x ][ pc.world_y + 1 ]:is_ocpied() then
		speech_bubble.text = world[ pc.world_x ][ pc.world_y + 1 ].holds.speech
		speech_bubble.show = true

	elseif pc.ori == 'w' and world[ pc.world_x - 1][ pc.world_y ]:is_ocpied() then
		speech_bubble.text = world[ pc.world_x - 1][ pc.world_y ].holds.speech
		speech_bubble.show = true

	elseif pc.ori == 'e' and world[ pc.world_x + 1][ pc.world_y ]:is_ocpied() then
		speech_bubble.text = world[ pc.world_x + 1][ pc.world_y ].holds.speech
		speech_bubble.show = true
	end
end




--========== Utility Functions ================

function load_libraries()
	map = require( "map" );				tile = require( "tile" )
	aal = require( "AnAL" );			template = require( "area_template" )
	district = require( "district" );	player = require( "player" )
	npc = require( "npc" )
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

function in_bounds( x_map_pos, y_map_pos )
	return ( x_map_pos < world_width_tiles and x_map_pos >= 0 and y_map_pos < world_height_tiles and y_map_pos >= 0 )
end
