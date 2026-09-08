local CreateDirectories = function(path)
    local backSlash = string.byte('\\');
    for c = 1,#path,1 do
        if (path:byte(c) == backSlash) then
            local directory = string.sub(path,1,c);            
            if (ashita.fs.create_directory(directory) == false) then
                gFuncs.Error('Failed to create directory: ' .. directory);
                return false;
            end
        end
    end
    return true;
end

local ReadAll = function(path)
    local file, openError = io.open(path, 'rb')
    if not file then
        return nil, openError
    end
    local data = file:read('*all')
    file:close()
    return data
end

local AtomicWrite = function(path, data)
    local tempPath = path .. '.tmp'
    local backupPath = path .. '.bak'
    local file, openError = io.open(tempPath, 'wb')
    if not file then
        gFuncs.Error('Failed to access file: ' .. tempPath .. ': ' .. tostring(openError))
        return false
    end

    local written, writeError = file:write(data)
    file:close()
    if not written then
        os.remove(tempPath)
        gFuncs.Error('Failed to write file: ' .. tempPath .. ': ' .. tostring(writeError))
        return false
    end

    local hadOriginal = ashita.fs.exists(path)
    if hadOriginal then
        os.remove(backupPath)
        local moved, moveError = os.rename(path, backupPath)
        if not moved then
            os.remove(tempPath)
            gFuncs.Error('Failed to back up file: ' .. path .. ': ' .. tostring(moveError))
            return false
        end
    end

    local installed, installError = os.rename(tempPath, path)
    if not installed then
        if hadOriginal then
            os.rename(backupPath, path)
        end
        os.remove(tempPath)
        gFuncs.Error('Failed to replace file: ' .. path .. ': ' .. tostring(installError))
        return false
    end

    if hadOriginal then
        os.remove(backupPath)
    end
    return true
end

local SerializeValue
SerializeValue = function(value, indent)
    local valueType = type(value)
    if valueType == 'table' then
        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        local lines = {'T{\n'}
        local childIndent = indent .. '\t'
        for _, key in ipairs(keys) do
            local keyText = type(key) == 'string' and key:match('^[%a_][%w_]*$')
                and key or ('[' .. string.format('%q', key) .. ']')
            lines[#lines + 1] = childIndent .. keyText .. ' = '
                .. SerializeValue(value[key], childIndent) .. ',\n'
        end
        lines[#lines + 1] = indent .. '}'
        return table.concat(lines)
    elseif valueType == 'string' then
        return string.format('%q', value)
    elseif valueType == 'number' or valueType == 'boolean' then
        return tostring(value)
    end
    return 'nil'
end


local CreateNewProfile = function(path, file_name)
    if ashita.fs.exists(path) then
        gFuncs.Error('Profile already exists: ' .. path);
        return false;
    end

    if (CreateDirectories(path) == false) then        
        return;
    end

	local src_profile_path = ('%saddons\\simplelog\\%s.lua'):fmt(AshitaCore:GetInstallPath(), file_name);
	local src_profile_data, readError = ReadAll(src_profile_path)
    if not src_profile_data then
        gFuncs.Error('Failed to access file: ' .. src_profile_path .. ': ' .. tostring(readError))
        return false
    end
	return AtomicWrite(path, src_profile_data);
end


local OverwriteProfile = function (path, source_path)
    if (CreateDirectories(path) == false) then
        return;
    end

	local src_profile_data, readError = ReadAll(source_path)
    if not src_profile_data then
        gFuncs.Error('Failed to access file: ' .. source_path .. ': ' .. tostring(readError))
        return false
    end
	return AtomicWrite(path, src_profile_data);
end


local SaveChanges = function (path, mod_table, file_type)
    if (CreateDirectories(path) == false) then
        return;
    end

    if not ashita.fs.exists(path) then
        gFuncs.Error(('File in "%s" dont exist.'):fmt(path))
        return false
    end

    local variableNames = {
        settings = 'settings',
        filters = 'filters',
        colors = 'colors',
    }
    local variableName = variableNames[file_type]
    if not variableName or type(mod_table) ~= 'table' then
        return false
    end

    local fileData = 'local ' .. variableName .. ' = '
        .. SerializeValue(mod_table, '') .. ';\n\nreturn ' .. variableName .. ';\n'
    return AtomicWrite(path, fileData)
end



local exports = {
    CreateDirectories = CreateDirectories,
	CreateNewProfile = CreateNewProfile,
    OverwriteProfile = OverwriteProfile,
    SaveChanges = SaveChanges,
};
return exports;
