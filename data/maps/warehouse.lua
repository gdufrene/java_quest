-- Lua script of map warehouse.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
	paul.step = 1
	assistant.step = 3
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
		always_continue,
		-- 5 -- test delete
		fn_testing_warehouse("testDelete"),
	}
	run_step(self, steps[self.step])
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