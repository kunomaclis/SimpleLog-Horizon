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

local function targeting_me()
	local filters = telegraphs_only()
	filters.ranged = false
	filters.melee = false
	filters.damage = false
	filters.other = false
	return filters
end

local function targeting_my_pet()
	local filters = telegraphs_only()
	filters.damage = false
	filters.other = false
	return filters
end

local function my_pet_without_misses()
	return {
		ranged = false,
		uses = false,
		all = false,
		healing = false,
		casting = false,
		melee = false,
		misses = true,
		damage = false,
		readies = false,
		items = true,
		other = false,
	};
end

local function enemy_targets()
	return {
		me = targeting_me(),
		party = telegraphs_only(),
		alliance = telegraphs_only(),
		others = telegraphs_only(),
		my_pet = targeting_my_pet(),
		my_fellow = telegraphs_only(),
		other_pets = telegraphs_only(),
		enemies = telegraphs_only(),
		monsters = telegraphs_only(),
	};
end

local function monster_targets()
	return {
		me = targeting_me(),
		my_pet = targeting_my_pet(),
		monsters = telegraphs_only(),
		party = telegraphs_only(),
		alliance = telegraphs_only(),
		others = hide_all(),
		my_fellow = targeting_my_pet(),
		other_pets = hide_all(),
		enemies = hide_all(),
	};
end

local function ambiguous_pet_targets()
	return {
		me = targeting_me(),
		my_pet = targeting_my_pet(),
		party = telegraphs_only(),
		alliance = telegraphs_only(),
		others = hide_all(),
		my_fellow = targeting_my_pet(),
		other_pets = hide_all(),
		enemies = hide_all(),
		monsters = hide_all(),
	};
end

local filters = T{
	me = {
		ranged = true,
		uses = true,
		all = false,
		target = true,
		healing = false,
		casting = false,
		melee = false,
		misses = false,
		damage = false,
		readies = true,
		items = true,
	},
	party = hide_all(),
	alliance = hide_all(),
	others = hide_all(),
	my_pet = my_pet_without_misses(),
	my_fellow = hide_all(),
	other_pets = ambiguous_pet_targets(),
	enemies = enemy_targets(),
	monsters = monster_targets(),
};

return filters;
