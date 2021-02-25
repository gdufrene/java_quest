-- Lua script of map http/simple.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end

function switch_bomb:on_activated()
  local a = math.random(100)
  local b = math.random(100)
  local str = "a=" .. a .. "&b=" .. b 
	code, body = sol.net.http_get("/sum?"..str)
    if code == 200 and tonumber(body) == (a+b) then
      sol.audio.play_sound("ok")
	  chest_bomb:set_enabled(true)
	else
	  sol.audio.play_sound("wrong3")
    end
end