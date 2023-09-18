require 'utf8'

local STRINGS = 
{
	require "local.ru",
	require "local.ch",
}

local M = {}
M.langs = {"ENGLISH", "РУССКИЙ", "汉语"}
M.lang = 1

M.localize = function(key)
	if M.lang == 1 then
		return key
	else
		local key2 = string.gsub(key, "\n", "")
		key2 = string.gsub(key2, "\t", " ")
		return STRINGS[M.lang - 1][key2] or key
	end
end

M.localize_font = function(node, font)
	if (M.lang == 3) then --chineese
		-- set chineese font
	elseif font ~= nil then
		gui.set_font(node, font)
	end
end

M.symbols = function(text)
	local n = 0
	local count = string.utf8len(text)
	return function ()
		n = n + 1
		if n <= count then
			return string.utf8sub(text, n, n)
		end
	end
end

M.words = function(text)
	if (M.lang == 3) then -- split per symbol
		return M.symbols(text)
	end
	
	return (text .. " "):gmatch("(.-) ")
end

return M