local M = {init = {}}

M.get_list_value = function(list)
	local value = M._STORY.variables[list]
	if type(value) == "string" then
		return value
	end
	for t, _ in pairs(value) do
		return t:gsub(list .. ".", "")
	end
end

return M