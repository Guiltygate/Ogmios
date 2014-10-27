--[[

	Author: Eric Ames
	Last Updated: September 23rd, 2014
	Purpose: main lua file for Ogmios game project.

	General rule of thumb: all dimensions are in pixels or tiles.
	Tiles are 32 x 32 pixels, stored in the TS variable.
	display is a table that holds the dimensions of the PORTION of the TOTAL WORLD currently being shown in TILES
	pc is player character, which is treated as an npc by the manager.
	window is the actual size of the game window, in pixels. It's only used to build a scale factor, so the game will
		run the same regardless of the player's choice of window size.

	at some point, need to seperate Map, to keep main.lua clean.

--]]

--============ Globals =================

local window_height, window_width			--dimensions of the window in pixels as chosen by player
TS = 32; raw_TS = nil
pc = nil
local chosen_world_height = 30; local chosen_world_width = 30
local build = false
local disp_height = 11; local disp_width = 19;
local img_dir = "images/"
local start_coord = {x=10, y=6}

local talking = false

npx, npy = 0,0
default_font = 25

stats_master = { 'Fang' , 'Reflex' , 'Lung' , 'Instinct' , 'Mind' , 'Snout' , 'Aura' , 'Blood' , 'Fur' , 'Paw' }

--Game Mode Flags
combat_mode = false
exploration_mode = true
orders_phase = false 		--part of combat_mode
resolution_phase = false	--part of combat_mode

--======================================

