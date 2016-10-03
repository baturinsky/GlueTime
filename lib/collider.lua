collider_default_radius = ballR 

function my_ghost()
	return collidersById[go.get_id()]
end	

Collider = class(function(self, type, param)
	
	self.type = type
	
	self.position = vmath.vector3()
	self.rotation = vmath.quat()
	self.radius = collider_default_radius
			
	for k, v in pairs(self.type) do
		self[k] = v
	end
	
	if param then
		for k, v in pairs(param) do
			self[k] = v
		end
	end
	
	self.angular_mass = 0.4 * self.radius * self.radius * self.mass
	
	self:setId()
	self.appearified = false
end)

function Collider:onFirstAppearify()
end

function Collider:appearify()
	if not self.appearified then
		self:setId(factory.create("#collider_factory", vector_to_global(self.position, tree), rotation_to_global(self.rotation, tree), 
		{
			master = go.get_id(), ghost_id = self.id
		}))	
		self:onFirstAppearify()
		self.appearified = true
	else
		go.set_position(self.position, self.id)
		go.set_rotation(self.rotation, self.id)
	end
end

function Collider:localise(tree, flag)
	if self.tree ~= tree then
		self.tree = tree
		if flag ~= LOCAL then
			self.position = vector_to_local(self.position, self.tree)
			self.rotation = rotation_to_local(self.rotation, self.tree)
		end
		self.good = tree.good
	end
end

function Collider:globalise()
	if self.tree then
		self.position = vector_to_global(self.position, self.tree)
		self.rotation = rotation_to_global(self.rotation, self.tree)
		self.tree = nil 
	end		
end

function Collider:setId(newId)
	if self.id then
		collidersById[self.id] = nil
		if self.tree then self.tree.colliders[self.id] = nil end
	end
	self.id = newId or uid()
	if self.tree then self.tree.colliders[self.id] = self end
	collidersById[self.id] = self
end

function Collider:touching(that)
	return vmath.length(that.position - self.position) <= (self.radius + that.radius + 2)
end

function Collider:world_position()
	return self.tree and vector_to_global(self.position, self.tree) or self.position 
end

function Collider:deappearify()
	if not self.appearified then
		return
	end
	go.delete(self.id)
	self.appearified = false
	if self.tree then
		assert(self.tree.colliders[self.id] ~= nil)				
			
		self.tree.colliders[self.id] = nil
		if self.root then
			self.tree:on_root_destroyed()
		else
			msg.post(self.tree.id, "appearify")
		end
	end			
	
	self:globalise()
end

function Collider:destroy()
	if not self.dead then
		self:deappearify()
		self.dead = true
		collidersById[self.id] = nil
	end
end