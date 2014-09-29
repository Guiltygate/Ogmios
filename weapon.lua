--[[

	Weapon class, might not be necessary, but we'll see.

--]]


weapon = {}

weapon.name = "Nihil"
weapon.type = "Sword"
weapon.hitorder = { "f2", "f1", "r2" }
weapon.hitboxes = { f2=1, f1=1, r2=2 }		--tiles hit by weapon.
weapon.damage = { 2 }							--multiplier for each tile

templates = {
		sword = { tiles=3, hitboxes={f2=1,f1=1,r2=2}, hitorder={ "f2", "f1", "r2" } }
	, 	dagger = { tiles=1, hitboxes={f1=2}, hitorder={"f1"} }
}

weapon.hit_holder = {
	n={ {x=0,y=-1} , {x=-1,y=-1} , {x=0,y=-2} ,  {x=-2,y=-1} , {x=-1,y=-2} , {x=0,y=-3}}
	,s={ {x=0,y=1} , {x=1,y=1} , {x=0,y=2} ,  {x=2,y=1} , {x=1,y=2} , {x=0,y=3}}
	,e={ {x=1,y=0} , {x=1,y=-1} , {x=2,y=0} , {x=1,y=-2} , {x=2,y=-1} , {x=3,y=0} }
	,w={ {x=-1,y=0} , {x=-1,y=1} , {x=-2,y=0} , {x=-1,y=2} , {x=-2,y=1} , {x=-3,y=0} }
}

--=======================


function weapon:new( param_table  )
	new_wpn = param_table
	setmetatable( new_wpn, self )
	self.__index = self

	new_wpn.hitorder = templates[ new_wpn.type ].hitorder
	new_wpn.hitboxes = templates[ new_wpn.type ].hitboxes
	new_wpn.tiles = templates[ new_wpn.type ].tiles

	return new_wpn
end


function weapon:strike( char )
	turn_num = char.is_attacking
	hit_tile = self:get_hit_location( char.ori, turn_num )
	x=hit_tile.x; y=hit_tile.y
	local damage = self.damage * self.hitboxes[ self.hitorder[turn_num] ]

	return x, y, damage

end



function weapon:get_hit_location( ori, turn_num )
	local hitbox = self.hitorder[ turn_num ]
	local x,y	

	dir = string.match( hitbox, '%a' )
	num = tonumber( string.match( hitbox, '%d' ) )


	if ori == 'n' then
		if dir == 'l' then return self.hit_holder.w[ num ]
		elseif dir == 'r' then return self.hit_holder.e[ num ]
		else return self.hit_holder.n[ num ] end

	elseif ori == 's' then
		if dir == 'l' then return self.hit_holder.e[ num ]
		elseif dir == 'r' then return self.hit_holder.w[ num ]
		else 
			print( num, self.hit_holder.s[ num ] )
			return self.hit_holder.s[ num ] end

	elseif ori == 'e' then
		if dir == 'l' then return self.hit_holder.n[ num ]
		elseif dir == 'r' then return self.hit_holder.s[ num ]
		else return self.hit_holder.e[ num ] end

	elseif ori == 'w' then
		if dir == 'l' then return self.hit_holder.s[ num ]
		elseif dir == 'r' then return self.hit_holder.n[ num ]
		else return self.hit_holder.w[ num ]	 end	
	end

end			


function weapon:num_of_hits()
	return #(weapon.hitorder)
end


return weapon