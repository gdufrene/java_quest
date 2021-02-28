-- Lua script of map warehouse.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

local registerServlet = "http://localhost:8080/exo201/registerServlet"



-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
	paul.step = 1
	assistant.step = 4
	print("Map started")
	-- code = sol.net.http_get(registerServlet)
	print("quest dir => ", os.getenv("HOME"))
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end

function store:on_interaction()
	
end

function run_step(npc, callback)
	game:start_dialog("warehouse." .. npc:get_name() .. "_" .. npc.step, function(r) 
		if callback(r) then
			npc.step = npc.step + 1
			npc:on_interaction() -- when suceed relaunch new dialog.
		end
	end)
end

function query_action(action)
	return sol.net.http_post("/exo201/test-warehouse?action=" .. action)
end

function test_warehouse(action, feedback)
	local code, html = query_action(action)
	print("[Test]", action, code)
	if code == 500 then
		print(html)
	end
	if feedback then
		if code == 200 then 
			sol.audio.play_sound("ok") 
		else 
			sol.audio.play_sound("wrong") 
		end
	end
	return code == 200
end

function always_continue(r) 
	return true
end

function never_continue(r) 
	return false
end

function continue_when_1(r) 
	return r == 1
end

function fn_testing_warehouse(action)
	return function(r)
		if r == 1 then
			return test_warehouse(action, true)
		end
	end
end

function paul:on_interaction() 
	local steps = {
		-- 1 -- intro, help needed
		function(r)
			if r == 1 then
				assistant.step = 2
				return true
			end
			return false
		end,
		-- 2 -- help accepted, wait for assistant
		never_continue,
		-- 3
		function()
		end
	}
	run_step(self, steps[self.step])
end

function assistant:on_interaction() 
	local steps = {
		-- 1 -- 
		never_continue,
		-- 2 -- compris ?
		continue_when_1,
		-- 3 -- test ajout paul
		function(r)
			if r == 2 then
				return false
			end
			res = sol.sql.query("select * from users where email = 'paul@mooc.fun'")
			if ( res == "Ok" ) then
				sol.audio.play_sound("wrong") 
				print("Aucun utilisateur avec le mail 'paul@mooc.fun' trouvé")
				self.step = 2
				return false
			end
			row = res[1]
			if ( row["email"] == "paul@mooc.fun" and row["password"] == "citoyen") then
				return true
			end
			sol.audio.play_sound("wrong") 
			print("L'utilisateur ne correspond pas.", dump(row))
			self.step = 2
			return false
		end,
		-- 4 -- Ok text
		function()
			sol.audio.play_sound("ok")
			map:set_entities_enabled("archives_door", false)
			return false
		end,
		-- 5 -- test delete
		function(r)
			if r == 2 then
				self.step = self.step - 1
				return true
			else
				self.step = self.step + 1
				return false
			end
		end,
		-- 6 -- test registerServlet GET et POST ?
		function(r)
			if r == 2 then 
				return false
			end
			code = sol.net.http_get(registerServlet)
			if code < 0 then
				print("Erreur de connexion vers "..registerServlet)
				return false
			end
			if code == 404 or code >= 500 then
				print("Erreur "..code.." vers "..registerServlet)
				return false
			end
			local body = "firstname=&lastname=&email=&password=azerty";
			local ctx = { headers = {} }
			ctx.headers["Content-Type"] = "application/x-www-form-urlencoded"
			print("[POST] "..body)
			code = sol.net.http_post(registerServlet, body, ctx)
			if code < 200 or code >= 400 then
				print("Erreur "..code)
				sol.sql.query("delete from users where email = ''")
				return false
			end
			res = sol.sql.query("select * from users where email = ''")
			if res == "Ok" then 
				print("L'utilisateur n'a pas été retrouvé dans la base")
				return false
			end
			if type(res) == "table" and res[1]["email"] == '' then
				-- OK !!
				sol.audio.play_sound("ok")
				return true
			end
			print("L'utilisateur enregistré n'a pas les bonnes données")
			sol.sql.query("delete from users where email = ''")
			return false
		end,
		-- 7 -- Succeed


	}
	run_step(self, steps[self.step])
