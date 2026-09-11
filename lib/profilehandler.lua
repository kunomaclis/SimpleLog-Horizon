local status = {
	PlayerId = 0,
	PlayerJob = 0,
	PlayerName = '',
	SettingsFolder = nil,
	CurrentFilters = nil;
	FilterWarning = nil;
	FilterSavingDisabled = false;
};

Self = nil;
SelfPlayer = nil;

local function LoadTable(path)
	local chunk, loadError = loadfile(path)
	if not chunk and ashita.fs.exists(path .. '.bak') then
		os.rename(path .. '.bak', path)
		chunk, loadError = loadfile(path)
	end
	if not chunk then
		return nil, loadError
	end
	local ok, profile = pcall(chunk)
	if not ok then
		return nil, profile
	end
	if type(profile) ~= 'table' then
		return nil, 'Profile must return a table.'
	end
	return profile
end

local filter_actors = {
	{'me', 'Player'},
	{'party', 'Party members'},
	{'alliance', 'Alliance members'},
	{'others', 'Players outside your group'},
	{'my_pet', 'Your pet'},
	{'my_fellow', 'Your fellow'},
	{'other_pets', 'Pets outside your group'},
	{'enemies', 'Claimed enemies'},
	{'monsters', 'Unclaimed monsters'},
}

local filter_targets = {
	{'me', 'you'},
	{'party', 'party members and their pets'},
	{'alliance', 'alliance members and their pets'},
	{'others', 'players outside your group'},
	{'my_pet', 'your pet'},
	{'my_fellow', 'your fellow'},
	{'other_pets', 'pets outside your group'},
	{'enemies', 'claimed enemies'},
	{'monsters', 'unclaimed monsters'},
}

local function ValidateFilterRow(row, label)
	if type(row) ~= 'table' then
		return false, label .. ' settings are missing.'
	end
	for key, value in pairs(row) do
		if type(value) ~= 'boolean' then
			return false, label .. ' has an invalid ' .. tostring(key) .. ' setting.'
		end
	end
	return true
end

local function ValidateNestedActor(actor, actor_label)
	for _, target in ipairs(filter_targets) do
		local valid, validationError = ValidateFilterRow(
			actor[target[1]], actor_label .. ' targeting ' .. target[2])
		if not valid then
			return false, validationError
		end
	end
	for key, value in pairs(actor) do
		if type(value) ~= 'table' then
			return false, actor_label .. ' cannot mix general and target-specific settings.'
		end
	end
	return true
end

local function ValidateFilterActor(profile, actor_key, actor_label)
	local actor = profile[actor_key]
	if type(actor) ~= 'table' then
		return false, actor_label .. ' settings are missing.'
	end

	if actor_key == 'enemies' or actor_key == 'monsters' then
		return ValidateNestedActor(actor, actor_label)
	elseif actor_key ~= 'other_pets' then
		return ValidateFilterRow(actor, actor_label)
	end

	local has_rows = false
	local has_settings = false
	for _, value in pairs(actor) do
		if type(value) == 'table' then
			has_rows = true
		else
			has_settings = true
		end
	end
	if has_rows and has_settings then
		return false, actor_label .. ' cannot mix general and target-specific settings.'
	elseif has_rows then
		return ValidateNestedActor(actor, actor_label)
	end
	return ValidateFilterRow(actor, actor_label)
end

local function IsProfileValid(profile, profileType)
	if profileType == 'config' then
		local valid = type(profile.lang) == 'table'
			and type(profile.mode) == 'table'
			and type(profile.text) == 'table'
		return valid, valid and nil or 'Configuration is missing required settings.'
	elseif profileType == 'filters' then
		for _, actor in ipairs(filter_actors) do
			local valid, validationError = ValidateFilterActor(profile, actor[1], actor[2])
			if not valid then
				return false, validationError
			end
		end
		return true
	elseif profileType == 'colors' then
		local valid = next(profile) ~= nil
		return valid, valid and nil or 'Color profile is empty.'
	end
	return false, 'Unknown profile type.'
end

status.Init = function()
	if (AshitaCore:GetMemoryManager():GetParty():GetMemberIsActive(0) == 1) then
		Self = GetPlayerEntity()
		SelfPlayer = AshitaCore:GetMemoryManager():GetPlayer()
		gStatus.PlayerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
		gStatus.PlayerName = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);
		gStatus.PlayerJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
		gStatus.SettingsFolder = ('%sconfig\\addons\\simplelog\\%s_%u\\'):fmt(AshitaCore:GetInstallPath(), gStatus.PlayerName, gStatus.PlayerId);
		gStatus.AutoLoadProfile();

		if (get_weapon_skill == nil or get_spell == nil or get_item == nil) then
			gFuncs.PopulateSkills()
			gFuncs.PopulateSpells()
			gFuncs.PopulateItems()
		end
	end
end