function love.load()							--initial values and files to load for gameplay
	load_libraries()

	--Display Settings
	window_height = love.window.getHeight();			window_width = love.window.getWidth();	--window size
	display = disp_lib:new( disp_height, disp_width, window_height, window_width )
	scale = window_height / ( display.height * TS )
	raw_TS = TS*scale
	load_images()

	--World Creation
	math.randomseed( os.time() )	--set random seed value for map generation
	tile_names = tile.all_names
	map.get_type( tile_names )		--Grab generation probabilities for map tiles
	map.load_map_tiles( map_tileset:getWidth(), map_tileset:getHeight(), tile_names )
	map:create_world( chosen_world_width, chosen_world_height )
	map:build_tileset_batch( display )

	--Load NPCs and weapon types
	manager:load_weapons()
	manager:load_npcs( "test_npcs", pc )

	--Random Settings (global fonts )
	speech_font = love.graphics.setNewFont( 25 )
	sidebar_font = love.graphics.setNewFont( 18 )
	info_font = love.graphics.setNewFont( 20 )
	love.keyboard.setKeyRepeat( true )


	--path-finding tests, will be removed
	local construct = { pt1={x=1 , y=1} , pt2={x=14 , y=5} }
	local path = find_path( construct.pt1 , construct.pt2 , {} , 0 )
	local total = math.abs( construct.pt1.x - construct.pt2.x ) + math.abs( construct.pt1.y - construct.pt2.y )
	if path then print( "Should be "..total..", is "..#path )
	else print( "Couldn't find a path! " ) end

	--for i,v in ipairs( path ) do
	--	print( i , v.x , v.y )
	--end


end


function love.draw()
	display:draw( TS, map.tileset_batch, scale , pc )	--first draw the background tiles, and then any highlights
	manager:draw( TS, scale, display, pc, map )		--then the characters, starting with the furthest back...
	--display:draw_high_layer()	--add later, for passable tiles that are "sticking up", must be drawn over characters; e.g. walls, fog, etc.
	--manager:draw_text()
	display:draw_gui( pc )								--and finally draw the message window

	debug()
end


function love.update( dt )

	if not orders_phase then
		build, move = manager:update( dt, TS, map, display, collision_world )
	end

	if combat_mode then 
		build = display:combat_move( map , dt , pc )
	end

	if ( move or build ) and exploration_mode then 
		display:show_text_box()
		if talking_npc then talking_npc:talking( pc , true ) end
		talking_npc = nil
	end

	if build then
		map:build_tileset_batch( display, TS )
		build = false 
	end

	--if orders_phase then love.timer.sleep( 0.05 ) end
end


function interact()						--move as player.lua function
	local coorx,coory = pc:get_facing_tile( display )
	talking_npc = map:get_resident( coorx , coory )

	if talking_npc then
		talking_npc:talking( pc )
		display:show_text_box( map:get_tile_text( coorx , coory ) )
	end
end






--========= Keyboard and Mouse IO ===============
function love.keypressed(key, isrepeat)

	if key == 'q' then
		if exploration_mode then
			exploration_mode = false
			combat_mode = true
			orders_phase = true
			manager:modify_player_npc( pc )
		elseif orders_phase then
			orders_phase = false
			resolution_phase = true
		elseif resolution_phase then
			exploration_mode = true
			orders_phase = false
			combat_mode = false
			resolution_phase = false
			manager:modify_player_npc( false , map )
		end 
	end

	if key == 'escape' then love.event.quit() end

	if exploration_mode then
		if key == "e" then interact() end	--move interact as player.lua function
		--if key == 'f' then pc:attacking( true, 1 ) end
		if key == 'v' then pc:add_to_party( map, display, manager ) end
	elseif combat_mode then
		--stuff
	end
end

function love.mousepressed( x , y , button )
end

function love.mousereleased( x , y , button )
	local x = math.ceil( x / scale )	--translates the raw pixel value to the display pixel value for all mouse events.
	local y = math.ceil( y / scale )
	local world_x = math.floor( ( x + display.pixel_x ) / TS )
	local world_y = math.floor( ( y + display.pixel_y ) / TS )
	local tile = map:get_tile( world_x , world_y )

	if exploration_mode then
		--stuff
	elseif combat_mode and orders_phase and tile then
		if button == 'l' then display:select_tile( world_x , world_y , tile ) end--should display tile stats, and the housed unit if there is one
		if button == 'r' then
			local npc = display:get_selected_npc()
			if npc and npc:is_friendly( pc ) then npc:new_order( tile , world_x , world_y ) end
		end
	end
end











--========== Utility Functions ================

function load_libraries()
	map = 		require( "map" );		tile = 		require( "tile" )
	aal = 		require( "AnAL" );		template = 	require( "area_template" )
	district = 	require( "district" );	player = 	require( "player" )
	npc = 		require( "npc" );		manager = 	require( "manager" )
	rules = 	require( "ruleset" );	weapon = 	require( "weapon" )
	bump = require( "bump" )
	disp_lib = 	require( "disp" )
end

function load_images()
	pc_image = love.graphics.newImage( img_dir.."fox.png" )
	pc_image:setFilter( "nearest" )
	pc_icon = love.graphics.newQuad( 0, 0, TS, TS, pc_image:getWidth(), pc_image:getHeight() )

	local offset = { x = ((display.width/2)+0.5), y = ((display.height/2)+0.5) }
	pc = player:new( pc_icon, pc_image, offset, TS , collision_world , stats_master )

	map_tileset = love.graphics.newImage( img_dir.."map_tile_placeholders2.png" )
	map_tileset:setFilter( "nearest" )
	map.tileset_batch = love.graphics.newSpriteBatch( map_tileset, (display.height + 3) * (display.width + 3) )
end


function get_tile_at_ori( char )
	if char.ori == 'n' then
		return 0, -1
	elseif char.ori == 's' then
		return 0, 1
	elseif char.ori == 'e' then
		return 1, 0
	elseif char.ori == 'w' then
		return -1, 0
	end
end
function set_color( R , G , B , A )
	if R == 'white' then
		love.graphics.setColor( 255 , 255 , 255 , G )
	elseif R == 'black' then
		love.graphics.setColor( 0 , 0 , 0 , G )
	elseif R == 'green' then
		love.graphics.setColor( 0 , 255 , 0 , G )
	elseif R == 'red' then
		love.graphics.setColor( 255 , 0 , 0 , G )
	else
		love.graphics.setColor( R , G , B , A )
	end
end
function set_font( font )
	love.graphics.setFont( font )
end
function lprint( text , x , y ) love.graphics.print( text , x , y ) end
function debug()
	lprint("FPS: "..love.timer.getFPS(), 10, 20)
  	lprint("Pos: "..display.world_x.." "..display.world_y, 10, 40)
  	lprint("Self Pos: "..pc.from_center_x.." "..pc.from_center_y, 10, 60)
  	lprint( "Explore: "..tostring(exploration_mode) , 10 , 80 )
   	lprint( "Orders: "..tostring(orders_phase) , 10 , 100 )
  	lprint( "Resolution: "..tostring(resolution_phase) , 10 , 120 )

 	--love.graphics.print("Self World: "..pc.world_x.." "..pc.world_y, 10, 80)
 	--set_color( 'green' )
 	--love.graphics.rectangle( 'fill' , npx*scale , npy*scale , 2*scale , 2*scale )
 	--set_color( 'white' )
end


--========== Pathfinding Utilities (here for now) ===============
function find_path( current_pt , target_pt , prev_pts , depth , target_depth )
	if not depth or not prev_pts or not target_depth then
		depth , prev_pts , target_depth = root_setup( current_pt , target_pt )
	end

	if depth > target_depth then return false end

	local path , history = {} , prev_pts
	table.insert( history, current_pt ) --update path history

	local adj_tiles = get_adj_tiles( current_pt , target_pt , history )

	for i,v in ipairs( adj_tiles ) do
		if v.score == 0 then
			return { v , current_pt }
		else
			path = find_path( { x=v.x , y=v.y } , target_pt , history , depth+1 , target_depth )
		end

		if path then 
			table.insert( path , current_pt )
			if depth == 0 then path[ #path ] = nil end --removes starting pt
			return path
		end
	end
	return false
end


function get_adj_tiles( current_pt , target_pt , history )
	local x,y = current_pt.x,current_pt.y
	local adj_tiles = {}

	for j=-1,1,2 do
		if map:get_passable( x , y+j ) then
			table.insert( adj_tiles , { x=x , y=y+j } )
		end
		if map:get_passable( x+j , y ) then
			table.insert( adj_tiles , { x=x+j , y=y } )
		end
	end

	return score_tiles( adj_tiles , target_pt , history )
end

function score_tiles( tile_array , target , history )
	local temp_array = {}
	local scored_array = {}
	local max = 0

	for i,v in ipairs( tile_array ) do

		if not already_traveled( v , history ) then
			score = get_dist( target , v )
			if score > max then max = score end
			table.insert( temp_array , { score=score , x=v.x , y=v.y } )
		end
	end

	for j=0,max do
		for i,v in ipairs( temp_array ) do
			if v.score == j then 	--if matches, add to scored array, clear
				table.insert( scored_array , v )
				temp_array[ i ] = nil
			end
		end
	end
	return scored_array
end



--========= Path Helpers ===============
function already_traveled( point , history )
	local traveled = false
	for i,v in ipairs( history ) do
		if point.x == v.x and point.y == v.y then
			traveled = true
		end
	end
	return traveled
end

function get_dist( pt1 , pt2 )
	return math.abs( pt1.x - pt2.x ) + math.abs( pt1.y - pt2.y )
end

function root_setup( current_pt , target_pt )
	local dist = get_dist( target_pt , current_pt )
	return 0 , {} , dist+(dist*0.35)
end