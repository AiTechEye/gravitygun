minetest.register_craftitem("gravitygun:zgc_active", {
	description = "Active zero gravity crystal",
	inventory_image = "gravitygun_zgc_active.png"
})
minetest.register_craftitem("gravitygun:zgc", {
	description = "Zero gravity crystal",
	inventory_image = "gravitygun_zgc.png",
})
minetest.register_craftitem("gravitygun:gun0", {
	description = "Gravitygun (no power)",
	inventory_image = "gravitygun_gun0.png",
})

minetest.register_craft({
	output = "gravitygun:gun0",
	recipe = {
		{"default:iron_lump", "default:steelblock", "default:steelblock"},
		{"", "default:steel_ingot", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "gravitygun:gun1",
	recipe = {
		{"gravitygun:zgc_active", "gravitygun:gun0"},
	}
})

minetest.register_craft({
	output = "gravitygun:gun2",
	recipe = {
		{"gravitygun:zgc_active","gravitygun:zgc_active", "gravitygun:gun1"},
	}
})

minetest.register_craft({
	output = "gravitygun:gun3",
	recipe = {
		{"gravitygun:zgc_active","gravitygun:zgc_active", ""},
		{"gravitygun:zgc_active","gravitygun:zgc_active", "gravitygun:gun2"}
	}
})

minetest.register_craft({
	output = "gravitygun:zgc",
	recipe = {
		{"default:obsidianbrick", "default:copper_lump", "default:obsidianbrick"},
		{"default:copper_lump", "default:diamond", "default:copper_lump"},
		{"default:obsidianbrick", "default:copper_lump", "default:obsidianbrick"}
	}
})


minetest.register_craft({
	type = "fuel",
	recipe = "gravitygun:zgc_active",
	burntime = 400,
})
minetest.register_craft({
	type = "cooking",
	output = "gravitygun:zgc_active",
	recipe = "gravitygun:zgc",
})