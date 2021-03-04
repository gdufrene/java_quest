
-- for font and font_size
local language_manager = require("scripts/language_manager")

local function initialize_empty_box_features(game)

  if game.get_empty_box ~= nil then
    -- Already done.
    return
  end

	local box = {
		width = 220,
		height = 60,
    title = nil,
    sprite = nil
	}

  function game:get_empty_box()
    return box
  end

  box.box_img = sol.sprite.create("hud/items_box")
  box.icons_img = sol.surface.create("hud/dialog_icons.png")
  box.dialog_surface = sol.surface.create(sol.video.get_quest_size())
  box.cursor_sprite = sol.sprite.create("hud/items_box")

  box.font, box.font_size = language_manager:get_dialog_font()

  -- Exits the dialog box system.
  function box:quit()
    if sol.menu.is_started(box) then
      sol.menu.stop(box)
    end
  end

  function box:set_size(w, h)
  	self.width  = w + 16
  	self.height = h + 14
  	self.dialog_surface = sol.surface.create(self.width, self.height)
  end

  function box:on_started()
  	game:set_suspended(true)
    game:set_custom_command_effect("action", "close")
    -- game:set_custom_command_effect("attack", "info")
  	self:show_dialog()
  	-- Set the correct HUD mode.
    self.backup_hud_mode = game:get_hud_mode()
    game:set_hud_mode("dialog")
    -- Set the HUD on top.
    game:bring_hud_to_front()
  end

  function box:on_finished()
    self.title = nil
    self.sprite = nil
  	game:set_suspended(false)
    -- Remove overriden command effects.
    if game.set_custom_command_effect ~= nil then
      game:set_custom_command_effect("action", nil)
      game:set_custom_command_effect("attack", nil)
    end
    game:set_hud_mode(self.backup_hud_mode)
  end

  function box:show_dialog()
    if self.title ~= nil then
      self.title_surface = sol.text_surface.create{
        horizontal_alignment = "left",
        vertical_alignment = "top",
        font = self.font,
        font_size = self.font_size,
        color = {0,0,0},
        text = self.title
      }
    end
  end

  -- Draws the dialog box.
  function box:on_draw(dst_surface)
  	local x, y = 0, 0
    self.dialog_surface:clear()
    -- draw background
    self.dialog_surface:fill_color( {255, 255, 255}, 7, 7, self.width-14, self.height-14 )
        -- draw borders
    self.box_img:set_animation("borders")
    local limit = self.width - 7
    x = 7
    while x < limit do
      if x + 19 > limit then x = limit - 19 end
	    self.box_img:set_direction(0)
	    self.box_img:draw(self.dialog_surface, x, 0)
	    self.box_img:set_direction(2)
	    self.box_img:draw(self.dialog_surface, x, self.height-7)
      x = x + 19
  	end
    limit = self.height - 7
    y = 7
    while y < limit do
      self.box_img:set_animation("borders")
      if y + 19 > limit then y = limit - 19 end
      self.box_img:set_direction(3)
      self.box_img:draw(self.dialog_surface, 0, y)
      self.box_img:set_direction(1)
      self.box_img:draw(self.dialog_surface, self.width-7, y)
      y =  y + 19
  	end

    if self.title_surface then
      self.title_surface:draw(self.dialog_surface, 7, 4)
    end

    if self.sprite then
      -- local w, h = self.sprite:get_size()
      self.sprite:draw(self.dialog_surface, 10, 20)
    end

    -- draw corners
    self.box_img:set_animation("corners")
    self.box_img:set_direction(0)
    self.box_img:draw(self.dialog_surface, 0, 0)
    self.box_img:set_direction(1)
    self.box_img:draw(self.dialog_surface, self.width-7, 0)
    self.box_img:set_direction(2)
    self.box_img:draw(self.dialog_surface, self.width-7, self.height-7)
    self.box_img:set_direction(3)
    self.box_img:draw(self.dialog_surface, 0, self.height-7)

    -- Final blit.
    self.dialog_surface:draw(dst_surface, 45, 15)
  end

  -- Commands to control the dialog box.
  function box:on_command_pressed(command)
    if command == "action" then
      sol.menu.stop( self )
      return
    end
    self:show_dialog()
  end
end

-- Set up the dialog box on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_empty_box_features)
return true
