-- Lua script of item potion.
-- This script is executed only once for the whole game.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local item = ...
local game = item:get_game()

function testflag(set, flag)
  return set % (2*flag) >= flag
end

function setflag(set, flag)
  if set % (2*flag) >= flag then
    return set
  end
  return set + flag
end

function clrflag(set, flag) -- clear flag
  if set % (2*flag) >= flag then
    return set - flag
  end
  return set
end

function item:get_save_flag()
  local popo = game:get_value("potion_flag")
  if popo == nil then popo = 0 end
  return popo
end


function item:on_obtained(variant)
  local flag = math.pow(2, variant)
  local popo = setflag( self:get_save_flag(), flag );
  game:set_value("potion_flag", popo)
  -- print ( "set popo to ", popo )
end

function item:offer(variant)
  local flag = math.pow(2, variant)
  local popo = self:get_save_flag()
  if not testflag( popo, flag ) then return false end
  popo = clrflag( popo, flag );
  game:set_value("potion_flag", popo)
  -- print ( "reset popo to ", popo )
  return true
end 


