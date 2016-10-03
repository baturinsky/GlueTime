ballR = 33
sin60 = 0.866

CUEBALL = 33

msg_contact_point_response = hash("contact_point_response")
msg_animation_done = hash("animation_done")
msg_trigger_response = hash("trigger_response")

id_ghost = hash("ghost")

id_cueball = hash("cueball")
id_1ball = hash("1ball")
id_2ball = hash("2ball")
id_3ball = hash("3ball")
id_4ball = hash("4ball")
id_5ball = hash("5ball")
id_6ball = hash("6ball")
id_7ball = hash("7ball")
id_8ball = hash("8ball")

id_explosion = hash("explosion")

quat_half_pi = vmath.quat_rotation_z(math.pi / 2)

GOOD = hash("GOOD")
EVIL = hash("EVIL")
UPDATE = hash("UPDATE")
LOCAL = hash("LOCAL")

INTRO_STAGE = hash("INTRO_STAGE")
MAIN_STAGE = hash("MAIN_STAGE")
GAME_OVER_STAGE = hash("GAME_OVER_STAGE")

uid_count = 0

screen_width = 1600
screen_height = 900

--[[
min_y = 0
max_y = 900

min_x = 0
max_x = 1600
--]]


min_y = -450
max_y = 1350

min_x = -800
max_x = 2400


mouse_position = vmath.vector3()

boss_time = 300

volume = 5

shown_glue_ready = true

function on_screen(p)
	--return p.x >= min_x and p.x <= max_x and p.y >= min_y and p.y <= max_y
	return vmath.length(p - view_center) <= 1600	
end

function too_far(p)
	return vmath.length(p - view_center) > 2400
end

function set_time_step(factor)
	if factor == nil then
		if paused then
			factor = 0
		elseif main then
			factor = 1 / (1 + (glue_scale - 1) * main.zoom_into_glue)
		else
			factor = 1
		end
	end
	msg.post("default:/loader#world1", "set_time_step", {factor = factor, mode = 0})
end

big_ship_plan = [[
544
7264
35064
 7264
  544
]]

boss_plan = [[
445
4274
41851
 4274
  445
]]

settings_file_path = sys.get_save_file("glue_time", "settings")

settings = sys.load(settings_file_path)

if settings == nil or settings.volume == nil then 
	settings = {volume = 10, difficulty = 0}
end

function init_globals()
	glue_time = false
	glue_cooldown = 2
	glue_scale = 4
	
	last_dt = 0
	
	protatree = nil
	
	game_time = 0
	
	collidersById = {}
	rigidsById = {}
	gluesById = {}
	
	rigidn = 0
	
	game_stage = INTRO_STAGE
	boss_present = false
	boss_nude = false
	
	camera_shake = 0
	cumulative_healing = 0
	
	view_center = vmath.vector3()	
	
	zoom = 2
end

function game_over()
	return game_stage == GAME_OVER_STAGE
end		

intro_text = [[


Step 1: Mouse click fires your main cannon. Use it to kill things.

Step 2: Collect glue (green drops) from killed things until your Glue is above the cap.
Current and cap Glue values are shown at the top of the screen.

Step 3: Press Space to go into Glue Time

Step 4. In Glue Time, bump into enemies to assimilate them.

Press Space when ready
]]

