
function uid()	
	uid_count = uid_count + 1
	return hash("uid_"..uid_count)
end

function url(obj, prop)
	return msg.url(nil, obj, prop)
end

function pprint_table(table)
	print("  table:")
	for k, v in pairs(table) do
		pprint(k)
		pprint(v.position)
	end
	print("  end:")
end

function scalar_cross(v1, v2)
	return v1.x*v2.y - v1.y*v2.x
end

function minmax(a,b,c)
	if b < a then
		return a
	elseif b > c then
		return c
	else
		return b
	end
end

function pow2(x)
	return x*x
end

function screen_to_world(original) 
	return vmath.vector3(
		zoom * (original.x - screen_width * 0.5) + view_center.x,
		zoom * (original.y - screen_height * 0.5) + view_center.y,
		original.z or 0
	)
end	

function world_to_screen(original) 
	return vmath.vector3(
		(original.x - view_center.x) / zoom + screen_width * 0.5,
		(original.y - view_center.y) / zoom + screen_height * 0.5,
		original.z or 0
	)
end	


--http://lua-users.org/wiki/SimpleLuaClasses

function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else 
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do 
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end

function quat_mul_calar(q1, s)
	return vmath.quat(q1.x*s, q1.y*s, q1.z*s, q1.w*s)	
end

function default_space()
	return {position = go.get_position(), rotation = go.get_rotation()}
end	

function vector_to_local(vec, space)
	space = space or default_space()	
	return vmath.rotate(vmath.conj(space.rotation), vec - space.position)
end

function rotation_to_local(rotation, space)
	space = space or default_space()		
	return rotation * vmath.conj(space.rotation)
end

function vector_to_global(vec, space)
	space = space or default_space()
	return vmath.rotate(space.rotation, vec) + space.position
end

function rotation_to_global(rotation, space)
	space = space or default_space()		
	return rotation * space.rotation
end

sound_cooldown = {}

function play_sound(sound, gain)
	if on_screen(go.get_world_position()) then
		if not sound_cooldown[sound] then
			msg.post("main#" .. sound, "play_sound", {delay = 0, gain = (gain or 1) * (settings.volume*0.1)})
			sound_cooldown[sound] = 0.1
		end
	end
end

function current_time_scale()
	return glue_time and glue_scale or 1
end

require "lib/globals"
require "lib/ai"
require "lib/ghost"
require "lib/ghost_tree"
