local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  -- sol.audio.set_music_volume(15)
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

function door_switch:on_interaction()
  local url = "http://localhost:8080/"
  code, body = sol.net.http_get(url)

  sol.log.debug("[GET] "..url.." returns code " .. code)

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