local M = {
	action = {}, 
	scenes = {},
	chars = {},
	stack = {},
	portrait = ""
}

M.action["Marin"] = function(text)
	M.speak("marin", text)
end

-----------------------------------------------------------
	
M.action["DELAY"] = function(time)
	time = time and tonumber(time) or 0.5
	local co = coroutine.running()
	timer.delay(time, false, function()
		coroutine.resume(co)
	end)
	coroutine.yield()
end

M.action["NOTEXT"] = function()
	msg.post("#gui", "clear", {clear = "all"})
	msg.post("#gui", "text", {text = ""})
	coroutine.yield()
end

M.action["Z"] = function(path, z)
	msg.post(M.url, "action", {move = path, z = z})
	table.insert(M.stack, {name = "Z", data = {path, z}})
end
	
M.action["HIDE"] = function(path, time)
	local duration = time and tonumber(time) or 0
	msg.post(M.url, "action", {hide = path, speed = duration})
	table.insert(M.stack, {name = "HIDE", data = {path, 0}})
end

M.action["SHOW"] = function(path, time)
	local duration = time and tonumber(time) or 0
	msg.post(M.url, "action", {show = path, speed = duration})
	table.insert(M.stack, {name = "SHOW", data = {path, 0}})
end

M.action["ZOOM_IN"] = function(scale)
	local action = {scale 	= scale, x = 1.1, y = 1.1, speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["ZOOM_OUT"] = function(scale)
	local action = {scale 	= scale, x = 1., y = 1., speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["SHOW_CHAR_RIGHT"] = function(path)
	M.chars[path] = 1400
	msg.post(M.url, "action", {show = path, speed = .5})
	msg.post(M.url, "action", {move = path, x = 1350, easing = gui.EASING_OUTQUAD, speed = 1})
	table.insert(M.stack, {name = "SHOW", data = {path}})
	table.insert(M.stack, {name = "MOVE", data = {path, 1350}})
end

M.action["SHOW_CHAR_LEFT"] = function(path)
	M.chars[path] = 600
	msg.post(M.url, "action", {show = path, speed = .5})
	msg.post(M.url, "action", {move = path, x = 650, easing = gui.EASING_OUTQUAD, speed = 1})
	table.insert(M.stack, {name = "SHOW", data = {path}})
	table.insert(M.stack, {name = "MOVE", data = {path, 650}})
end

M.action["HIDE_CHAR"] = function(path)
	msg.post(M.url, "action", {hide = path, speed = .5})
	msg.post(M.url, "action", {move = path, x = M.chars[path], easing = gui.EASING_OUTQUAD, speed = 1})
	table.insert(M.stack, {name = "HIDE", data = {path}})
	table.insert(M.stack, {name = "MOVE", data = {path, M.chars[path]}})
end

M.action["FADE_OUT"] = function()
	msg.post("/hud", "fade_out")
	M.action["DELAY"](.5)
end

M.action["FADE_IN"] = function()
	msg.post("/hud", "fade_in")
end

M.action["DELETE"] = function(path)
	msg.post(M.url, "action", {delete = path})
	table.insert(M.stack, {name = "DELETE", data = {path}})
end

M.action["MOVE"] = function(path, x, y, time)
	msg.post(M.url, "action", {
		move = path,
		x = tonumber(x),
		y = y and tonumber(y) or nil,
		speed = time and tonumber(time) or nil
	})
	table.insert(M.stack, {name = "MOVE", data = {path, x, y, 0}})
end

M.action["SCENE"] = function(name, mode, keep)
	local fade = mode or "fadeinout"
	if fade == "fadeout" or fade == "fadeinout" then
		msg.post("/hud", "fade_out")
		M.action["DELAY"](.5)
	end

	M.load_scene(name, keep)
	coroutine.yield()
	
	if fade == "fadein" or fade == "fadeinout" then
		msg.post("/hud", "fade_in")
	end
end

M.action["LOAD_IMAGE"] = function(path, file)
	msg.post(M.url, "load_image", {url = "/" .. path .. "#sprite", file = file})
	table.insert(M.stack, {name = "LOAD_IMAGE", data = {path, file}})
end

M.action["LOAD_ANIM"] = function(path, file, count)
	count = tonumber(count)
	for i = 1, 10 do
		msg.post(M.url, "load_image", {url = "/" .. path .. "#frame" .. i, file = file .. i .. ".jpg"})
	end
	table.insert(M.stack, {name = "LOAD_ANIM", data = {path, file, count}})
end

M.action["PLAY"] = function(path)
	msg.post(M.scene .. ":/" .. path, "play")
end

M.action["STOP"] = function(path)
	msg.post(M.scene .. ":/" .. path, "stop")
end

M.action["MSG"] = function(path, id)
	local url = string.find(path, ":") ~= nil and path or M.scene .. ":/" .. path
	msg.post(url, id)
end

M.action["SOUND"] = function(sound)
	msg.post(M.scene .. ":/sound#" .. sound, "play_sound")
end

M.action["MUTE"] = function(sound)
	msg.post(M.scene .. ":/sound#" .. sound, "stop_sound")
end

---------------------------------------------------------------

M.load_scene = function(name, keep)

	if M.scenes[name] then
		M.scene = name
		return false
	end

	if not keep then
		for key, _ in pairs(M.scenes) do
			local url = "/scenes#" .. key
			msg.post(url, "disable")
			msg.post(url, "final")
			msg.post(url, "unload")
		end
		M.scenes = {}
		M.stack = {{name = "SCENE", data = {name, "none", false}}}
	end

	M.scene = name
	M.url = name .. ":/controller"
	M.scenes[name] = true

	msg.post("/scenes#" .. name, "async_load")
	return true
end

M.restore_text_prompt = function()
	if M.portrait ~= "" then
		msg.post("#gui", "portrait", {portrait = "", animate = {
			{prop = "opacity", from = 1, to = 0, speed = 0.4, delay = 0.2},
			{prop = "move", from = {}, to = {x = -10}, speed = 1, delay = 0.2, easing = gui.EASING_OUTCUBIC}}
		})
		msg.post("#gui", "text_restore")
		M.portrait = ""
		M.action["DELAY"](0.5)
	end
end

M.speak = function(character, text)
	character = string.lower(character)
	msg.post("#gui", "text_move", {x = 400})
	if M.portrait ~= character then
		M.portrait = character
		msg.post("#gui", "portrait", {portrait = "marin", animate = {
			{prop = "opacity", from = 0, to = 1, speed = 0.5},
			{prop = "move", from = {x = -20}, to = {x = -5}, speed = 0.7, easing = gui.EASING_OUTBACK}
		}})
	end
	msg.post("#gui", "text", {text = text, speed = 0.001, limit = 1240})
end

M.restore = function(stack)
	M.stack = {}
	for _, item in ipairs(stack) do
		M.action[item.name](unpack(item.data))
	end
end

return M