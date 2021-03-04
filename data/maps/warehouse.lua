-- Lua script of map warehouse.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

local registerServlet = "http://localhost:8080/exo201/register"
local registerJsp = "http://localhost:8080/exo201/register.jsp"

require("scripts/util/html_parser")
require("scripts/util/dump")

local npc_entered = false
local npc_register_left = {}

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
	paul.step = game:get_value("paul_step") or 1
	assistant.step = game:get_value("assistant_step") or 1
	local open = game:get_value("archives_door")
	if open == nil then open = true end
	map:set_entities_enabled("archives_door", false)
end


function run_step(npc, callback)
	game:start_dialog("warehouse." .. npc:get_name() .. "_" .. npc.step, function(r) 
		if callback(r) then
			npc.step = npc.step + 1
			npc:on_interaction() -- when suceed relaunch new dialog.
		end
	end)
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

function check_common_npc(results) 
	allOk = true
	for k, v in pairs(results) do
		-- print("Enregistrement de "..k..": "..(v and "Ok" or "Erreur"))
		allOk = allOk and v
	end
	if allOk then
		paul.step = 5
	else
		paul.step = 4
	end
	npc_entered = false
	paul:on_interaction()
end

function check_after_erroneous_npc_completed(npc)
	local i = 0
	local hasLeft = false
	for k, v in ipairs(npc_register_left) do
		if v == npc then 
			i = k
		else
			hasLeft = true
		end
	end
	if i > 0 then
		table.remove(npc_register_left, i)
	end
	if not hasLeft then
		paul.step = 6 -- Ok !
		paul:on_interaction()
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
		function()
			game:set_value("paul_step", 2)
			return false
		end,
		-- 3 -- common npc comes and register ...
		function()
			if npc_entered then return false end
			do_enter_then({joe, bob, spencer}, function()
				dataTable = {
					joe={
						firstname= "Joe",
						lastname= "Black",
						email= "joe.black@mooc.fun",
					},
					bob={
						firstname= "Bob",
						lastname= "Razowski",
						email= "bob.razowski@mooc.fun",
					},
					spencer={
						firstname= "Spencer",
						lastname= "Andmarc",
						email= "spencer.andmarc@mooc.fun",
					}
				}
				register_common_npc({joe, bob, spencer}, dataTable, check_common_npc)
			end)
			npc_entered = true
			return false
		end,
		-- 4 --
		function(r)
			if r == 2 then return false end
			self.step = 2
			return true 
		end,
		-- 5 -- erroneous npc register
		function()
			game:set_value("paul_step", 5)
			if npc_entered then return false end
			npc_register_left = {soldier, kaleido, groot, phil}
			do_enter_then(npc_register_left, never_continue)
			npc_entered = true
			return false
		end,
		-- 6 -- Succeed
		function()
			paul.step = 7
			game:set_value("paul_step", 7)
			assistant.step = 11
			game:set_value("assistant_step", 11)
			sol.timer.start(750, function()
				game:get_hero():start_treasure("key", 1)
			end)
			return false
		end,
		-- 7 -- End
		never_continue
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
				sol.log.error("Aucun utilisateur avec le mail 'paul@mooc.fun' trouvé")
				self.step = 2
				return false
			end
			row = res[1]
			if ( row["email"] == "paul@mooc.fun" and row["password"] == "citoyen") then
				return true
			end
			sol.audio.play_sound("wrong") 
			sol.log.error("L'utilisateur ne correspond pas."..dump(row))
			self.step = 2
			return false
		end,
		-- 4 -- Ok text
		function()
			game:set_value("assistant_step", 4)
			sol.audio.play_sound("ok")
			map:set_entities_enabled("archives_door", false)
			game:set_value("archives_door", false)
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
				sol.log.error("Erreur de connexion vers "..registerServlet)
				return false
			end
			if code == 404 or code >= 500 then
				sol.log.error("Erreur ["..code.."] vers "..registerServlet)
				return false
			end
			local body = "firstname=aaa&lastname=aaa&email=aaa@aaa.aaa&password=azerty";
			local ctx = { headers = {} }
			ctx.headers["Content-Type"] = "application/x-www-form-urlencoded"
			sol.log.debug("[POST] "..registerServlet.." "..body)
			code = sol.net.http_post(registerServlet, body, ctx)
			if code < 200 or code >= 400 then
				sol.log.error("Code Http ["..code.."], attendu 2xx ou 3xx")
				sol.sql.query("delete from users where email = 'aaa@aaa.aaa'")
				return false
			end
			res = sol.sql.query("select * from users where email = 'aaa@aaa.aaa'")
			if res == "Ok" then 
				sol.log.error("L'utilisateur n'a pas été retrouvé dans la base")
				return false
			end
			if type(res) == "table" and res[1]["email"] == 'aaa@aaa.aaa' then
				-- OK !!
				sol.audio.play_sound("ok")
				return true
			end
			sol.log.error("L'utilisateur enregistré n'a pas les bonnes données")
			sol.sql.query("delete from users where email = 'aaa@aaa.aaa'")
			return false
		end,
		-- 7 --
		function()
			game:set_value("assistant_step", 7)
			return true
		end,
		-- 8 -- check JSP form
		function(r)
			sol.log.debug("[GET] "..registerJsp)
			code, body = sol.net.http_get(registerJsp)
			if code < 0 then
				sol.log.error("Erreur de connexion vers "..registerJsp)
				return false
			end
			local errorLabel = check_register_form(body)
			if errorLabel then
				sol.log.error( errorLabel )
				sol.audio.play_sound("wrong")
				return true
			end
			self.step = self.step + 1
			return true
		end,
		-- 9 -- error check JSP
		function(r)
			if r == 1 then 
				self.step = 6
				return true
			else
				self.step = 8
			end
			return false
		end,
		-- 10 --
		function()
			game:set_value("assistant_step", 10)
			paul.step = 3 -- register_common_npc
			return false
		end,
		-- 11 -- after the end of all tasks
		never_continue
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
	sol.log.debug("[POST] "..registerServlet.." "..body)
	return sol.net.http_post(registerServlet, body, ctx)
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

