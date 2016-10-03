require "lib/rigid"

function my_tree()
	local ghost = my_ghost()
	if ghost then 
		return ghost.tree
	else
		return rigidsById[go.get_id()]
	end	
end

GhostTree = class(Rigid, function(self, params)
	self.glue = 0
	self.charge = 0
	Rigid.init(self, params)
end)

function GhostTree:from_string(s)
	local row = 0
	local col = 0
	local charn = string.byte("\n")
	local charn2 = string.byte(";")
	local char0 = string.byte("0")
	for i = 1, string.len(s) do		
		c = string.byte(s, i)
		if c == charn or c == charn2 then
			row = row + 1
			col = 0
		else
			col = col + 1
		end
		local x = ballR * (col * 2 - row)
		local y = ballR * (row * 2 * sin60)
		local n = c - char0
		if n == 0 then
			n = CUEBALL
		end
		
		if n >= 0 and n <= CUEBALL then
			local g = self:insert( Ghost(n, {position = vmath.vector3(x, y, 0)}), LOCAL)			
			if n == CUEBALL or n == 8 then
				self:set_root(g)
			end
		end
	end
end

function GhostTree:steer(v, rotate)
	local acceleration = 700 * self.engine * self.friction
	local angular_acceleration = self.engine

	if v then
		self:push(v * acceleration * last_dt)
	end
	
	if rotate then
		self:roll(rotate * angular_acceleration * last_dt)
	end	
end

function GhostTree:update(game_object, dt)
	local bleed_rate = game_stage == MAIN_STAGE and last_dt or 0
	
	local total_bleed = 0
	
	if self == protatree and glue_time then
		bleed_rate = bleed_rate * glue_scale
	end

	for k, v in pairs(self.colliders) do
		if v.hp < v:max_hp() then
			if self.glue > self.max_glue + bleed_rate or (v == self.root and self.glue > bleed_rate) then
				self.glue = self.glue - bleed_rate
				v.hp = math.min(v.hp + bleed_rate, v:max_hp())
				total_bleed = total_bleed + bleed_rate
			end
		end
	end
	
	if self == protatree and total_bleed>0 then
		msg.post("main", "glue_healing", {healing = total_bleed}) 
	end
	
	if self.glue >= self.max_glue + last_dt then
		self.glue = self.glue - bleed_rate
	end
	
	self:count_hp()
	
	self.charge = self.charge + dt

	Rigid.update(self, game_object, dt)
end


function GhostTree:count_hp()
	self.hp = 0
	for k, v in pairs(self.colliders) do
		self.hp = self.hp + v.hp
	end
	return self.hp
end

function GhostTree:appearify(flag)

	Rigid.appearify(self, flag)
	
	self.engine = 0 
	self.max_hp = 0
	self.max_glue = 0	

	for k, v in pairs(self.colliders) do
		self.engine = self.engine + v.engine		
		self.max_hp = self.max_hp + v:max_hp()
		self.max_glue = self.max_glue + v:max_glue()
		v.buff = 0				 
	end
				
	for k, v in pairs(self.colliders) do
		if v.aura then
			for k1, buffed in pairs(self.colliders) do
				if not buffed.aura then
					local d = vmath.length(buffed.position - v.position)
					local buff = v.aura / pow2(d/ballR/2)
					buffed.buff = math.min(buffed.buff + buff, 3)					
				end  
			end
		end		
	end	

	self.gun_power = 50 + self.collidern*5
		
	if self.boss and self.collidern == 1 then
		boss_nude = true
		msg.post("main#gui", "boss_nude")
	end
end

function GhostTree:can_into_glue()
	return glue_cooldown <= 0 and (self.glue >= self.max_glue or boss_nude)
end	

function GhostTree:deappearify()
	Rigid.deappearify(self)

	if self == protatree then
		msg.post("main", "game_over")
	elseif self.boss then
		win()
	end
end

function GhostTree:integrity_check()
	local connected = {}
	connected[self.root.id] = self.root
	
	local fresh = {self.root}
	
	while #fresh > 0 do		
		local a = table.remove(fresh)
		for k, v in pairs(self.colliders) do
			if a:touching(v) and not connected[v.id] and not v.root then
				connected[v.id] = v
				table.insert(fresh, v)
			end
		end
	end
	
	for k, v in pairs(self.colliders) do
		if not connected[v.id] then
			v:destroy()
		end
	end
end

function GhostTree:on_root_destroyed()
	for k, v in pairs(self.colliders) do
		msg.post(v.id, "murder", {damage=1000000})
	end
	msg.post(self.id, "deappearify")
end	


function GhostTree:on_input(action_id, action)
	local rotate = 0
		local v = vmath.vector3(0, 0, 0)
	
	if action_id == hash("mouse_left") then
		local xyzoomed = screen_to_world(action)
		
		if (self.charge >= 0.2 and self.glue > 10 and action.pressed) or self.charge >= 1 then			
			local p = go.get_world_position(self.root.id)
			local shot = factory.create(url(self.id,"shot_factory"), p, nil, {
				master = self.id, target = vmath.vector3(xyzoomed.x, xyzoomed.y, 0), power = self.gun_power / 2, hp = self.gun_power * 3, scale = 2 
			})
			self.glue = self.glue - math.max(0, (1 - self.charge) * 3)
			self.charge = 0
		end
	elseif action_id == hash("up") then
		v.y = 1
	elseif action_id == hash("down") then
		v.y = -1
	elseif action_id == hash("right") then
		v.x = 1
	elseif action_id == hash("left") then
		v.x = -1
	elseif action_id == hash("rot_left") then
		rotate = 1
	elseif action_id == hash("rot_right") then
		rotate = -1
	elseif action_id == hash("glue") then
		if action.pressed then
			toggle_glue()
		end
	end
	
	if glue_time then
		v = v * 1.5
		rotate = rotate * 2 	
	end
	
	self:steer(v, rotate)
	
end
