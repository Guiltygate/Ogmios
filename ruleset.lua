--[[

	Top-level object for dice and stat calculations, to try and keep all the ruleset stuff in
	one place.


--]]


ruleset = {}


function ruleset:d( faces, number )	--generalized dX function
	local total = 0
	for i=0,number do total = total + math.ceil( math.random() * faces ) end
	return total
end

function ruleset:setup_base_calcs( char )
	local stats = char.stats

	char.max_hp = stats.lung * stats.blood * 2	--set max and current health
	char.current_hp = char.max_hp

end

function ruleset:attack( attacker, disp, map )
	local weapon = attacker.weapon
	local stat_dmg = self:d( 4, attacker.stats.fang )

	if not attacker:is_moving() and ( not disp or ( disp and not disp:is_moving() ) ) then
		x,y,wpn_dmg = weapon:strike( attacker )
		x,y = x+attacker.world_x, attacker.world_y+y
		target = map:get_resident( x, y )

		if target then 
			print( target.name )
			total_damage = stat_dmg + wpn_dmg - target:armor()
			target:wound( total_damage )
		end

	end
end





return ruleset