--[[]

	Author: Eric Ames
	Last Updated: August 8th, 2014
	Purpose: Creates message box object for lua RPG.

--]]


msg_box = {}
msg_box.text = ""
msg_box.show = false
msg_box.offset_x = 100
msg_box.offset_y = 100



function msg_box:new( window_height, window_width)
	new_box = {}
	setmetatable( new_box, self )
	self.__index = self

	new_box.ypos = window_height - ( (window_height / 8) * 2 )
	new_box.xpos = window_width / 4
	new_box.width = (window_width/2)
	new_box.height = (window_height/4)

	return new_box
end

function msg_box:draw()

  	if self.show then
  		love.graphics.rectangle( "line", self.xpos, self.ypos,  self.width, self.height)
  		love.graphics.print( self.text, self.xpos + self.offset_x, self.ypos + self.offset_y )
  	end

end


function msg_box:show_text( text )
	if text then
		self.text = text
		self.show = true
	else
		self.text = ""
		self.show = false
	end
end



return msg_box