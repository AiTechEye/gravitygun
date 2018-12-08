enable_gravitygun_requires_privilege_to_hold_players=true
enable_gravitygun_throw_stuff_destroys=true
enable_gravitygun_basic=true
enable_gravitygun=true
enable_gravitygun_requires_privilege=false
enable_gravitygun_owerloaded=true
enable_gravitygun_owerloaded_requires_privilege=true

minetest.register_privilege("gravitygun", {
	description = "Gravitygun privilege",
	give_to_singleplayer= true})
minetest.register_privilege("gravitygun2", {
	description = "Gravitygun overloaded privilege",
	give_to_singleplayer= true})
dofile(minetest.get_modpath("gravitygun") .. "/entitys.lua")
dofile(minetest.get_modpath("gravitygun") .. "/craft.lua")
gravitygun_slowdown={}

if enable_gravitygun_owerloaded then
minetest.register_tool("gravitygun:gun3", {
	description = "Gravitygun basic (overloaded)",
	range = 5,
	inventory_image = "gravitygun_gun3.png",
		on_use = function(itemstack, user, pointed_thing)
			if enable_gravitygun_owerloaded_requires_privilege and minetest.check_player_privs(user:get_player_name(), {gravitygun2=true})==false then
				minetest.chat_send_player(user:get_player_name(), "You need the gravitygun2 privilege to use this")
				return itemstack
			end

			local obs={}
			local item=user:get_wielded_item():get_name():split(":")[2]
			local powers={}
			local name=user:get_player_name()
			local pos={}
			local y=1
			if pointed_thing.type=="node" then
				if gravitygun_slowdown_user(user)==false then
					return itemstack
				end
				pos=pointed_thing.above
				y=2
			elseif pointed_thing.type=="object" then
				pos=pointed_thing.ref:get_pos()
			elseif pointed_thing.type=="nothing" then
				pos=user:get_pos()
				local dir=user:get_look_dir()
				pos={x=pos.x+(dir.x*2), y=pos.y+(dir.y*2)+1, z=pos.z+(dir.z*2)}
				y=2
			else
				return itemstack
			end
		if pointed_thing.type~="node" then
			for i, ob in pairs(minetest.get_objects_inside_radius(pos, 5)) do
				if (ob:get_luaentity() and ob:get_luaentity().ggunpower==nil) or ob:get_player_name()~=name then
					gravitygun_power.item=item
					gravitygun_power.user=user
					local obpos=ob:get_pos()
					ob:move_to({x=obpos.x,y=obpos.y+y,z=obpos.z})
					gravitygun_power.target=ob
					local m=minetest.add_entity(ob:get_pos(), "gravitygun:power")
					ob:set_attach(m, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
					table.insert(powers,m)
				end
			end
			for i, ob in pairs(powers) do
				ob:right_click(user)
			end
			minetest.sound_play("gravitygun_grabnodesend_massive1", {pos=pos,max_hear_distance = 10, gain = 1})
			return  itemstack
		else
			for i=1,20,1 do
				local np=minetest.find_node_near(pos, 2,{
					"group:snappy",
					"group:wood",
					"group:choppy",
					"group:tree",
					"group:level",
					"group:crumbly",
					"group:falling_node",
					"group:sand",
					"group:dig_immediate",
					"group:flammable",
					"group:water",
					"group:liquid ",
					"group:oddly_breakable_by_hand",
					"group:soil",
					"group:cracky",
					"group:stone"
				})
				if np~=nil and minetest.is_protected(np,user:get_player_name())==false then
					local obn=gravitygun_spawn_block(np)
					if not obn.notable then
						table.insert(obs,obn)
					end
				else
					break
				end
			end
			for i, ob in pairs(obs) do
				gravitygun_power.item=item
				gravitygun_power.user=user
				gravitygun_power.target=ob
				local m=minetest.add_entity(ob:get_pos(), "gravitygun:power")
				ob:set_attach(m, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
				table.insert(powers,m)
			end
			for i, ob in pairs(powers) do
				ob:right_click(user)
			end
			minetest.sound_play("gravitygun_grabnodesend_massive2", {pos=pos,max_hear_distance = 10, gain = 1})
		end
		return itemstack
	end,
})
end

if enable_gravitygun==true then
minetest.register_tool("gravitygun:gun2", {
	description = "Gravitygun",
	range = 10,
	inventory_image = "gravitygun_gun2.png",
	on_use = function(itemstack, user, pointed_thing)
		if enable_gravitygun_requires_privilege and minetest.check_player_privs(user:get_player_name(), {gravitygun=true})==false then
			minetest.chat_send_player(user:get_player_name(), "You need the gravitygun privilege to use this")
			return itemstack
		end
		gravitygun_onuse(itemstack, user, pointed_thing,2)
		return itemstack
	end,
})
end
if enable_gravitygun_basic then
minetest.register_tool("gravitygun:gun1", {
	description = "Gravitygun (basic)",
	range = 5,
	inventory_image = "gravitygun_gun1.png",
	on_use = function(itemstack, user, pointed_thing)
		gravitygun_onuse(itemstack, user, pointed_thing,1)
			return itemstack
	end,
})
end


function gravitygun_onuse(itemstack, user, pointed_thing,type)
	local ob={}
	local pos=user:get_pos()
	if user:get_attach() then return itemstack end

	if pointed_thing.type=="object" then
		ob=pointed_thing.ref
	elseif pointed_thing.type=="node" and minetest.is_protected(pointed_thing.above,user:get_player_name())==false then
		ob=gravitygun_spawn_block(pointed_thing.under)
		if ob.notable then
			return itemstack
		end
	else
		return itemstack
	end

	if ob:get_luaentity() and ob:get_luaentity().ggunpower then
		local player_name=user:get_player_name()
		local target=ob:get_luaentity().target
		if ob:get_luaentity().user:get_player_name()==player_name
		and not (target:get_luaentity() and target:get_luaentity().block) then
		minetest.sound_play("gravitygun_grabnodedrop", {pos=pos,max_hear_distance = 5, gain = 1})
			target:set_detach()
			if target:get_luaentity() then
				target:set_velocity({x=0, y=-2, z=0})
				target:set_acceleration({x=0, y=-8, z=0})
			end

			return itemstack
		elseif target:get_luaentity() and target:get_luaentity().block
		and ob:get_luaentity().user:get_player_name()==player_name then
			local pos=ob:get_pos()
			if minetest.registered_nodes[minetest.get_node(pos).name].walkable==false
			and minetest.is_protected(pos,player_name)==false then
			if minetest.registered_nodes[target:get_luaentity().drop] then
				minetest.set_node(pos,{name=target:get_luaentity().drop})
			else
				minetest.add_item(pos, target:get_luaentity().drop)
			end
			target:set_detach()
			target:set_hp(1)
			target:punch(target, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
			minetest.sound_play("gravitygun_grabnodedrop", {pos=pos,max_hear_distance = 5, gain = 1})
			end

		end

	if ob:get_luaentity().target:get_luaentity() and ob:get_luaentity().target:get_luaentity().itemstring then
		ob:get_luaentity().target:set_velocity({x=0, y=-2, z=0})
		ob:get_luaentity().target:set_acceleration({x=0, y=-8, z=0})
		minetest.sound_play("gravitygun_grabnodedrop", {pos=pos,max_hear_distance = 5, gain = 1})
	end
	return  itemstack
	end

	if (not ob:get_attach()) and not (ob:get_luaentity() and ob:get_luaentity().ggunpower) then
		if (not ob:get_luaentity()) and enable_gravitygun_requires_privilege_to_hold_players and minetest.check_player_privs(user:get_player_name(), {gravitygun=true})==false then
			minetest.chat_send_player(user:get_player_name(), "You need the gravitygun privilege to hold players")
			return itemstack
		end
		gravitygun_power.item=user:get_wielded_item():get_name():split(":")[2]
		gravitygun_power.user=user
		gravitygun_power.target=ob
		local m=minetest.add_entity(ob:get_pos(), "gravitygun:power")
		ob:set_attach(m, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
		if user:get_player_control().RMB then m:right_click(user)
		else
			minetest.sound_play("gravitygun_grabnode", {pos=pos,max_hear_distance = 5, gain = 1})
		end
		return  itemstack
	end
	return itemstack
end

function gravitygun_slowdown_user(user)
	local name=user:get_player_name()
	if gravitygun_slowdown[name]~=nil then
		return false
	end
	gravitygun_slowdown[name]=1
	minetest.after(2, function(name)
		gravitygun_slowdown[name]=nil
	end, name)
	return true
end
