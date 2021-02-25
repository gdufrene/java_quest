-- Animated Solarus logo by Maxs.

-- You may include this logo in your quest to show that you use Solarus,
-- but this is not mandatory.

-- Example of use:
-- local solarus_logo = require("menus/solarus_logo")
-- sol.menu.start(solarus_logo)
-- function solarus_logo:on_finished()
--   -- Do whatever you want next (show a title screen, start a game...)
-- end
local solarus_logo_menu = {}

-- Main surface of the menu.
local surface = sol.surface.create(260, 130)

-- Solarus title sprite.
local bar1 = sol.sprite.create("menus/logo_univ")
bar1:set_animation("bar1")

-- Solarus subtitle sprite.
local bar2 = sol.sprite.create("menus/logo_univ")
bar2:set_animation("bar2")

-- Sun sprite.
local logo = sol.sprite.create("menus/logo_univ")
logo:set_animation("logo")

-- Black square below the sun.
local black_square = sol.surface.create(150, 130)
black_square:fill_color{0, 0, 0}

-- Step of the animation.
local animation_step = 0

-- Time handling.
local timer = nil

local title = sol.text_surface.create({
  font = "8_bit",
  text = "Université"
})
local title2 = sol.text_surface.create({
  font = "8_bit",
  text = "de Lille"
})

-------------------------------------------------------------------------------

-- Rebuilds the whole surface of the menu.
local function rebuild_surface()

  surface:clear()

  -- Draw the title (after step 1).
  if animation_step >= 1 then
    -- title:draw(surface)
  end

  -- Draw the sun.
  logo:draw(surface, 0, 0)

  -- Draw the bar1.
  bar1:draw(surface, 24, 18)

  -- Draw the bar2.
  bar2:draw(surface, 57, 73)

  -- Draw the black square to partially hide the sun.
  black_square:draw(surface, 110, 0)

  -- Draw the title
  if animation_step >= 2 then
    title:draw(surface, 120, 50)
    title2:draw(surface, 120, 65)
  end
end

-------------------------------------------------------------------------------

local skip_logo = false

-- Starting the menu.
function solarus_logo_menu:on_started()


  if skip_logo then
    sol.timer.start(solarus_logo_menu, 100, function()
      sol.menu.stop(solarus_logo_menu)
    end)
    return
  end
  

  -- Initialize or reinitialize the animation.
  animation_step = 0
  timer = nil
  surface:set_opacity(255)
  -- logo:set_direction(0)
  logo:set_xy(0, 0)
  bar1:set_xy(0, 0)
  bar2:set_xy(0, 0)
  -- Start the animation.
  solarus_logo_menu:start_animation()

  -- Update the surface.
  rebuild_surface()


end

-- Animation step 1.
function solarus_logo_menu:step1()

  animation_step = 1
  -- Stop movements and replace elements.
  logo:stop_movement()
  logo:set_xy(0, 0)

  bar1:stop_movement()
  bar1:set_xy(0, 0)

  bar2:stop_movement()
  bar2:set_xy(0, 0)

  -- Play a sound.
  sol.audio.play_sound("diarandor/solarus_logo")
  -- Update the surface.
  rebuild_surface()
end

function fade_menu()
  sol.timer.start(solarus_logo_menu, 500, function()
    surface:fade_out()
    sol.timer.start(solarus_logo_menu, 700, function()
      sol.menu.stop(solarus_logo_menu)
    end)
  end)
end

-- Animation step 2.
function solarus_logo_menu:step2()

  animation_step = 2
  -- Update the surface.
  rebuild_surface()
  -- Start the final timer.
  fade_menu()

end

-- Run the logo animation.
function solarus_logo_menu:start_animation()

  -- Move the logo.
  local logo_movement = sol.movement.create("target")
  logo_movement:set_speed(150)
  logo_movement:set_target(0, 0)
  logo:set_xy(0, 130)
  -- Update the surface whenever the sun moves.
  function logo_movement:on_position_changed()
    rebuild_surface()
  end

    -- Move the first bar.
  local bar1_movement = sol.movement.create("target")
  bar1_movement:set_speed(150)
  bar1_movement:set_target(0, 0)
  bar1:set_xy(0, -110)
  -- Update the surface whenever the sun moves.
  function bar1_movement:on_position_changed()
    rebuild_surface()
  end

  -- Move the second bar.
  local bar2_movement = sol.movement.create("target")
  bar2_movement:set_speed(75)
  bar2_movement:set_target(0, 0)
  bar2:set_xy(50, 0)
  -- Update the surface whenever the sword moves.
  function bar2_movement:on_position_changed()
    rebuild_surface()
  end

  -- Start the movements.
  logo_movement:start(logo, function()
    bar2_movement:start(bar2)
    bar1_movement:start(bar1, function()

      if not sol.menu.is_started(solarus_logo_menu) then
        -- The menu may have been stopped, but the movement continued.
        return
      end

      -- If the animation step is not greater than 0
      -- (if no key was pressed).
      if animation_step <= 0 then
        -- Start step 1.
        solarus_logo_menu:step1()
        -- Create the timer for step 2.
        timer = sol.timer.start(solarus_logo_menu, 250, function()
          -- If the animation step is not greater than 1
          -- (if no key was pressed).
          if animation_step <= 1 then
            -- Start step 2.
            solarus_logo_menu:step2()
          end
        end)
      end
    end)
  end)
end

-- Draws this menu on the quest screen.
function solarus_logo_menu:on_draw(screen)

  -- Get the screen size.
  local width, height = screen:get_size()

  -- Center the surface in the screen.
  surface:draw(screen, width / 2 - 120, height / 2 - 50)
end

-- Called when a keyboard key is pressed.
function solarus_logo_menu:on_key_pressed(key)

  if key == "escape" then
    -- Escape: quit Solarus.
    sol.main.exit()
  else
    -- If the timer exists (after step 1).
    if timer ~= nil then
      -- Stop the timer.
      timer:stop()
      timer = nil
      -- If the animation step is not greater than 1
      -- (if the timer has not expired in the meantime).
      if animation_step <= 1 then
        -- Start step 2.
        solarus_logo_menu:step2()
      end

    -- If the animation step is not greater than 0.
    elseif animation_step <= 0 then
      -- Start step 1.
      solarus_logo_menu:step1()
      -- Start step 2.
      solarus_logo_menu:step2()
    end

    -- Return true to indicate that the keyboard event was handled.
    return true
  end
end

-- Return the menu to the caller.
return solarus_logo_menu

