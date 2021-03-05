
local main_menu = {}

local color_orange = {241,174,8,255}
local color_white = {255,255,255,255}
local color_blue = {24,175,240,255}

local current_step = 0
local in_fade = false

-- Main surface of the menu.
local surface = sol.surface.create(320, 240)

local title = sol.text_surface.create({
  font = "8_bit",
  text = "Java EE Spring ///",
  vertical_alignment = "bottom",
})
title:set_color_modulation(color_orange)

local title2 = sol.text_surface.create({
  font = "8_bit",
  text = "prêt à l'emploi",
  vertical_alignment = "bottom",
})

local commencer = sol.text_surface.create({
  font = "8_bit",
  text = "Commencer",
  vertical_alignment = "top"
})
commencer:set_color_modulation(color_blue)

local current_text = 0
local rolling_text = {
  "Réalisé avec Solarus.",
  "Projet : Université de Lille.",
  "Graphiques : Max Mraz, Alex Gleason ..",
  "Graphiques : Diarandor.",
  "Moteur du Jeu : Solarus team.",
  "Scénario Quête : Guillaume Dufrêne.",
  "Musique : Eduardo."
}
local rolling_text_surface = nil
local text_movement = nil

local logo_surface = sol.surface.create(120, 60)
local logo = sol.sprite.create("menus/team_logo")
logo:set_animation("static")
local logo_univ = sol.sprite.create("menus/logo_univ_full")
logo_univ:set_animation("static")
logo_univ:set_scale(0.8, 0.8)

local cursor = sol.sprite.create("menus/arrow")

local printed = false

function main_menu:rebuild_surface()
    -- Get the screen size.
  local width, height = surface:get_size()
  surface:fill_color(color_white)

  -- title and line
  title:draw(surface, 2, 20)
  title2:draw(surface, 160, 20)
  surface:fill_color(color_orange, 0, 22, width, 3)

  -- begin and cursor
  if current_step >= 3 then
    commencer:draw(surface, 120, 120)
    cursor:draw(surface, 108, 122)
  end

  -- logos and rolling text
  if text_surface then
    text_surface:draw(surface, 125, height - 2)
  end
  main_menu:draw_logos()
  logo_surface:draw(surface, 0, height - 60)
end

function main_menu:on_draw(screen)
  main_menu:rebuild_surface()
  surface:draw(screen)
end

function main_menu:draw_logos()
  logo_surface:fill_color(color_white)
  logo_univ:draw(logo_surface, 2, 5)
  logo:draw(logo_surface, 50, 2)
end

function main_menu:title_animation()
  -- Move the title.
  title:set_xy(-160, 0)
  local title_movement = sol.movement.create("target")
  title_movement:set_speed(150)
  title_movement:set_target(0, 0)
  title_movement:start(title)

  title2:set_xy(160, 0)
  title_movement = sol.movement.create("target")
  title_movement:set_speed(150)
  title_movement:set_target(0, 0)
  title_movement:start(title2)
  title_movement.on_finished = main_menu.step_animation 
end

function main_menu:next_text_animation()
  if in_fade then return end
  current_text = current_text + 1
  local text = rolling_text[current_text]
  if not text then
    current_text = 0
    sol.timer.start(main_menu, 5000, main_menu.next_text_animation)
    return
  end
  text_surface = sol.text_surface.create({
    font = "enter_command",
    text = text,
    vertical_alignment = "bottom",
    color = {0,0,0},
    font_size = 16
  })
  -- Move the text.
  text_surface:set_xy(160, 0)
  text_movement = sol.movement.create("target")
  text_movement:set_speed(50)
  text_movement.cycle = 1
  text_movement.on_finished = function (self)
    if self.cycle == 1 then
      self:set_target(0, 0)
    elseif self.cycle == 2 then
      sol.timer.start(main_menu, 1500, function ()
        if in_fade then return end
        self:set_target(0, 20)
        self:start(text_surface)
      end)
    else
      self:stop()
      main_menu:next_text_animation()
    end
    self.cycle = self.cycle + 1
  end
  text_movement:on_finished()
  text_movement:start(text_surface)
end

function main_menu:on_started()
  main_menu:step_animation()
  sol.audio.play_music("eduardo/title_screen")
end

function main_menu:team_logo_loop_animations()
  logo:set_animation("shine", function()
    logo:set_animation("static")
    if in_fade then return end
    sol.timer.start(main_menu, 3500, main_menu.team_logo_loop_animations)
  end)
end


function main_menu:step_animation()
  current_step = current_step + 1
  if current_step == 1 then
    main_menu:title_animation()
  elseif current_step == 2 then
    logo:set_animation("rotation", main_menu.team_logo_loop_animations)
    main_menu:step_animation()
  elseif current_step == 3 then
    main_menu:next_text_animation()
    cursor:set_animation("blink")
  end
end

function main_menu:fade_menu()
  sol.timer.start(main_menu, 50, function()
    surface:fade_out()
    sol.timer.start(main_menu, 700, function()
      if text_movement then text_movement:stop() end
      sol.menu.stop(main_menu)
    end)
  end)
end

-- Called when a keyboard key is pressed.
function main_menu:on_key_pressed(key)
  if key == "escape" then
    -- Escape: quit Solarus.
    sol.main.exit()
  else
    if not in_fade then
      in_fade = true
      main_menu:fade_menu()
    end
    return true
  end
end

return main_menu
