local texthandlers = {}
local bm_message
local flip_block_equip
local flip_block_cannot

texthandlers.HandleIncomingText = function(e)
	if not gProfileSettings then
		return
	end
	local redcol = e.mode%256
	
	if (redcol == 121 and gProfileSettings.mode.cancelmultimsg) then
		local a = string.find(e.message,'Equipment changed')

		if (a and not block_equip) then
			flip_block_equip:once(1)
			--ashita.tasks.once(1, flip_block_equip)
			block_equip = true
		elseif (a and block_equip) then
			e.blocked = true
			return
		end
	elseif (redcol == 123 and gProfileSettings.mode.cancelmultimsg) then
		local a = string.find(e.message, 'You were unable to change your equipped items')
		local b = string.find(e.message, 'You cannot use that command while viewing the chat log')
		local c = string.find(e.message, 'You must close the currently open window to use that command')
		
		if ((a or b or c) and not block_cannot) then
			flip_block_cannot:once(1)
			--ashita.tasks.once(1, flip_block_cannot)
			block_cannot = true
		elseif ((a or b or c) and block_cannot) then
			e.blocked = true
			return
		end
	end
	
	if (block_modes:contains(e.mode)) then
		local endline = string.char(0x7F, 0x31)
		local item = string.char(0x1E)
		if (not bm_message(e.message)) then
			if (e.message:endswith(endline)) then --allow add_to_chat messages with the modes we blocking
				e.blocked = true
				return
			end
		elseif (e.message:endswith(endline) and string.find(e.message, item)) then --block items action messages
			e.blocked = true
			return
		end
	end

end

bm_message = function(original)
    local check = string.char(0x1E)
    local check2 = string.char(0x1F)
    if string.find(original, check) or string.find(original, check2) then
        return true
    end
end

flip_block_equip = function()
	block_equip = not block_equip
end

flip_block_cannot = function()
	block_cannot = not block_cannot
end

return texthandlers;