status.AutoLoadProfile = function()
	static_config = false
	gStatus.FilterWarning = nil
	gStatus.FilterSavingDisabled = false
	local defaultSettingsFile = gStatus.SettingsFolder .. 'config.lua';
	local defaultFiltersFile = gStatus.SettingsFolder .. 'default_filters.lua';
	local defaultColorsFile = gStatus.SettingsFolder .. 'chat_colors.lua';
	local jobFiltersFile = (gStatus.SettingsFolder .. '%s.lua'):fmt(AshitaCore:GetResourceManager():GetString("jobs.names_abbr", gStatus.PlayerJob));
	
	if (not ashita.fs.exists(defaultSettingsFile)) then
		gFileTools.CreateNewProfile(defaultSettingsFile, 'configuration');
		print(chat.header('SimpleLog') .. chat.message('Created config file: ') .. chat.color1(2, 'config.lua'));
		gStatus.LoadProfile(defaultSettingsFile, 'config');
	elseif (ashita.fs.exists(defaultSettingsFile)) then
		gStatus.LoadProfile(defaultSettingsFile, 'config');	
	end
	
	if (not ashita.fs.exists(jobFiltersFile)) then
		if (not ashita.fs.exists(defaultFiltersFile)) then
			gFileTools.CreateNewProfile(defaultFiltersFile, 'filters');
			print(chat.header('SimpleLog') .. chat.message('Created filters profile: ') .. chat.color1(2, 'default_filters.lua'));
			gStatus.LoadProfile(defaultFiltersFile, 'filters');
		elseif (ashita.fs.exists(defaultFiltersFile)) then
			gStatus.LoadProfile(defaultFiltersFile, 'filters');
		end
	elseif (ashita.fs.exists(jobFiltersFile)) then
		gStatus.LoadProfile(jobFiltersFile, 'filters');	
	end
	
	if (not ashita.fs.exists(defaultColorsFile)) then
		gFileTools.CreateNewProfile(defaultColorsFile, 'colors');
		print(chat.header('SimpleLog') .. chat.message('Created color profile: ') .. chat.color1(2, 'chat_colors.lua'));
		gStatus.LoadProfile(defaultColorsFile, 'colors');
	elseif (ashita.fs.exists(defaultColorsFile)) then
		gStatus.LoadProfile(defaultColorsFile, 'colors');	
	end
end

status.LoadProfile = function(profilePath, profileType)
    local shortFileName = profilePath:match("[^\\]*.$");
    local profile, loadError = LoadTable(profilePath);
	if profile then
		local valid, validationError = IsProfileValid(profile, profileType)
		if not valid then
			profile = nil
			loadError = validationError
		end
	end

	if (profileType == 'config') then
		if not profile then
			gProfileSettings = static_settings;
			print(chat.header('SimpleLog') .. chat.error('Failed to load configuration file: ') .. chat.color1(2, shortFileName)..chat.error('\nSaving will be disabled.'));
			print(chat.header('SimpleLog') .. chat.error(loadError));
			static_config = true
			return;
		end
		gProfileSettings = profile;
		if (gProfileSettings ~= nil) then
			print(chat.header('SimpleLog') .. chat.message('Loaded configuration file: ') .. chat.color1(2, shortFileName));
		end
	end
	
	if (profileType == 'filters') then
		gFuncs.ResetFilterDiagnostics()
		if not profile then
			local defaultFiltersFile = gStatus.SettingsFolder .. 'default_filters.lua';
			gStatus.FilterWarning = {
				Profile = shortFileName,
				Reason = tostring(loadError),
			}
			print(chat.header('SimpleLog') .. chat.error('Failed to load filters profile: ') .. chat.color1(2, shortFileName) .. chat.error(' loading defaults: ' .. chat.color1(2, 'default_filters.lua')));
			print(chat.header('SimpleLog') .. chat.error(loadError));
			local default_profile, default_loadError = LoadTable(defaultFiltersFile)
			if default_profile then
				local valid, validationError = IsProfileValid(default_profile, 'filters')
				if not valid then
					default_profile = nil
					default_loadError = validationError
				end
			end
			if not default_profile then
				gProfileFilter = static_filters;
				gStatus.CurrentFilters = 'Built-in defaults (read-only)'
				print(chat.header('SimpleLog') .. chat.error('Failed to load filters profile: ') .. chat.color1(2, 'default_filters.lua')..chat.error('\nSaving will be disabled.'));
				print(chat.header('SimpleLog') .. chat.error(default_loadError));
				gStatus.FilterSavingDisabled = true
				return
			end
			gProfileFilter = default_profile;
			gStatus.CurrentFilters = 'default_filters.lua'
			gStatus.FilterSavingDisabled = false
			return;
		else
			gProfileFilter = profile;
			gStatus.FilterWarning = nil
			gStatus.FilterSavingDisabled = false
		end
		if (gProfileFilter ~= nil) then
			print(chat.header('SimpleLog') .. chat.message('Loaded filters profile: ') .. chat.color1(2, shortFileName));
			gStatus.CurrentFilters = shortFileName
		end
	end
	
	if (profileType == 'colors') then
		if not profile then
			gProfileColor = static_colors;
			print(chat.header('SimpleLog') .. chat.error('Failed to load colors profile: ') .. chat.color1(2, shortFileName)..chat.error('\nSaving will be disabled.'));
			print(chat.header('SimpleLog') .. chat.error(loadError));
			static_config = true
			return;
		end
		gProfileColor = profile;
		if (gProfileColor ~= nil) then
			print(chat.header('SimpleLog') .. chat.message('Loaded colors profile: ') .. chat.color1(2, shortFileName));
		end
	end
end

return status;