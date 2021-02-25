-- Main Lua script of the quest.
-- See the Lua API! http://www.solarus-games.org/doc/latest

require("scripts/features")
require("scripts/multi_events")

function dump(o)
  if type(o) ~= 'table' then
    return tostring(o)
  end

 local s = '{ '
 local first = true
 for k,v in pairs(o) do
    if type(k) ~= 'number' then k = tostring(k) end
    if first == false then s = s .. ", " end
    first = false
    s = s .. k .. ' => ' .. dump(v) .. "\n"
 end
 return s .. '} '

end


-- Edit scripts/menus/initial_menus_config.lua to add or change menus before starting a game.
local initial_menus_config = require("scripts/menus/initial_menus_config")
local initial_menus = {}

-- This function is called when Solarus starts.
function sol.main:on_started()

  print("This is a sample quest for Solarus.")

  sol.video.set_window_title("Sample quest - Solarus " .. sol.main.get_solarus_version())

  sol.main.load_settings()
  math.randomseed(os.time())

--[[
  local code, t = sol.net.json_post("/", {hello="world"}, 
    {cookies = {JSESSIONID = "1234567890"}, headers = {UserAgent = "solarus"}} )
  print( dump(t) )


  sol.timer.start(sol.main, 250, function()
    local game_manager = require("scripts/game_manager")
    local game = game_manager:create("save1.dat")
    game:start();
  end)
  if true then return end
]]--

  -- Show the initial menus.
  if #initial_menus_config == 0 then
    return
  end

  for _, menu_script in ipairs(initial_menus_config) do
    initial_menus[#initial_menus + 1] = require(menu_script)
  end

  
  
  
  local on_top = false  -- To keep the debug menu on top.
  
  

  for i, menu in ipairs(initial_menus) do
    function menu:on_finished()
      if sol.main.get_game() ~= nil then
        -- A game is already running (probably quick start with a debug key).
        return
      end
      local next_menu = initial_menus[i + 1]
      if next_menu ~= nil then
        sol.menu.start(sol.main, next_menu)
      end
    end
  end

  sol.menu.start(sol.main, initial_menus[1], on_top)
  
  
  local game_meta = sol.main.get_metatable("game")
  game_meta:register_event("on_started", function(game)
    -- Skip initial menus when a game starts.
    for _, menu in ipairs(initial_menus) do
      sol.menu.stop(menu)
    end
  end)
end

-- Event called when the program stops.
function sol.main:on_finished()
  sol.main.save_settings()
end

-- Event called when the player pressed a keyboard key.
function sol.main:on_key_pressed(key, modifiers)

  local handled = false
  if key == "f11" or
    (key == "return" and (modifiers.alt or modifiers.control)) then
    -- F11 or Ctrl + return or Alt + Return: switch fullscreen.
    sol.video.set_fullscreen(not sol.video.is_fullscreen())
    handled = true
  elseif key == "f4" and modifiers.alt then
    -- Alt + F4: stop the program.
    sol.main.exit()
    handled = true
  elseif key == "escape" and sol.main.get_game() == nil then
    -- Escape in pre-game menus: stop the program.
    sol.main.exit()
    handled = true
  end

  return handled
end
