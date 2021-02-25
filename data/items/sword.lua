local item = ...
local game = item:get_game()

-- Event called when the game is initialized.
function item:on_started()

  -- Initialize the properties of your item here,
  -- like whether it can be saved, whether it has an amount
  -- and whether it can be assigned.
  item:set_savegame_variable("possession_sword")
end

function item:on_variant_changed(variant)
  -- The possession state of the sword determines the built-in ability "sword".
  game:set_ability("sword", variant)
end
