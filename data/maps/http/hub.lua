-- Lua script of map hub.
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
  sol.audio.set_music_volume(15)

  
  
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()
  

end


function welcome_sign:on_interaction()

--[[
  dialog = sol.language.get_dialog("hub.welcome_sign")
  dialog["text"] = "Salut mec, ca roule ?"
  print( "text = ", dialog["text"] )
  name =[[Salut mec ça roule ?
j'espère que çà marche.
non ?
Si, surement.
sinon c'est balo !]]
--]]

  game:start_dialog("hub.welcome_sign", name)
end

-- function param_sign:on_interaction()
--   local a = math.random(100)
--   local b = math.random(100)
--   local str = "a=".. a .. "&b=" .. b
--   game:start_dialog("hub.param_sign", str, function()
--     code, body = sol.net.http_get("/sum?"..str)
--     if code == 200 and tonumber(body) == (a+b) then
--       sol.audio.play_sound("ok")
--     end
--   end)
-- end

function door_switch:on_interaction()

  -- print( "run", sol.net.run() )

  code, body = sol.net.http_get("/")

  print("GET / returns code " .. code)

  if code == 200 then
    door = map:get_entity("door")
    if door ~= nil then 
      door:set_enabled( false ) 
      sol.audio.play_sound("stone")
    end
  else
    sol.audio.play_sound("wrong3")
  end
end