function check_register_form(body)
	local html = parse_html(body, false)
	-- print(dump(html))
	local form = html_search(html, "form")
	if form == nil then
		return "Il n'y a pas de formulaire dans la page"
	end
	-- print ( dump(form) )
	local method = form.attr.method or ""
	if method:upper() ~= "POST" then
		return "La méthode de transmission des données du formulaire n'est pas correcte"
	end
	if not form.attr.action then
		return "Le formulaire devrait contenir un attribut 'action'"
	end
	local expected = "register"
	if form.attr.action:sub(-#expected) ~= expected  then
		return "L'action du formulaire devrait terminer par 'register'"
	end
	local inputs = html_all(form.childNodes, "input")
	local foundInput = { firstname = false, lastname = false, email = false, password = false }
	if inputs ~= nil then
		for k, v in pairs(inputs) do
			if v.attr.name ~= nil then
				foundInput[v.attr.name] = true
			end
		end
	end
	for k, v in pairs(foundInput) do 
		if v == false then 
			return "Il manque la zone '" .. k .. "' dans le formulaire"
		end
	end
	local foundAlert = deep_search(html, "div", function(tag)
		return tag.attr.role == "alert"
	end)
	if foundAlert then
		return "Le message d'alerte ne devrait apparaitre qu'en cas d'erreur"
	end
	return nil
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

function goto_initial_then(npc, cb)
	mvt = sol.movement.create("target")
	mvt:set_ignore_obstacles()
	mvt:set_target(npc.initial_position[1], npc.initial_position[2])
	mvt:start(npc, function()
		mvt:stop()
		cb()
	end)
end

function do_moves_enter_wait(npc, cb)
	fallback_movements(npc, {
		align_to_waypoint_then,
		goto_initial_then,
		end_movement(cb)
	})	
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

function do_enter_then(npcs, cb)
	local i = 0
	iter_enter_npc = function()
		i = i + 1
		npc = npcs[i]
		if npc == nil then 
			cb() 
			return nil
		end
		if npc.initial_position == nil then
			x, y = npc:get_position()
			npc.initial_position = {x, y}
		end
		x, y = from_outside:get_position()
		npc:set_position(x, y)
		npc:set_enabled(true)
		do_moves_enter_wait(npc, function() 
			npc:get_sprite():set_direction(3)
			iter_enter_npc()
		end)
	end
	iter_enter_npc()
end


function npc_try_register(npc, data, ignore_param)
	return function()
		if not ignore_param then ignore_param = "" end
		code, html = test_register_noparam(ignore_param, data)
		local check_mail = nil
		if ignore_param ~= "" then
			check_mail = data.email
		end
		local res = check_register_erroneous_npc(code, html, check_mail)
		if not res then
			npc.step = 3
			npc:on_interaction()
			return
		end
		npc.step = 4
		npc:on_interaction()
	end
end

function check_register_erroneous_npc(code, html, user)
	if code < 200 or code >= 300 then
		sol.log.error("Code ["..code.."]. Le code de retour HTTP attendu est 2xx")
		return false
	end
	if user then
		local res = sol.sql.query("select * from users where email = '"..user.."'")
		if res ~= "Ok" then
			sol.log.error("L'utilisateur '"..user.."' ne devrait pas être en base")
			return false
		end
	end
	html = parse_html(html, false)
	local foundAlert = deep_search(html, "div", function(tag)
		return tag.attr.role == "alert"
	end)
	if not foundAlert then
		sol.log.error("Un message d'alerte devrait apparaitre en cas d'erreur")
		return false
	end
	return true
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
				check_after_erroneous_npc_completed(npc)
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
	local registerFn = npc_try_register(self, data, nil)
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
		npc:get_sprite():set_animation("stopped")
		cb()
	end
end

function fallback_movements(npc, functions)
	local t = {
		functions=functions,
		npc=npc,
		i=0
	}
	function t:nextFn()
		self.i = self.i + 1
		if self.functions[self.i] then
			self.functions[self.i](self.npc, function()
				self:nextFn()
			end)
		end
	end
	t:nextFn()
end

function do_moves_to_register_then( npc, cb )
	fallback_movements(npc, {
		align_to_waypoint_then,
		goto_waypoint_then,
		goto_register_then,
		end_movement(cb)
	})
end

-- the callback has one parameter : succeed (boolean)
function do_register_then(npc, data, cb)
	local result = {}
	do_moves_to_register_then(npc, function()
		code, html = test_register_noparam(nil, data)
		do_moves_to_outside_then(npc, function()
			npc:set_enabled(false)
			cb( code, html )
		end)
	end)
end

function register_common_npc(npcs, dataTable, cb)
	local i = 0
	local results = {}
	iter_register_common_npc = function()
		i = i + 1
		local npc = npcs[i]
		if npc == nil then return cb(results) end
		data = dataTable[npc:get_name()]
		if npc == nil then return iter_register_common_npc() end
		do_register_then(npc, data, function(code, html)
			res = check_register_common_npc(code, html, data)
			results[npc:get_name()] = res
			iter_register_common_npc()
		end)
	end
	iter_register_common_npc()
end

function check_register_common_npc( code, html, data )
	if code < 200 or code >= 400 then
		sol.log.error("Code ["..code.."]. Le code de retour HTTP attendu est 2xx ou 3xx")
		if code == 500 then
			html = parse_html(html, false)
			local pre = html_search(html, "pre") or {}
			if pre.textNode then
				sol.log.debug(pre.textNode)
			end
		end
		return false
	end
	local user = data.email
	res = sol.sql.query("select * from users where email = '"..user.."'")
	if res == "Ok" then
		sol.log.error("L'utilisateur '"..user.."' n'a pas été retouvé en base après enregistrement")
		return false
	end
	res = res[1]
	for k, v in pairs(res) do
		if data[k] ~= nil and data[k] ~= v then
			sol.log.error("La donnée "..k.."='"..v.."' de l'utilisateur '"..user.."' ne correspond pas à celle transmise '"..data[k].."'")
			return false
		end
	end
	sol.log.debug("Enregistrement de '"..data.email.."'' Ok !")
	return true
end