end

function test_register_noparam(name, data)

	formData = {
		firstname= "Someone",
		lastname= "Withname",
		email= "someone@mooc.fun",
		password= "azerty",
	}
	if type(data) ~= "table" then
		data = {}
	end
	body = ""
	for k, v in pairs(formData) do
		if k ~= name then 
			if body ~= "" then body = body .. "&" end
			if data[k] then v = data[k] end
			body = body .. string.format("%s=%s", k, v)
		end
	end
	local ctx = { headers= {} }
	ctx.headers["Content-Type"] = "application/x-www-form-urlencoded"
	print("[POST] "..body)

	if true then
		return false -- TODO: for tests only !!!
	end

	code = sol.net.http_post(registerServlet, body, ctx)
	if code < 200 or code >= 400 then
		return false
	end
	return true
end

function archives_sensor:on_activated()
	if assistant.step == 4 then
		assistant.step = 5
		self:set_enabled(false) -- needed ??
	end
end

function get_str_user_data(id)
	id = tonumber(id)
	res = sol.sql.query("select * from users where id = "..tonumber(id))
	if res == "Ok" then
		data = { 
			"Le tome numéro ["..id.."] est vide."
		}
	else
		res = res[1]
		data = {
			"ID : "..res["id"],
			"Prenom : "..res["firstname"],
			"Nom : "..res["lastname"],
			"Email : "..res["email"],
			"Password : "..res["password"]
		}
	end
	local i = 0
	return function() -- return iterator
		i = i + 1
		return data[i]
	end
end

function show_user_data(id)
	local txt = game:get_text_box()
	txt:set_size(40, 6)
	for str in get_str_user_data(id) do
		txt:add_line( str )
	end
	sol.menu.start(game, txt)
end

function etagere_1:on_interaction()
	show_user_data(1)
end

function etagere_2:on_interaction()
	show_user_data(2)
end

function etagere_3:on_interaction()
	show_user_data(3)
end

function etagere_4:on_interaction()
	show_user_data(4)
end

function etagere_5:on_interaction()
	show_user_data(5)
end

function etagere_6:on_interaction()
	show_user_data(6)
end

function goto_outside_then(npc, cb)
	mvt = sol.movement.create("target")
	mvt:set_ignore_obstacles()
	mvt:set_target(from_outside, 8, 0)
	mvt:start(npc, function()
		mvt:stop()
		cb()
	end)
end

function do_moves_to_outside_then(npc, cb)
	fallback_movements(npc, {
		align_to_waypoint_then,
		goto_waypoint_then,
		goto_outside_then,
		end_movement(cb)
	})
end

function do_again_fn(npc)
	return function()
		npc.step = 1
		game:get_hero():teleport(map:get_id(), nil, "fade")
		sol.timer.start(750, function()
			npc:set_position(npc.initial_position[1], npc.initial_position[2])
			npc:get_sprite():set_animation("stopped")
		end)
		return false
	end
end

function npc_try_register(npc, data, ignore_param)
	return function()
		if not ignore_param then ignore_param = "" end
		if not test_register_noparam(ignore_param, data) then
			npc.step = 3
			npc:on_interaction()
			return
		end
		npc.step = 4
		npc:on_interaction()
	end
end

function npc_registering_steps(npc, registerFn)
	if not npc.step then
		npc.step = 1
	end
	local steps = {
		-- 1 -- register ?
		continue_when_1,
		-- 2 -- try to register,
		function()
			x, y = npc:get_position()
			npc.initial_position = {x, y}
			do_moves_to_register_then(npc, registerFn)
			return false
		end,
		-- 3 -- fail to check param check
		function()
			do_moves_to_outside_then(npc, do_again_fn(npc))
			return false
		end,
		-- 4 -- Succeed
		function()
			do_moves_to_outside_then(npc, function()
				npc:set_enabled(false)
			end)
			return false
		end,
	}
	run_step(npc, steps[npc.step])
