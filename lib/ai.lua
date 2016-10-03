function shooter_update(self, game_object, dt)		
	
	if not self.charge then
		self.charge = 0
	end
	
	self.charge = self.charge + dt * (1 + self.buff)
	
	if self.charge >= 2 then
		local p = go.get_world_position()
		local shot = factory.create(self.good and "#good_bullet_factory" or "#evil_bullet_factory", nil, nil, {
			master = self.id, target = p + vmath.vector3(self.good and 100 or -100, 0, 0), velocity = self.velocity, power = 50, no_particles = true}
		)
		sprite.set_constant(url(shot, "sprite"), "tint", self.good and vmath.vector4(1, 2, 2, 1) or vmath.vector4(2, 1, 1, 1))
		self.charge = 0
	end	
end

function launcher_update(self, game_object, dt)	

	if not self.charge then
		self.charge = 0
	end
	
	self.charge = self.charge + dt * (1 + self.buff)
	
	if self.charge >= 2 then
		local p = go.get_world_position()
		
		if not on_screen(p) then
			return
		end
		
		local nearest_enemy = nil
		local nearest_enemy_distance = 1000000
		
		for k,t in pairs(rigidsById) do
			if t.good ~= self.good and on_screen(t.position) then
				local d = vmath.length(t.position - self.position)
				if d < nearest_enemy_distance then
					d = nearest_enemy_distance
					nearest_enemy = t
				end
			end
		end
		
		if nearest_enemy then
		
			local d = nearest_enemy.position - p
			local rot = vmath.quat_rotation_z(-math.atan2(d.x, d.y))	
		
			local shot = factory.create(self.good and "#good_rocket_factory" or "#evil_rocket_factory", nil, rot, {
				master = self.id, target = p + vmath.vector3(self.good and 100 or -100, 0, 0), power = self.good and 40 or 20, homing_id = nearest_enemy.id}
			)
			
			sprite.set_constant(url(shot, "sprite"), "tint", self.good and vmath.vector4(0.5, 0.5, 3, 1) or vmath.vector4(3, 1, 1, 1))
		end
		self.charge = 0
	end
end

function ai_magnet_update(self, game_object, dt)
	local p = go.get_world_position()
	for k,g in pairs(gluesById) do
		local r = p - go.get_world_position(g.id)
		local d = vmath.length(r)
		g.velocity = g.velocity + vmath.normalize(r) * pow2(1000 / (d + 60)) * self.buff
	end
end

function ai_rigid_update(self, game_object, dt)
	if self.boss then
		self:steer(vmath.normalize(protatree.position + vmath.vector3(max_x * 0.25, 0, 0) - self.position))
	else	
		self:steer(vmath.vector3(-0.5, 0, 0))
	end	
end

function ai_collider_update(self, game_object, dt)
	if self.type.ai_update then
		self.type.ai_update(self, game_object, dt)
	end
end