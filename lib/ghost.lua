require "lib/collider"

ballTypes = {}
ballTypes[CUEBALL] = {name = "Cueball", sprite = "cueball", glue = 30, hp = 1000, engine = 30, mass = 30, color=vmath.vector4(1,1,1,1)}
ballTypes[1] = {name = "Rock", sprite = "1ball", glue = 10, hp = 100, engine = 1, mass = 1, color=vmath.vector4(1,1,0,1)}
ballTypes[2] = {name = "Shooter", sprite = "2ball", glue = 20, hp = 100, engine = 1, mass = 2, color=vmath.vector4(0,0,1,1), ai_update = shooter_update}
ballTypes[3] = {name = "Bull", sprite = "3ball", glue = 20, hp = 100, engine = 5, mass = 2, color=vmath.vector4(1,0,0,1)}
ballTypes[4] = {name = "Armor", sprite = "4ball", glue = 40, hp = 300, engine = 1, mass = 3, armor = 1, color=vmath.vector4(1,0,1,1)}
ballTypes[5] = {name = "Launcher", sprite = "5ball", glue = 50, hp = 100, engine = 1, mass = 2, color=vmath.vector4(0.5,1,0,1), ai_update = launcher_update}
ballTypes[6] = {name = "Magnet", sprite = "6ball", glue = 60, hp = 200, engine = 1, mass = 2, capturing = true, color=vmath.vector4(0,1,0,1), ai_update = magnet_update}
ballTypes[7] = {name = "Hub", sprite = "7ball", glue = 100, hp = 200, engine = 1, mass = 3, aura = 1, color=vmath.vector4(0.5,0.2,0,1)}
ballTypes[8] = {name = "8ball", sprite = "8ball", glue = 200, hp = 1000000, engine = 30, mass = 30, aura = 3, glue_resistant = true, color=vmath.vector4(0,0,0,1)}

Ghost = class(Collider, function(self, type_id, param)
	self.glue = 0
	Collider.init(self, ballTypes[type_id], param)
end)

function Ghost:onFirstAppearify()
	msg.post(self.id, "alignment", {good = self.good})
end

function Ghost:max_hp()
	return self.type.hp
end

function Ghost:max_glue()
	return self.type.glue
end

function Ghost:localise(tree, flag)
	Collider.localise(self, tree, flag)
end

function Ghost:spawn_glue(gluen)
	local tree
	if self.tree then			
		tree = self.tree 
		local glue_blobs = math.random(1,3)
		for i=1, glue_blobs do
			local glue_id = factory.create(url(self.id, "glue_factory"), vmath.vector3(0, 0, -0.1) + go.get_world_position(), nil, {
				glue = math.random(1, math.floor(gluen/3)), velocity = self.tree.velocity
			})
		end								
	end
end

function Ghost:deal_damage(damage)
	if self.buff then
		damage = damage / (1 + self.buff)
	end
	
	if self.type.armor then
		damage = damage / (1 + self.type.armor)
	end	

	if self.tree.good then
		damage = damage * (1 + settings.difficulty*0.2)
	else
		damage = damage / (1 + settings.difficulty*0.1)
	end

	self.hp = self.hp -	math.floor(damage)
	
	if self.tree == protatree and damage > 10 then
		play_sound("im_hit", math.min(damage/30, 2))
		msg.post("camera", "shake", {magnitude = math.min(damage/30, 2)})
	end
	
	if self.hp <= 0 then
		self:spawn_glue(self.glue)
		local tree = self.tree
		local p = go.get_world_position()
				
		if on_screen(p) then
			play_sound("crack", (math.random()*0.4 + 0.1) * (self.tree.good and 3 or 1))
			play_sound("bang", (math.random()*0.4 + 0.1) * (self.tree.good and 3 or 1))
			particlefx.play(url(self.id, id_explosion))
			for i  = 1,5 do
				local debris = factory.create("#debris_factory",p , vmath.quat_rotation_z(math.random()*6.28), {type_id = self.type_id, shell_debris= i ~= 1})
			end
		end 
		
		self:destroy()
		
		if tree then
			tree:integrity_check()
		end
		
		for k, ghost in pairs(collidersById) do
			local r = ghost:world_position() - self:world_position()
			local d = vmath.length(r)
			if ghost.tree then
				ghost.tree:push(vmath.normalize(r) * pow2(30000 / (d + 60)) * last_dt, ghost:world_position())
			end			
		end			
		
	else
		self.tree:count_hp()
	end						
end


			