old_intro_text = 
[[



OK, important thing is that you kill things to collect glue (green drops).
When you have enough Glue you can go into Glue Time and capture extra balls by bumping into them.
Button to go into Glue Time (and also to close this text and start playing) is Space.
Rest of this text is just a lore, you can skip it if you want. 


===================== LORE STARTS HERE =====================

A long time ago, in a galaxy far away, a great battle happened.

Automatic space murdermashines were firing, smashing and hacking with glee, tearing each other's metalloceramic bodies and electronic souls apart.
At the end, all that remained was a huge field of debris and half-dead, half-insane robotic zombies, moving and attacking at random.
The battle and the war was declared a draw and a truce was signed, leading to a long, prosperious, boring period of peace.
A battlefiled was marked on all maps as "crazy robots - keep away" and left alone, deemed too dangerous to even approach.

Present day, still in a galaxy far away.
 
A certain prominent, but currently down on her luck space pirate has got some ideas about this battlefield of old.
Being an individual of exemplary enterpreneurship, though lacking a bit in self-preservance, she has decided that 
she will have all these undead robots at her command.

All of them.

Or, at least, all those of them that will survive the process of salvation.
And so, with a help of friend, she has captured one of the robots, and modified it, so it could connect to other robots and take them under control.
All that was needed for this was a hefty amount of "Space Glue" - a nanomachine liquid, that these ancient killbots were using for rapid self-repair.
Thankfully, it could be acquired in numbers by smashing these same machines.

And therefore, her ill-advised escapade begins. As soon as you press the Space button, that is.
]]

win_text = [[
YOU WIN

This demo, that is. There is not anything beyond that boss yet.

No compelling story and memorable heroes, no other levels, bosses, superweapons etc. But they will totally be in the full game.

But you can try to win on harder difficulty (adjusted with V/B buttons).

If you liked the game so far at least a bit, let me know and tell me what you want to see in the game when it's done.
I would really appreciate it 
 ]]


game_over_text_before_boss = [[
GAME OVER

And so, the pirate is dead. Well, not actually. You see, she has a time rewind button.
Have you ever wondered why all those action heroes risk their life each other minute, but survive well into several sequels?
Time rewind button. Just like the one our protagonist has. You can press it now too, if you want - it's button "K", for some reason.

Too bad you haven't seen the boss. It's big and mean. Killing, well, gluing it would give you a nicer message than this.
Boss appears if you survive for 5 minutes. You can try to adjust the difficulty with V/B buttons if you need.

Though, there is not anything beyond that boss yet. 

No compelling story and memorable heroes, no other levels, bosses, superweapons etc. But they will totally be in the full game.

If you liked the game so far at least a bit, let me know and tell me what you want to see in the game when it's done.
I would really appreciate it.
]]

game_over_text_on_boss = [[
GAME OVER

Well... At least you have seen the boss, so there is that. 
This demo has no checkpoints, so if you want to try again, you have to start from the sratch, sorry. 
You can try lower difficulty (adjusted with V/B buttons).

Full game, if by some coincidence it will be made, will have checkpoints, levels, bosses, superweapons, etc. Exactly 8 of each, because it's a theme.
And also balance, graphics, upgrades and all that other stuff that games use to trick you into playing basically the same stuff forever.

If you liked the demo so far at least a bit, let me know and tell me what you want to see in it.
I would really appreciate it.
]]

game_over_text = [[
Hmm, what else... Oh, have you figured what each ball type does? Ok, I'll tell you, it's simple.
First of all, each ball gives you a bonus to your main cannon. Namely, to it's projectile speed, damage and projectile life time.
Also each ball adds some value to your ship top glue value, acceleration and weight. For example, 3-ball has high acceleration bonus.
Balls have different durability, 4-ball is the sturdiest, and has damage reduction on top of that. So, try to build your outer layer out of it. 
2-ball shoots dumb shots, 5-ball shoots homing missiles. 6-ball is a magnet for glue drops.
7-ball is the trickiest - it gives hefty bonuses to nearby balls. Bonuses like ignoring part of the damage and shooting more often. 
This bonus drops with the square of distance. 

8-balls are local bosses. They usually appear at the end of the stages, as the centerpieces of the big ships. 
They are indestructible by any normal means, so you have to glue them. And you have to destroy all their entourage before being able to do that.

So, that's it for now. Press "K" and try to get a better time and please leave feedback, I need it.  
]] 

boss_tip = [[
A wild boss appears! There is a dreaded and coveted 8-ball at it's core. 
You are here to capture this ball, not destroy. But it can't be glued before it has any other balls connected.
So, first remove the shell, then glue the 8-ball.
]]

boss_nude_text = [[
Now glue this thing
]]