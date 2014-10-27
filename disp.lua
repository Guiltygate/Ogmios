--[[

No time, I'm drunk.
display.lua!

]]

package.path = "Ogmios/sub_objects/?.lua"

disp = {}
gui_boxes = require( "gui_boxes" )
disp.tile_selected = nil	--{ tile=map:get_tile( x , y ) , x=x , y=y }
disp.npc_selected = nil


function disp:new( height, width, window_height, window_width )
	new_disp = {}
	setmetatable( new_disp, self )
	self.__index = self

	new_disp.world_x = 0; new_disp.world_y = 0
	new_disp.pixel_x = 0; new_disp.pixel_y = 0
	new_disp.height = height; new_disp.width = width
	new_disp.offset_x = 0; new_disp.offset_y = 0
	new_disp.pixel_height = window_height
	new_disp.pixel_width = window_width

	disp.text_box = gui_boxes:new( 'text' , window_height, window_width)
	disp.info = gui_boxes:new( 'info' , window_height , window_width )

	return new_disp
end


function disp:explore_move( x , y , move_slice )
	
	self.pixel_x = self.pixel_x + x*move_slice
	self.pixel_y = self.pixel_y + y*move_slice

	x,y = self:grid_snap()
	if x then self.world_x = self.world_x + x end
	if y then self.world_y = self.world_y + y end

	return true
end


function disp:draw( TS, tileset_batch, scale )
	love.graphics.draw( tileset_batch, -self.pixel_x*scale, -self.pixel_y*scale , 0, scale, scale ) --This draws the entire background!

	if combat_mode and orders_phase then 		--selected tile outline must be drawn here, to appear behind characters
		if self.tile_selected then
			self:draw_selected_tile( self.tile_selected )
		end
		if self.npc_selected then
			self:draw_npc_attack( self.npc_selected )
		end
	end
end


function disp:select_tile( x , y , tile  ) --x and y are in display pixel, not raw
	local construct = { tile=tile , x=x , y=y }
	local npc = tile:get_resident()

	if self.tile_selected and self.tile_selected.tile == tile then
		self.tile_selected = nil
		self.npc_selected = nil
	else 
		self.tile_selected = construct
		self.npc_selected = npc
	end
end


function disp:show_text_box( text )	self.text_box:show_text( text ) end

function disp:get_selected_npc() return self.npc_selected end


function disp:draw_gui( pc )
	if combat_mode then
		self:show_party_status( pc:get_party() )
		if self.tile_selected then
			self:show_info_pane( self.tile_selected )
			self.text_box:draw( self.tile_selected.tile , self )
		end		--These are the different GUI pieces
	else
		self.text_box:draw()
	end
end


function disp:combat_move( map , dt , pc )
	local build = false
	local move_slice = math.ceil( dt * 100 )

		local direction = { n=false , e=false , w=false , s=false }

		if love.keyboard.isDown( 'w' , 'up' ) then direction.n = true; end
		if love.keyboard.isDown( 'a' , 'left' ) then direction.w = true; end
		if love.keyboard.isDown( 'd' , 'right' ) then direction.e = true; end
		if love.keyboard.isDown( 's' , 'down' ) then direction.s = true; end

		for key,value in pairs( direction ) do
			if value then
				local x,y = get_tile_at_ori({ ori = tostring( key ) })
				if self:should_move( map.world , x*move_slice , y*move_slice , pc ) then
					build = self:explore_move( x , y , move_slice )
				end
			end
		end
	return build
end






--===================== HELPERS =================================

function disp:snap_x()
	local pixel = self.pixel_x
	if pixel > self.world_x*TS + TS/2 then return 1
	elseif pixel < self.world_x*TS - TS/2 then return -1
	else return nil end
end

function disp:snap_y()
	local pixel = self.pixel_y
	if pixel > self.world_y*TS + TS/2 then return 1
	elseif pixel < self.world_y*TS - TS/2 then return -1
	else return nil end
end

function disp:grid_snap() return self:snap_x() , self:snap_y() end

function disp:show_info_pane( construct )
	--construct.xy is in tiles, so we convert to game pixel then raw pixel with raw_TS
	--pixel_xy is in game pixel, convert to raw pixel via scale ( raw pixel / disp pixel )
	-- 96 --> 32 --> 1 for my testing laptop, differs obviously
	set_color( 'black' )
	self.info:draw( construct.tile ) 		--draw info box via guit_boxes.lua
	set_color( 'white' )
end

function disp:show_party_status( party )
	local margin = self.pixel_height/60
	local start_pos_y = self.pixel_width / 20
	local count = 1

	for k,v in pairs( party ) do
		--set_color( 'white' )
		--love.graphics.rectangle( 'fill' , margin , start_pos_y*count , TS*scale*2 , (TS-4)*scale )
		set_color( 'black' ); set_font( sidebar_font )
		love.graphics.print( v.name , margin*2 , (start_pos_y*count)+margin )
		set_color( 'white' ); love.graphics.setNewFont( default_font )

		self:draw_health_bar( margin , start_pos_y , v , count )

		count = count + 1
	end
end

function disp:draw_health_bar( margin , start_pos_y , v , count )
	local health_fill = math.ceil( (v.current_hp / v.max_hp) * 40 )
	local G = 200 * ( health_fill / 20 ); local R = 200 - G;
	set_color( R , G,  10 , 255 )
	love.graphics.rectangle( 'fill', margin*2 , (start_pos_y*count)+margin*3 , health_fill*scale , 4*scale )
	set_color( 'white' )
end

function disp:draw_selected_tile( construct )
	set_color( 'green' )
	love.graphics.rectangle( 'line' , construct.x*raw_TS - self.pixel_x*scale , construct.y*raw_TS - self.pixel_y*scale, TS*scale , TS*scale )
	set_color( 'white' )
end

function disp:draw_npc_attack( npc )
	local weapon = npc.weapon
	local tiles = self:get_attack_tiles( weapon , npc )

	set_color( 'red' , 150 )
	for i,v in ipairs( tiles ) do
		love.graphics.rectangle( 'fill' , v.x*raw_TS - self.pixel_x*scale , v.y*raw_TS - self.pixel_y*scale , TS*scale , TS*scale )
	end
	set_color( 'white' )
end

function disp:get_attack_tiles( weapon , npc )
	char = { ori=npc.ori , is_attacking=0 }
	tiles = {}

	for i=1,weapon:num_of_hits() do
		char.is_attacking = i
		local x,y = weapon:strike( char )
		local tile = { x=x+npc.world_x , y=y+npc.world_y }
		table.insert( tiles , tile )
	end
	return tiles
end

function disp:should_move( world , dx , dy , pc )
	return self.pixel_y+dy >= 0 and self.pixel_x+dx >= 0 and self.pixel_y+dy <= (world.height_tiles*TS - pc.offset_y*2)+TS and
				 self.pixel_x+dx <= ( world.width_tiles*TS - pc.offset_x*2 )+TS
end



return disp