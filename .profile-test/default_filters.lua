local function hide_all()
	return {
		ranged = true,
		uses = true,
		all = true,
		healing = true,
		casting = true,
		melee = true,
		misses = true,
		damage = true,
		readies = true,
		items = true,
	};
end

local function telegraphs_only()
	return {
		ranged = true,
		uses = true,
		all = false,
		healing = true,
		casting = false,
		melee = true,
		misses = true,
		damage = true,
		readies = false,
		items = true,
		other = true,
	};
end

local function enemy_targets()
	return {
		me = telegraphs_only(),
		party = telegraphs_only(),
		alliance = telegraphs_only(),
		others = telegraphs_only(),
		my_pet = telegraphs_only(),
		my_fellow = telegraphs_only(),
		other_pets = telegraphs_only(),
		enemies = telegraphs_only(),
		monsters = telegraphs_only(),
	};
end

local function monster_targets()
	return {
		me = telegraphs_only(),
		my_pet = telegraphs_only(),
		monsters = telegraphs_only(),
		party = hide_all(),
		alliance = hide_all(),
		others = hide_all(),
		my_fellow = hide_all(),
		other_pets = hide_all(),
		enemies = hide_all(),
	};
end

local filters = T{
	me = {
		ranged = true,
		uses = true,
		all = false,
		target = true,
		healing = true,
		casting = false,
		melee = true,
		misses = false,
		damage = false,
		readies = true,
		items = true,
	},
	party = hide_all(),
	alliance = hide_all(),
	others = hide_all(),
	my_pet = hide_all(),
	my_fellow = hide_all(),
	other_pets = hide_all(),
	enemies = enemy_targets(),
	monsters = monster_targets(),
};

return filters;