end

function phil:on_interaction()
	local data = {
		firstname= "Phil",
		email= "phil@mooc.fun"
	}
	local registerFn = npc_try_register(self, data, "lastname")
	npc_registering_steps(self, registerFn)
end

function groot:on_interaction()
	local data = {
		lastname= "Groot",
		email= "groot@mooc.fun"
	}
	local registerFn = npc_try_register(self, data, "firstname")
	npc_registering_steps(self, registerFn)
end

function kaleido:on_interaction()
	local data = {
		firstname= "Grandalf",
		lastname= "Leviolet",
		email= "grandalf@mooc.fun",
		password=""
	}
	local registerFn = npc_try_register(self, data, "password")
	npc_registering_steps(self, registerFn)
end

function soldier:on_interaction()
	local data = {
		firstname= "Arsene",
		lastname= "Lupin",
		email= "lionel.seinturier@foo.bar"
	}
	local registerFn = npc_try_register(self, data, "")
	npc_registering_steps(self, registerFn)
end

function movement_factory(npc, configurer)
	local mvt = sol.movement.create("target")
	mvt:set_ignore_obstacles()
	configurer(mvt)
	-- mvt:set_target(x2, y1)
	mvt:start(npc, cb)

	Factory = {}
	function Factory:set_target(e, x, y)
		mvt:set_target(e, x ,y)
	end 
	Factory.start = function(cb)
		mvt:start(npc, function()
			mvt:stop()
			cb()
		end)
	end
	return Factory
end

function align_to_waypoint_then(npc, cb)
	local x1, y1 = waypoint:get_position()
	local x2, y2 = npc:get_position()
	local mvt = sol.movement.create("target")
	mvt:set_target(x2, y1)
	mvt:set_ignore_obstacles()
	mvt:start(npc, function()
		mvt:stop()
		cb()
	end)
end

function goto_waypoint_then(npc, cb)
	local x1, y1 = waypoint:get_position()
	local x2, y2 = npc:get_position()
	local mvt = sol.movement.create("target")
	mvt:set_target(x1, y1)
	mvt:set_ignore_obstacles()
	mvt:start(npc, function()
		mvt:stop()
		cb()
	end)
end

function goto_register_then(npc, cb)
	local mvt = sol.movement.create("target")
	mvt:set_target(paul, 0, 16)
	mvt:set_ignore_obstacles()
	mvt:start(npc, function()
		mvt:stop()
		cb()
	end)
end

function end_movement(cb)
	return function(npc, next_cb)
		cb()
	end
end

function fallback_movements(npc, functions)
	local i = 0
	nextFn = function()
		i = i + 1
		if functions[i] then
			functions[i](npc, nextFn)
		end
	end
	nextFn()
end

function do_moves_to_register_then( npc, cb )
	fallback_movements(npc, {
		align_to_waypoint_then,
		goto_waypoint_then,
		goto_register_then,
		end_movement(cb)
	})
end

function store:on_interaction()
	local code, html = query_action("getData1")
	local txt = game:get_text_box()
	txt:set_size(40, 6)
	if code == 200 then
		local text = html:gsub("\r\n", "\n"):gsub("\r", "\n")
    	local line_it = text:gmatch("([^\n]*)\n")  -- Each line including empty ones.
    	local next_line = line_it()
    	while next_line ~= nil do
    		txt:add_line(next_line)
    		next_line = line_it()
    	end
	else
		txt:add_line("Erreur " .. code)
		txt:add_line("Impossible d'afficher les données")
	end
	sol.menu.start(game, txt)
end