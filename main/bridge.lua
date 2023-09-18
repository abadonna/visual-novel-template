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
	local co = coroutine.running()
	timer.delay(tonumber(time), false, function()
		coroutine.resume(co)
	end)
	coroutine.yield()
end

M.action["NOTEXT"] = function()
	msg.post("#gui", "clear", {clear = "all"})
	msg.post("#gui", "text", {text = ""})
	coroutine.yield()
end

M.action["Z"] = function(data)
	msg.post(M.url, "action", {move = data[1], z = tonumber(data[2])})
	table.insert(M.stack, {name = "Z", data = data})
end
	
M.action["HIDE"] = function(data)
	local duration = data[2] and tonumber(data[2]) or 0
	msg.post(M.url, "action", {hide = data[1], speed = duration})
	table.insert(M.stack, {name = "HIDE", data = {data[1], 0}})
end

M.action["SHOW"] = function(data)
	local duration = data[2] and tonumber(data[2]) or 0
	msg.post(M.url, "action", {show = data[1], speed = duration})
	table.insert(M.stack, {name = "SHOW", data = {data[1], 0}})
end

M.action["ZOOM_IN"] = function(data)
	local action = {scale 	= data[1], x = 1.1, y = 1.1, speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["ZOOM_OUT"] = function(data)
	local action = {scale 	= data[1], x = 1., y = 1., speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["SHOW_CHAR_RIGHT"] = function(data)
	M.chars[data[1]] = 1400
	msg.post(M.url, "action", {show = data[1], speed = .5})
	msg.post(M.url, "action", {move = data[1], x = 1350, easing = gui.EASING_OUTQUAD, speed = 1})
	table.insert(M.stack, {name = "SHOW", data = {data[1]}})
	table.insert(M.stack, {name = "MOVE", data = {data[1], 1350}})
end

M.action["SHOW_CHAR_LEFT"] = function(data)
	M.chars[data[1]] = 600
	msg.post(M.url, "action", {show = data[1], speed = .5})
	msg.post(M.url, "action", {move = data[1], x = 650, easing = gui.EASING_OUTQUAD, speed = 1})
	table.insert(M.stack, {name = "SHOW", data = {data[1]}})
	table.insert(M.stack, {name = "MOVE", data = {data[1], 650}})
end

M.action["HIDE_CHAR"] = function(data)
	msg.post(M.url, "action", {hide = data[1], speed = .5})
	msg.post(M.url, "action", {move = data[1], x = M.chars[data[1]], easing = gui.EASING_OUTQUAD, speed = 1})
	table.insert(M.stack, {name = "HIDE", data = {data[1]}})
	table.insert(M.stack, {name = "MOVE", data = {data[1], M.chars[data[1]]}})
end

M.action["FADE_OUT"] = function()
	msg.post("/hud", "fade_out")
	M.action["DELAY"](.5)
end

M.action["FADE_IN"] = function()
	msg.post("/hud", "fade_in")
end

M.action["DELETE"] = function(data)
	msg.post(M.url, "action", {delete = data[1]})
	table.insert(M.stack, {name = "DELETE", data = data})
end

M.action["MOVE"] = function(data)
	msg.post(M.url, "action", {
		move = data[1],
		x = tonumber(data[2]),
		y = data[3] and tonumber(data[3]) or nil,
		speed = data[4] and tonumber(data[4]) or nil
	})
end

M.action["SCENE"] = function(data)
	local fade = data[2] or "fadeinout"
	if fade == "fadeout" or fade == "fadeinout" then
		msg.post("/hud", "fade_out")
		M.action["DELAY"](.5)
	end

	M.load_scene(data[1], data[3])
	coroutine.yield()
	
	if fade == "fadein" or fade == "fadeinout" then
		msg.post("/hud", "fade_in")
	end
end

M.action["LOAD_IMAGE"] = function(data)
	msg.post(M.url, "load_image", {url = "/" .. data[1] .. "#sprite", file = data[2]})
	table.insert(M.stack, {name = "LOAD_IMAGE", data = data})
end

M.action["LOAD_ANIM"] = function(data)
	local count = tonumber(data[3])
	for i = 1, 10 do
		msg.post(M.url, "load_image", {url = "/" .. data[1] .. "#frame" .. i, file = data[2] .. i .. ".jpg"})
	end
	table.insert(M.stack, {name = "LOAD_ANIM", data = data})
end

M.action["PLAY"] = function(data)
	msg.post(M.scene .. ":/" .. data[1], "play")
end

M.action["STOP"] = function(data)
	msg.post(M.scene .. ":/" .. data[1], "stop")
end

M.action["MSG"] = function(data)
	local url = string.find(data[1], ":") ~= nil and data[1] or M.scene .. ":/" .. data[1]
	msg.post(url, data[2])
end

M.action["SOUND"] = function(data)
	msg.post(M.scene .. ":/sound#" .. data[1], "play_sound")
end

M.action["MUTE"] = function(data)
	msg.post(M.scene .. ":/sound#" .. data[1], "stop_sound")
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
		M.action[item.name](item.data)
	end
end

return M