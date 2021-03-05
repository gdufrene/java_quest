local map = ...
local game = map:get_game()


local nb_popo = 0
local cookies_a = {}
local cookies_b = {}
local key_a = -1
local key_b = -1


local chestUrl = "http://localhost:8080/cave/chest"

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  local ladder = game:get_value("session_ladder")
  if ladder == 1 then
  	map:set_entities_enabled("ladder")
  end
  chest1:set_open(true)
  chest2:set_open(true)
end

function check_chest( cookies, key, item, variant ) 
	local hero = game:get_hero()
	local code, body, head
	code, body, head = sol.net.http_get(chestUrl, {cookies=cookies})
	-- print( "check chest on session " .. cookies['JSESSIONID'] .. " returns " .. body )
	sol.log.debug("[GET] "..chestUrl)
	if ( code == 200 and tonumber(body) == key ) then
		hero:start_treasure(item, variant)
	else
		sol.log.error("Code ["..code.."] Body: "..body)
		sol.audio.play_sound("wrong")
		hero:unfreeze();
	end
end

function chest1:on_opened(treasure_item, treasure_variant, treasure_savegame_variable)
	check_chest(cookies_a, key_a, treasure_item:get_name(), treasure_variant)
end

function chest2:on_opened(treasure_item, treasure_variant, treasure_savegame_variable)
	check_chest(cookies_b, key_b, treasure_item:get_name(), treasure_variant)
end

function init_chest(chest) 
	local key = math.random(100)
	local cookies
	local code, body, head
	
	local addItemUrl = chestUrl.."?item="..key
	code, body, head = sol.net.http_post(addItemUrl)
	sol.log.debug("[POST] "..addItemUrl)
	if ( code == 200 ) then 
		cookies = head["cookies"] 
		chest:set_open(false)
	else 
		key = -1
	end

	-- print( "init chest " .. chest:get_name() .. " with key " .. key .. " on session " .. cookies["JSESSIONID"] )

	return key, cookies
end

function sw_chest:on_activated()

	local ladder = game:get_value("session_ladder")
	if ladder == 1 then
		return
	end

	key_b, cookies_b = init_chest(chest2)
	key_a, cookies_a = init_chest(chest1)

	if ( key_a > 0 and key_b > 0 ) 
		then sol.audio.play_sound("cursor")
		else sol.audio.play_sound("wrong")
	end

end



function offer_popo(npc, variant)

	local popo = game:get_item("potion")
	-- print( "npc name = ", npc:get_name() )
	-- print( "popo = ", popo:get_save_flag() )
	if popo:offer( variant ) then
		local properties = {}
		properties["treasure_name"] = "potion"
		properties["treasure_variant"] = variant;
		local x, y, layer = npc:get_position();
		properties["x"] = x;
		properties["y"] = y - 8;
		properties["layer"] = layer;
		local pickable = map:create_pickable( properties )
		nb_popo = nb_popo + 1
		if nb_popo == 2 then
			game:set_value("session_ladder", 1)
			map:set_entities_enabled("ladder")
			sol.audio.play_sound("door_open")
		end
	end

end

function popo1:on_interaction()
	offer_popo(self, 2)
end

function popo2:on_interaction()
	offer_popo(self, 3)
end
