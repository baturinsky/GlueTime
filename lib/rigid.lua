Rigid = class(function(self, params)
	rigidn = rigidn + 1
	
	self.colliders = {}
	self.collidern = 0
	
	self.connectors = {}
	
	self.mass = 2
	self.angular_mass = 2 * 60 * 60 * 2/5
	
	self.position = vmath.vector3()
	self.rotation = vmath.quat()
	
	self.velocity = vmath.vector3()
	self.angular_velocity = 0
	
	self.friction = 5
	self.angular_friction = 10
	
	self.restitution = 0.9

	self.d_velocity = vmath.vector3()
	self.d_angular_velocity = 0
	self.d_position = vmath.vector3()
	
	for k,v in pairs(params) do
		self[k] = v
	end
	
	self:setId()
end)

function Rigid:update(game_object, dt)
	
	if self.ai then
		ai_rigid_update(self, game_object, dt)
	end

	self.position = self.position + self.velocity * dt + self.d_position
	self.rotation = self.rotation * vmath.quat_rotation_z(self.angular_velocity * dt)
	
	if (vmath.length(self.velocity) > 300) then
		self.velocity = self.velocity * math.max(0, 1 - self.friction * dt)
	end 
	self.velocity = self.velocity + self.d_velocity
	self.angular_velocity = self.angular_velocity * math.max(0, 1 - self.angular_friction * dt) + self.d_angular_velocity

	self.d_velocity = vmath.vector3()
	self.d_angular_velocity = 0
	self.d_position = vmath.vector3()

	go.set_position(self.position, self.id)	
	go.set_rotation(self.rotation, self.id)		
end

function Rigid:velocity_at(point)	
	local r = point - self.position
	return self.velocity + vmath.vector3(-r.y, r.x, 0) * self.angular_velocity
end

function Rigid:calculate_applied_impulse(other, point, normal)
	local va = self:velocity_at(point)
	local vb = other:velocity_at(point)
	local vab = va - vb		
		
	local top = - vmath.dot(normal, vab) * ( 1 + self.restitution)
	local bottom = 1 / self.mass + 1 / other.mass 
		+ pow2(scalar_cross(point - self.position, normal)) / self.angular_mass
		+ pow2(scalar_cross(point - other.position, normal)) / other.angular_mass
	local j = top / bottom
	return j
end

function Rigid:push(impulse, point)
	if vmath.length(impulse)<0.1 then
		return
	end

	point = point or self.position	

	self.d_velocity = self.d_velocity  + impulse * (1 / self.mass)
		
	local r = point - self.position
			
	self.d_angular_velocity = self.d_angular_velocity + scalar_cross(r, impulse) / self.angular_mass
	
end

function Rigid:bounce(other, point, normal)
	local j = self:calculate_applied_impulse(other, point, normal)	
	self:push(normal * j, point)
end

function Rigid:roll(d_angular_velocity)
	self.angular_velocity = self.angular_velocity + d_angular_velocity 
end

function Rigid:set_root(collider)
	
	if self.root then
		self.root.root = false
	end
	self.root = collider	
	collider.root = true
end

function Rigid:insert(collider, flag)
	collider:deappearify()
	
	if not self.root then
		self:set_root(collider)
	else
    	collider.root = false
	end
		
	collider:localise(self, flag)
	self.colliders[collider.id] = collider
	
	return collider			
end

function Rigid:setId(newId)
	self.id = newId or uid()
	if self.id then
		rigidsById[self.id] = nil
	end
	rigidsById[self.id] = self
end

function Rigid:deappearify()
	if rigidsById[self.id] then
		rigidsById[self.id] = nil
		for k, v in pairs(self.colliders) do
			go.delete(v.id)
		end
		--if flag ~= FINAL then
			go.delete(self.id)
		--end
		
		rigidn = rigidn - 1
	end
	
	for k, v in pairs(self.connectors) do
		go.delete(v)		
	end
	
	self.dead = true
	rigidsById[self.id] = nil
end

function Rigid:appearify()	
	
	self:setId(go.get_id())
	self.position = go.get_world_position()
	self.rotation = go.get_world_rotation()
	
	local weightedPositionSum = vmath.vector3()
	self.mass = 0 
	self.collidern = 0 
	
	for k, v in pairs(self.colliders) do
		self.collidern = self.collidern + 1
		self.mass = self.mass + v.mass
		weightedPositionSum = weightedPositionSum + v.mass * v.position
	end
		
	if self.collidern == 0 then
		self:deappearify()
		return
	end
	
	local center = weightedPositionSum * (1 / self.mass)
	
	--Changing ids by appearify can screw order, therefore this
	local allColliders = {}	
	for k, v in pairs(self.colliders) do table.insert(allColliders, v) end
		
	self.angular_mass = 0
			
	for k, v in ipairs(allColliders) do		
		self.angular_mass = self.angular_mass + (v.mass * v.mass) * vmath.length(v.position) + v.angular_mass  
		v.position = v.position - center
		v:appearify()
	end	

	if vmath.length(center) > 0.1 then
		self.d_position = self.d_position + vmath.rotate(self.rotation, center)
	end	

	for k, v in pairs(self.connectors) do
		go.delete(v)
	end
	self.connectors = {}
	
	for k1, v1 in pairs(self.colliders) do
	for k2, v2 in pairs(self.colliders) do
		if hash_to_hex(v1.id) < hash_to_hex(v2.id) then
			local d = v2.position - v1.position
			if vmath.length(d) <= v1.radius + v2.radius + 2 then
				local midpoint = (v1.position * v2.radius + v2.position * v1.radius) * (1 / (v1.radius + v2.radius))
				midpoint.z = 0.05
				local angle = -math.atan2(d.x, d.y) + math.pi/2
				local rotation = vmath.quat_rotation_z(angle)
				local connector = factory.create(url(self.id, "connector_factory"), vector_to_global(midpoint), rotation_to_global(rotation))
				msg.post(connector, "set_parent", {parent_id = go.get_id()})
				table.insert(self.connectors, connector)
			end
		end
	end
	end
end