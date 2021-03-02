local item = ...
local game = item:get_game()

function item:on_started()
  self:set_savegame_variable("possession_item_key")
end
