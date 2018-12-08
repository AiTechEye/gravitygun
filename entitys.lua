gravitygun_power={}
gravitygun_item_time=tonumber(minetest.settings:get("item_entity_ttl"))
if not gravitygun_item_time then
	gravitygun_item_time=880
else
	gravitygun_item_time=gravitygun_item_time-20
end

minetest.register_entity("gravitygun:power",{
	hp_max = 100,
	physical = true,
	weight = 0,
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	visual = "sprite",
	visual_size = {x=1, y=1},
	textures = {"gravitygun_gravity.png"},
	spritediv = {x=1, y=1},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
	timer=0,
	time=0.2,
	timer2=0,
	time2=10,
	ggunpower=1,
	throw=0,
	throw_timer=0,
	throw_time=4,
	dir={},
	opos=0,
	damage=1,
	ignore=0,
on_activate=function(self, staticdata)
		if gravitygun_power.user then
			self.target=gravitygun_power.target
			self.user=gravitygun_power.user
			self.item=gravitygun_power.item
			gravitygun_power={}
			local c=self.target:get_properties().collisionbox
			if c~=nil then
				self.object:set_properties({collisionbox=c})
				local a1=c[1]+c[2]+c[3]
				local a2=c[4]+c[5]+c[6]
				if a1<a2 then a1=a2 end
				self.damage=a1*10
			end
		else
			self.object:remove()
		end
	end,
on_rightclick=function(self, clicker)
		if clicker:get_player_name()==self.user:get_player_name() then
			local item=self.user:get_wielded_item():get_name()
			if item=="gravitygun:gun2" or item=="gravitygun:gun3" then
			local dir=self.user:get_look_dir()
			self.dir=dir
			if self.target:get_luaentity() and self.target:get_luaentity().itemstring then
				self.target:get_luaentity().age=gravitygun_item_time
			end
			local pos=self.object:get_pos()
			self.time=10
			self.object:set_velocity({x=dir.x*45, y=dir.y*45, z=dir.z*45})
			self.throw=1
			self.time=0
			if self.item~="gun3" then
				minetest.sound_play("gravitygun_grabnodesend", {pos=pos,max_hear_distance = 7, gain = 1})
			end
			end
		end
		end,
on_step= function(self, dtime)
	self.timer=self.timer+dtime
	if self.timer<self.time then return self end
	self.timer=0

	if self.throw==0 then
		if self.user:get_wielded_item():get_name():find(self.item,11)==nil then
			self.target:set_detach()
			self.target:set_velocity({x=0, y=-2, z=0})
			self.target:set_acceleration({x=0, y=-8, z=0})
		end
		if self.target==nil or (not self.target:get_attach()) then
			self.object:set_hp(0)
			self.object:punch(self.object, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
			if self.sound then minetest.sound_stop(self.sound) end
		end
		local d=4
		local pos = self.user:get_pos()
		if pos==nil then return self end

		if self.user:get_hp()<1 then self.target:set_detach() end

		local dir = self.user:get_look_dir()
		local npos={x=pos.x+(dir.x*d), y=pos.y+(dir.y*d)+1.6, z=pos.z+(dir.z*d)}

		local opos=npos.x+npos.y+npos.z
		if opos~=self.opos then
			self.opos=opos
			self.timer2=0
		else
		self.timer2=self.timer2+dtime
			if self.timer2>self.time2 then self.target:set_detach() end
		end

		if minetest.registered_nodes[minetest.get_node(npos).name].walkable then
			self.object:set_velocity({x=0,y=0,z=0})
			return self
		end
		if self.autoglitchfix then -- becaouse model sizes more then 200kb making it glitch >_<
			self.object:move_to(npos)
			return self
		else
			local ta=self.target:get_pos()
			if ta==nil then return self end
			local v={x = (npos.x - ta.x)*4, y = (npos.y - ta.y)*4, z = (npos.z - ta.z)*4}
			if npos.y - ta.y>2 or npos.y - ta.y<-3 then
				self.time=0.1
				self.autoglitchfix=1
				self.object:set_velocity({x=0,y=0,z=0})
				return self
			end
			self.object:set_velocity(v)
		end
	else
		self.throw_timer=self.throw_timer+dtime
		local v=self.object:get_velocity()
		local pos=self.object:get_pos()

		if enable_gravitygun_throw_stuff_destroys then
			local vpos={x=pos.x+(v.x*0.07),y=pos.y+(v.y*0.07),z=pos.z+(v.z*0.07)}
			if minetest.registered_nodes[minetest.get_node(vpos).name]==nil then return self end
			if minetest.registered_nodes[minetest.get_node(vpos).name].walkable and minetest.is_protected(vpos,self.user:get_player_name())==false then
				local obn=gravitygun_spawn_block(vpos)
				if not obn.notable then
					local sv={x=v.x*0.9,y=v.y*0.9,z=v.z*0.9}
					obn:set_velocity(sv)
					self.object:set_velocity(sv)
				end
			end
		end

		for i, ob in pairs(minetest.get_objects_inside_radius(pos, 1.7)) do
			if ((ob:is_player() and ob:get_player_name()~=self.user:get_player_name()) or (ob:get_luaentity() and ob:get_luaentity().ggunpower==nil)) and (not ob:get_attach()) then
				local igpos=ob:get_pos()
				igpos=math.floor(igpos.x+igpos.y+igpos.z)
				if igpos~=self.ignore then
					self.ignore=igpos
					ob:punch(ob, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
					ob:set_hp(ob:get_hp()-self.damage)
					if (not ob:get_attach()) and (ob:get_hp()>0 or ob:is_player()) then
						local c=ob:get_properties().collisionbox
						if c~=nil then
							local a1=c[1]+c[2]+c[3]
							local a2=c[4]+c[5]+c[6]
							if a1<a2 then a1=a2 end
							if a1<=self.damage then
							local objpos=ob:get_pos()
								gravitygun_power.item=self.item
								gravitygun_power.user=self.user
								gravitygun_power.target=ob
								local m=minetest.add_entity(objpos, "gravitygun:power")
								ob:set_attach(m, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
								local v=self.object:get_velocity()
								if minetest.get_node({x=objpos.x,y=objpos.y-1,z=objpos.z}).name~="air" then
									m:move_to({x=objpos.x,y=objpos.y+0.2,z=objpos.z})
								end
								local sv={x=v.x*0.9,y=v.y*0.9,z=v.z*0.9}
								self.object:set_velocity(sv)
								m:right_click(self.user)
							end
						end
					end
				end
			end
		end
		if (v.x>-25 and v.x<25)
		and (v.y>-25 and v.y<25)
		and (v.z>-25 and v.z<25) then
			if self.target:get_luaentity() and self.target:get_luaentity().itemstring then
				self.target:get_luaentity().age=gravitygun_item_time
			end
			self.target:set_detach()
			self.target:set_hp(self.target:get_hp()-self.damage)
			self.target:punch(self.target, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
			self.throw_timer=self.throw_time
		end
		if self.throw_timer>=self.throw_time then
			self.target:set_detach()
			if self.target~=nil and self.target:get_luaentity() then
				self.target:set_velocity({x=self.dir.x*25, y=self.dir.y*25, z=self.dir.z*25})
				self.target:set_acceleration({x=0, y=-4, z=0})
			end
			self.object:set_hp(0)
			self.object:punch(self.object, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
		end
	end
	return self
	end,
})

function gravitygun_spawn_block(pos)
	local node=minetest.registered_nodes[minetest.get_node(pos).name]
	if node==nil then return {notable=true} end
	if minetest.get_node_group(node.name, "unbreakable")>0 or (
	minetest.get_node_group(node.name, "fleshy")==0 and
	minetest.get_node_group(node.name, "choppy")==0 and
	minetest.get_node_group(node.name, "bendy")==0 and
	minetest.get_node_group(node.name, "cracky")==0 and
	minetest.get_node_group(node.name, "crumbly")==0 and
	minetest.get_node_group(node.name, "snappy")==0 and
	minetest.get_node_group(node.name, "oddly_breakable_by_hand")==0 and
	minetest.get_node_group(node.name, "dig_immediate")==0)
	then return {notable=true} end

	if minetest.get_meta(pos):get_string("infotext")~="" then return {notable=true} end

	gravitygun_power={drop="",new=1}
	minetest.set_node(pos, {name = "air"})

	if node.drop=="" or node.drop==nil then 
		gravitygun_power.drop=node.name
	elseif node.drop.items and node.drop.items[1].items then
		if minetest.registered_nodes[node.drop.items[2].items[1]] then
			gravitygun_power.drop=node.drop.items[2].items[1]
		elseif minetest.registered_nodes[node.drop.items[1].items[1]] then
			gravitygun_power.drop=node.drop
		else
			gravitygun_power.drop=node.drop
		end
	else
		gravitygun_power.drop=node.drop
	end
	local tiles={}
	local stop=0
	for i, t in pairs(node.tiles) do
		tiles[i]=t
		stop=stop+1
		if type(tiles[i])~="string" then
		if stop==1 then tiles[i]="default_dirt.png" end
			stop=stop-1
			break
		end
	end

	for i=stop,6,1 do
		tiles[i]=tiles[stop] 
	end

	local type=node.drawtype
	if type=="nodebox" and node.node_box then
		if node.node_box.type=="regular" or
		node.node_box.type=="wallmounted" or
		node.node_box.type=="fixed" then type="normal" end
	end
	if type~="plantlike" and type~="signlike" and type~="raillike" and type~="torchlike" and type~="mesh" and type~="fencelike" then type="normal" end
	if node.name:find("slab_",1) or node.name:find("_slab",1) or node.name:find("sign",1) or node.name=="default:snow" then type="slab" end
	if node.name:find("stair_",1) or node.name:find("_stair",1) then type="stair" end

	local m=minetest.add_entity(pos, "gravitygun:block")
	m:set_properties({textures = tiles})

	if type=="plantlike" or type=="torchlike" then m:set_properties({visual="sprite"}) end
	if type=="signlike" or type=="raillike" then m:set_properties({visual="upright_sprite"}) end
	if type=="mesh" then
		local npos={}
		npos.x=node.wield_scale.x*2
		npos.y=node.wield_scale.y*2
		npos.z=node.wield_scale.z*2
		m:set_properties({collisionbox=node.selection_box.fixed})
		m:set_properties({visual="mesh"})
		m:set_properties({mesh=node.mesh})
		m:set_properties({visual_size=npos})
		colision=node.selection_box.fixed
	end
	if type=="fencelike" then
		local npos={}
		npos.x=node.wield_scale.x*0.3
		npos.y=node.wield_scale.y*1
		npos.z=node.wield_scale.z*0.3
		m:set_properties({visual_size=npos})
	end

	if type=="stair" then
		local npos={}
		npos.x=node.wield_scale.x*10
		npos.y=node.wield_scale.y*10
		npos.z=node.wield_scale.z*10
		m:set_properties({visual="mesh"})
		m:set_properties({mesh="stairs_stair.obj"})
		m:set_properties({visual_size=npos})
	end
	if type=="slab" then
		local npos={}
		npos.x=node.wield_scale.x*1
		npos.y=node.wield_scale.y*0.4
		npos.z=node.wield_scale.z*1
		m:set_properties({visual_size=npos})
	end
	if node.selection_box.wall_side then
		m:set_properties({collisionbox=node.selection_box.wall_side})
	end
	if node.selection_box.fixed then
		local colbox=node.selection_box.fixed
		if  colbox and tonumber(colbox[1])~=nil then -- and colbox[1][1]==nil
			m:set_properties({collisionbox={colbox[1],colbox[2],colbox[3],colbox[4],colbox[5]+0.4,colbox[6]}})
		elseif colbox and colbox[1]~=nil and colbox[1][1]~=nil then
			m:set_properties({collisionbox={colbox[1][1],colbox[1][2],colbox[1][3],colbox[1][4],colbox[1][5]+0.4,colbox[1][6]}})
		end
	end
	return m
end


minetest.register_entity("gravitygun:block",{
	hp_max = 30,
	physical = true,
	weight = 0,
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "cube",
	visual_size = {x=1, y=1},
	textures = {},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		local pos=self.object:get_pos()
		if self.object:get_hp()==1 then
			self.drop=""
			self.timer=1
			self.timer2=10
		elseif pos~=nil and self.object:get_hp()<=0 and self.drop~="" then
			local it=minetest.add_item(pos, self.drop)
			it:get_luaentity().age=gravitygun_item_time
			return self
		end
	end,
on_activate=function(self, staticdata)
		if not gravitygun_power.new then
			self.object:remove()
			return false
		end
		self.drop=gravitygun_power.drop
		gravitygun_power={}
	end,
on_step= function(self, dtime)
		self.timer=self.timer+dtime
		if self.timer<0.5  then return self end
		if self.object:get_attach() then return self end
		self.timer=0
		self.timer2=self.timer2+1
		local pos=self.object:get_pos()
		if self.timer2>10 then
			self.object:set_hp(0)
			self.object:punch(self.object, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
			return self
		end
	end,
	timer=0,
	timer2=0,
	drop="",
	block=1,
})
