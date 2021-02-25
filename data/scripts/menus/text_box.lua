-- Fenêtre de texte générale.

local language_manager = require("scripts/language_manager")

local function initialize_text_box_features(game)

	if game.get_text_box ~= nil then
	    -- Already done.
	    return
  	end

	local text_box = {
		width = 220,
		height = 60,
    cols = 5,
    rows = 1,
	  box_img = sol.sprite.create("hud/items_box"),
    dialog_surface = sol.surface.create(sol.video.get_quest_size()),
    line_surfaces = {},
    lines = {},
    cursor_pos = 1,
    -- cursor_sprite = sol.sprite.create("hud/items_box"),
    next_sprite = sol.sprite.create("hud/items_box"),
    line_spacing = 10,
    char_spacing = 6,
    scroll_pos = -1
  }

  -- Initialize dialog box data.
  text_box.font, text_box.font_size = language_manager:get_dialog_font()

  -- Exits the dialog box system.
  function text_box:quit()
    if sol.menu.is_started(text_box) then
      sol.menu.stop(text_box)
    end
  end

  function game:get_text_box()
    return text_box
  end

  function text_box:add_line( line )
  	table.insert( self.lines, line )
  end

  function text_box:set_size(cols, rows)
    self.cols = cols
    self.rows = rows
  	self.width  = cols * self.char_spacing + 16
  	self.height = rows * self.line_spacing + 14
  	self.dialog_surface = sol.surface.create(self.width, self.height)
  end

  function text_box:on_started()
  	game:set_suspended(true)
    self.next_sprite:set_animation("next")
    self.next_sprite:set_ignore_suspend()

    game:set_custom_command_effect("action", "close")
    -- game:set_custom_command_effect("attack", "info")

    self.cursor_pos = 1
  	self:show_dialog()

  	-- Set the correct HUD mode.
    self.backup_hud_mode = game:get_hud_mode()
    game:set_hud_mode("dialog")
    -- Set the HUD on top.
    game:bring_hud_to_front()
  end

  function text_box:on_finished()
    self.cursor_pos = 1
    self.lines = {}
  	game:set_suspended(false)
    -- Remove overriden command effects.
    if game.set_custom_command_effect ~= nil then
      game:set_custom_command_effect("action", nil)
      game:set_custom_command_effect("attack", nil)
    end
    game:set_hud_mode(self.backup_hud_mode)
  end

  function text_box:show_dialog()
    local nb_visible_lines = table.getn(self.lines) - self.cursor_pos + 1
    if ( nb_visible_lines > self.rows ) then 
      nb_visible_lines = self.rows 
    end
    self.line_surfaces = {}
    -- print( self.cursor_pos, "> ", nb_visible_lines )
    local x = self.cursor_pos
    for i = 1, nb_visible_lines do
      -- dialog_box.lines[i] = ""
      self.line_surfaces[i] = sol.text_surface.create{
        horizontal_alignment = "left",
        vertical_alignment = "top",
        font = self.font,
        font_size = self.font_size,
        color = {0,0,0},
        text = self.lines[x]
      }
      x = x + 1
    end
    
    if table.getn(self.lines) > self.rows then 
      self.scroll_pos = (self.height-21) * (self.cursor_pos - 1) / ((table.getn(self.lines) - self.rows - 1))
    else
      self.scroll_pos = -1
    end
  end

  -- Draws the dialog box.
  function text_box:on_draw(dst_surface)
  	local x, y = 0, 0

    self.dialog_surface:clear()

    -- draw background
    self.dialog_surface:fill_color( {255, 255, 255}, 7, 7, self.width-14, self.height-14 )

    -- draw lines
    x = 8
    y = 5
    for i, item in pairs(self.line_surfaces) do
      self.line_surfaces[i]:draw(self.dialog_surface, x, y)
      y = y + self.line_spacing
    end

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
      if self.scroll_pos >= 0 then 
        self.box_img:set_animation("scroll")
        self.box_img:set_direction(0)
      else 
	      self.box_img:set_direction(1)
      end
	    self.box_img:draw(self.dialog_surface, self.width-7, y)
      y = y + 19
  	end

    if self.scroll_pos >= 0 then 
      self.box_img:set_animation("cursor")
      self.box_img:set_direction(0)
      self.box_img:draw(self.dialog_surface, self.width-6, self.scroll_pos+7)
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

    if self.scroll_pos >= 0 and self.cursor_pos + self.rows < table.getn(self.lines) then
      self.next_sprite:draw(self.dialog_surface, self.width/2, self.height-3)
    end


    -- Final blit.
    self.dialog_surface:draw(dst_surface, 45, 15)
  end

  -- Commands to control the dialog box.
  function text_box:on_command_pressed(command)
  	if command == "action" then
  		sol.menu.stop( text_box )
    elseif command == "down" then
      local to = self.cursor_pos + 1
      if to + self.rows > table.getn(self.lines) then to = self.cursor_pos end
      self.cursor_pos = to
    elseif command == "up" then
      local to = self.cursor_pos - 1
      if to < 1 then to = self.cursor_pos end
      self.cursor_pos = to
    end
    self:show_dialog()
  end

end

-- Set up the dialog box on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_text_box_features)
return true
 