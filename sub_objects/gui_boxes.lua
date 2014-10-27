--[[]

	Author: Eric Ames
	Last Updated: August 8th, 2014
	Purpose: Creates message box object for lua RPG.

--]]


gui_boxes = {}
gui_boxes.text = ""
gui_boxes.show = false


function gui_boxes:new( type, window_height, window_width)
	new_box = {}
	setmetatable( new_box, self )
	self.__index = self
	new_box.type = type
	new_box.margin_x = window_width/50
	new_box.margin_y = window_height/50

	if type == 'text' then
		new_box.ypos = window_height - ( (window_height / 8) * 2 )
		new_box.xpos = window_width / 4
		new_box.width = (window_width/2)
		new_box.height = (window_height/4)
		new_box.offset_x_2 = window_width/16
		new_box.offset_y_2 = window_height/12
	elseif type == 'info' then
		new_box.ypos = (window_height / 8)
		new_box.xpos = window_width - window_width / 6
		new_box.width = window_width / 6
		new_box.height = (window_height / 8) * 2
		new_box.offset_x = window_width/70
		new_box.offset_y = window_height/40
		new_box.show = true
	end	
	return new_box
end

function gui_boxes:draw( selected_tile , disp )

  	if self.show or combat_mode then
  		set_color( 'white' )
  		love.graphics.rectangle( "fill" , self.xpos , self.ypos , self.width , self.height )
  		set_color( 'black' )
  		if not combat_mode then 
  			set_font( speech_font )
  			lprint( self.npc_speech, self.xpos + self.offset_x_2, self.ypos + self.offset_y_2 )
  		end

  		set_font( info_font ); local tile = selected_tile
  		if tile then
	  		if self.type == 'info' then
	  			love.graphics.print( "Tile Type: "..tile:get_type(), self.xpos+self.offset_x, self.ypos + self.offset_y )
	  			love.graphics.print( "Passable: "..tostring( tile:passable() ) , self.xpos+self.offset_x, self.ypos+self.offset_y*4 )

	   		elseif self.type == 'text' then
	   			local resident = tile:get_resident()
	   			if resident then
	   				lprint( resident.name, self.xpos+self.margin_x, self.ypos+self.margin_y*1 )
	   				lprint( "Faction: "..resident.faction, self.xpos+self.margin_x, self.ypos+self.margin_y*10 )
	   				self:draw_health_bar( self.xpos+self.margin_x , self.ypos+self.margin_y*9 , resident )

	   				local count = 1
	   				for k,v in pairs( resident.stats ) do
	   					lprint( k..":" , self.xpos+self.margin_x*5 , self.ypos+self.margin_y*count )
	   					lprint( v , self.xpos+self.margin_x*8 , self.ypos+self.margin_y*count )
	   					count = count + 1
	   				end
	   				lprint( resident.weapon.name , self.xpos+self.margin_x*12 , self.ypos+self.margin_y*2 )
	   				lprint( resident.weapon.type , self.xpos+self.margin_x*12 , self.ypos+self.margin_y*3 )
	   				lprint( "Damage: "..resident.weapon.damage , self.xpos+self.margin_x*12 , self.ypos+self.margin_y*4 )

	   			end
	   		end
   		end
   		set_color( 'white' )
  	end
end


function gui_boxes:show_text( npc_speech )
	if npc_speech then
		self.npc_speech = npc_speech
		self.show = true
	else
		self.npc_speech = ""
		self.show = false
	end
end







--========== HELPERS ============

function gui_boxes:draw_health_bar( x , y , v )
	local health_fill = math.ceil( (v.current_hp / v.max_hp) * 40 )
	local G = 200 * ( health_fill / 20 ); local R = 200 - G;
	set_color( R , G,  10 , 255 )
	love.graphics.rectangle( 'fill', x , y , health_fill*scale , 4*scale )
	set_color( 'black' )
end

return gui_boxes