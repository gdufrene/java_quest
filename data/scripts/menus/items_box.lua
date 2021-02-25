-- Inventaire d'objets avec actions variables.

local function initialize_items_box_features(game)

	if game.get_items_box ~= nil then
	    -- Already done.
	    return
  	end

	local items_box = {
		width = 220,
		height = 60,
    cols = 5,
    rows = 1
	}

    items_box.box_img = sol.sprite.create("hud/items_box")
    items_box.icons_img = sol.surface.create("hud/dialog_icons.png")
    items_box.dialog_surface = sol.surface.create(sol.video.get_quest_size())
    items_box.items = {}
    items_box.cursor_pos = 0
    items_box.cursor_sprite = sol.sprite.create("hud/items_box")

  -- Exits the dialog box system.
  function items_box:quit()
    if sol.menu.is_started(items_box) then
      sol.menu.stop(items_box)
    end
  end

  function game:get_items_box()
    return items_box
  end

  function items_box:add_item( sprite_id, amount, selectable )
    selectable = selectable or true
  	table.insert( self.items, {sprite=sprite_id, amount=amount, selectable=selectable} )
  end

  function items_box:set_size(cols, rows)
    self.cols = cols
    self.rows = rows
  	self.width  = cols * 19 + 14
  	self.height = rows * 19 + 14
  	self.dialog_surface = sol.surface.create(self.width, self.height)
  end

  function items_box:on_started()
  	game:set_suspended(true)
    self.cursor_sprite:set_animation("slot_selection")
    self.cursor_sprite:set_ignore_suspend()
  	self:show_dialog()
  	-- Set the correct HUD mode.
    self.backup_hud_mode = game:get_hud_mode()
    game:set_hud_mode("dialog")
    -- Set the HUD on top.
    game:bring_hud_to_front()
  end

  function items_box:on_finished()
  	self.items = {}
  	game:set_suspended(false)
    -- Remove overriden command effects.
    if game.set_custom_command_effect ~= nil then
      game:set_custom_command_effect("action", nil)
      game:set_custom_command_effect("attack", nil)
    end
    game:set_hud_mode(self.backup_hud_mode)
  end

  function items_box:show_dialog()
  	game:set_custom_command_effect("action", "close")
  	game:set_custom_command_effect("attack", "info")
  end

  -- Draws the dialog box.
  function items_box:on_draw(dst_surface)
  	local x, y = 0, 0

    self.dialog_surface:clear()

    -- self.dialog_surface:fill_color( {0, 0, 0} )

    -- draw borders
    self.box_img:set_animation("borders")
    for x = 7, self.width-14, 19 do
	    self.box_img:set_direction(0)
	    self.box_img:draw(self.dialog_surface, x, 0)
	    self.box_img:set_direction(2)
	    self.box_img:draw(self.dialog_surface, x, self.height-7)
	end
	for y = 7, self.height-14, 19 do
	    self.box_img:set_direction(3)
	    self.box_img:draw(self.dialog_surface, 0, y)
	    self.box_img:set_direction(1)
	    self.box_img:draw(self.dialog_surface, self.width-7, y)
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

    -- draw background
    self.dialog_surface:fill_color( {255, 255, 255}, 7, 7, self.width-14, self.height-14 )

    -- draw items
    x = 7
    y = 7
    for i, item in pairs(self.items) do
      if self.cursor_pos == i then
        -- self.box_img:set_animation("slot_selection")
        -- self.box_img:set_direction(0)
        self.cursor_sprite:draw(self.dialog_surface, x, y)
      else
        self.box_img:set_animation("slot")
      	self.box_img:set_direction(0)
        self.box_img:draw(self.dialog_surface, x, y)
      end
    	local sprite_img = sol.surface.create(item.sprite)
    	sprite_img:draw_region(0, 0, 16, 16, self.dialog_surface, x, y)
    	local amount_text = sol.text_surface.create( {text=""..item.amount, horizontal_alignment="right", vertical_alignment="bottom"} )
    	amount_text:draw(self.dialog_surface, x+18, y+18)
    	x = x + 19
    	if x > self.width then 
    		x = 7
    		y = y + 19
    	end
    end

    -- Final blit.
    self.dialog_surface:draw(dst_surface, 50, 20)
  end

  -- Commands to control the dialog box.
  function items_box:on_command_pressed(command)
  	if command == "action" then
  		sol.menu.stop( items_box )
    elseif command == "right" then
      self.cursor_pos = math.min( self.cursor_pos + 1, table.getn( self.items ) )
    elseif command == "left" then
      self.cursor_pos = math.max( self.cursor_pos - 1, 1 )
    elseif command == "down" then
      local to = self.cursor_pos + self.cols
      if to > table.getn( self.items ) then to = self.cursor_pos end
      self.cursor_pos = to
    elseif command == "up" then
      local to = self.cursor_pos - self.cols
      if to < 1 then to = self.cursor_pos end
      self.cursor_pos = to
    end
  end

end

-- Set up the dialog box on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_items_box_features)
return true
 