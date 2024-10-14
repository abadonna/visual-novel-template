local M = {
	action = {}, 
	scenes = {},
	chars = {},
	stack = {},
	portrait = "",
	ready = true
}

M.action["Marin"] = function(text)
	M.speak("marin", text)
end

-----------------------------------------------------------

M.action["DELAY"] = function(time)
	M.ready = false
	time = time and tonumber(time) or 0.5
	local co = coroutine.running()
	timer.delay(time, false, function()
		M.ready = true
		coroutine.resume(co)
	end)
	coroutine.yield()
end

M.action["NOTEXT"] = function()
	msg.post("/hud#gui", "clear", {clear = "all"})
	msg.post("/hud#gui", "text", {text = ""})
	M.restore_text_prompt()
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

M.action["ZOOM_IN"] = function(path)
	local action = {scale 	= path, x = 1.1, y = 1.1, speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["ZOOM_OUT"] = function(path)
	local action = {scale 	= path, x = 1., y = 1., speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["SCALE"] = function(path, x, y)
	local action = {scale = path, x = x, y = y, target = "."}
	msg.post(M.url, "action", action)
	table.insert(M.stack, {name = "SCALE", data = {path, x, y}})
end

M.action["CHR_SHOW_RIGHT"] = function(path)
	M.chars[path] = 1400
	msg.post(M.url, "action", {show = path, speed = .5})
	msg.post(M.url, "action", {move = path, x = 1350, easing = gui.EASING_OUTQUAD, speed = 1})
end

M.action["CHR_SHOW_LEFT"] = function(path)
	M.chars[path] = 600
	msg.post(M.url, "action", {show = path, speed = .5})
	msg.post(M.url, "action", {move = path, x = 650, easing = gui.EASING_OUTQUAD, speed = 1})
	
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

M.action["DELETE"] = function(path, time)
	local duration = time and tonumber(time) or 0
	if duration > 0 then
		msg.post(M.url, "action", {hide = path, speed = duration})
	end
	timer.delay(duration, false, function()
		msg.post(M.url, "action", {delete = path}) 
	end)
		
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

	if M.scenes[name] then
		M.scene = name
		M.url = name .. ":/controller"
		table.insert(M.stack, {name = "SCENE", data = {name, mode, keep}})
		return
	end
	
	local fade = mode or "fadeinout"
	if fade == "fadeout" or fade == "fadeinout" then
		msg.post("/hud", "fade_out")
		M.action["DELAY"](.5)
	end

	M.ready = false
	M.load_scene(name, keep)
	coroutine.yield()

	M.ready = true
	if fade == "fadein" or fade == "fadeinout" then
		msg.post("/hud", "fade_in")
	end
end

M.action["UNLOAD"] = function(name)
	M.scenes[name] = nil
	local url = "/scenes#" .. name
	msg.post(url, "disable")
	msg.post(url, "final")
	msg.post(url, "unload")
	table.insert(M.stack, {name = "UNLOAD", data = {name}})
end

M.action["LOAD_IMAGE"] = function(path, file)
	msg.post(M.url, "load_image", {path = path, sprite = "sprite", file = file})
	table.insert(M.stack, {name = "LOAD_IMAGE", data = {path, file}})
end

M.action["LOAD_ANIM"] = function(path, file, count, delay)
	count = tonumber(count)
	for i = 1, 10 do
		timer.delay( (i - 1) * (delay or 0), false, function()
			msg.post(M.url, "load_image", {path = path, sprite = "frame" .. i, file = file .. i .. ".jpg"})
		end)
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

M.action["EXIT"] = function(sound)
	sys.exit(0)
end

M.action["SAVE"] = function(slot)
	msg.post(".", "save", {slot = slot})
end

M.action["LOAD"] = function(slot)
	msg.post(".", "load", {slot = slot})
	coroutine.yield()
end

---------------------------------------------------------------

M.load_scene = function(name, keep)

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
		msg.post("/hud#gui", "portrait", {portrait = "", animate = {
			{prop = "opacity", from = 1, to = 0, speed = 0.4, delay = 0.2},
			{prop = "move", from = {}, to = {x = -10}, speed = 1, delay = 0.2, easing = gui.EASING_OUTCUBIC}}
		})
		msg.post("/hud#gui", "text_restore")
		M.portrait = ""
		msg.post("/hud#gui", "clear", {clear = "all"})
		M.action["DELAY"](0.5)
	end
end

M.speak = function(character, text)
	character = string.lower(character)
	msg.post("/hud#gui", "text_move", {x = 400})
	if M.portrait ~= character then
		M.portrait = character
		msg.post("/hud#gui", "portrait", {portrait = character, animate = {
			{prop = "opacity", from = 0, to = 1, speed = 0.5},
			{prop = "move", from = {x = -20}, to = {x = -5}, speed = 0.7, easing = gui.EASING_OUTBACK}
		}})
	end
	msg.post("/hud#gui", "text", {text = text, speed = 0.001, limit = 1240})
end

M.restore = function(stack)
	M.stack = {}
	for _, item in ipairs(stack) do
		M.action[item.name](unpack(item.data))
	end
end


-------------------------- LEGACY ---------------------------------

M.action["BG_OUT_EX"] = function(path)
	msg.post(M.url, "action", {scale = path, x = .53, y = .53,  target = "."})
	msg.post(M.url, "action", {scale = path, x = .5, y = .5, speed = 3, easing = gui.EASING_OUTQUAD, target = "."})
end

M.action["BG_IN"] = function(path)
	local action = {scale = path, x = .53, y = .53, speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["HIDE2_SLOW"] = function(path)
	M.restore_text_prompt()
	msg.post(M.url, "action", {hide = path, target = "sprite1", speed = 0.5})
	msg.post(M.url, "action", {hide = path, target = "sprite2", speed = 0.5})
end

M.action["BG_IN2"] = function(path)
	msg.post(M.url, "action", {scale = path, x = .53, y = .53,  target = "."})
	msg.post(M.url, "action", {scale = path, x = .56, y = .56, speed = 3, easing = gui.EASING_OUTQUAD, target = "."})
end

M.action["CHR_HIDE_LEFT"] = function(path)
	msg.post(M.url, "action", {hide = path, speed = .5})
	msg.post(M.url, "action", {move = path, x = M.chars[path], easing = gui.EASING_OUTQUAD, speed = 1})
end

M.action["CHR_HIDE_RIGHT"] = function(path)
	msg.post(M.url, "action", {hide = path, speed = .5})
	msg.post(M.url, "action", {move = path, x = M.chars[path], easing = gui.EASING_OUTQUAD, speed = 1})
end

M.action["OBSERVE"] = function(path)
	msg.post("main:/hud", "observe")
end


M.action["RESTORE"] = function(path)
	local delay = M.portrait ~= ""
	M.restore_text_prompt()
	
	if delay then
		M.action["DELAY"](.5)
	end
	
end

M.action["RESETSTACK"] = function(path)
	M.stack = {}
end

M.action["BG_OUT"] = function(path)
	local action = {scale 	= path, x = .5, y = .5, speed = 3, easing = gui.EASING_OUTQUAD, target = "."}
	msg.post(M.url, "action", action)
end

M.action["HIDE2"] = function(path)
	local duration = time and tonumber(time) or 0
	msg.post(M.url, "action", {hide = path, target = "sprite1"})
	msg.post(M.url, "action", {hide = path, target = "sprite2"})
end

M.action["SHOW2"] = function(path)
	local duration = time and tonumber(time) or 0
	msg.post(M.url, "action", {show = path, target = "sprite1"})
	msg.post(M.url, "action", {show = path, target = "sprite2"})
end

M.action["SHOW2_SLOW"] = function(path)
	msg.post(M.url, "action", {show = path, speed = .5, target = "sprite1"})
	msg.post(M.url, "action", {show = path, speed = .5, target = "sprite2"})

end

M.action["STEAM_UNLOCK"] = function(key)
	msg.post("main:/steam", "unlock", {name = key})
end

M.action["BLOG"] = function(key)
	if html5 then
		html5.run("document.getElementById(\"canvas\").onclick = function (e) {window.open(\"http://google.com\",\"_blank\");document.getElementById(\"canvas\").onclick = \"\";};")
	else
		sys.open_url("http://google.com")
	end
end

return M