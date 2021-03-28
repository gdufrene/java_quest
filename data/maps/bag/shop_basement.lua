-- Lua script of map shop_basement.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

local bag_url = "http://localhost:8080/exo103/bag"

require("scripts/util/html_parser")
require("scripts/util/dump")


-- TODO: set this to 1
local dave_step = 1
local bob_step = 1
local spencer_step = 1

local deliveries = {
	-- chests will get ref and amount
	chest_1 = {
		ref = "scroll"
	},
	chest_2 = {
		ref = "bomb"
	},
	chest_3 = {
		ref = "oil_lamp"
	}
}

local bob_expected = {
	scroll = -1,
	bomb = -1,
	oil_lamp = -1
}

local spencer_expected = {
	bow_arrow = -1,
	makopa = -1,
}

local test_chest_fn = {
	chest_1 = function()
		local item = {}
		item["ref"] = "scroll"
		item["amount"] = math.random(10) + 3
		local code = do_delivery( item )
		return code == 200
	end,
	chest_2 = function()
		local item = {}
		item["ref"] = "oil_lamp"
		-- item["amout"] = math.random(10) + 3
		local code = do_delivery( item )
		return code == 400
	end,
	chest_3 = function()
		local item = {}
		item["ref"] = "oil_lamp"
		item["amount"] = "boom"
		local code = do_delivery( item )
		return code == 400
	end
}

local second_bag_content = {}
local second_bag_cookies = {}
local first_bag_cookies = {}

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
	if game:get_item("item_bag"):has_variant() then
		dave_step = 11
	end

	for entity in map:get_entities("chest_") do
		local delivery = deliveries[entity:get_name()]
 		delivery.x, delivery.y = entity:get_position()
 		delivery.amount = math.random(10) + 3
	end
	if dave_step > 1 and dave_step < 10 then 
		map:set_entities_enabled("dave_bag")
	end
	if dave_step == 3 then
		map:set_entities_enabled("chest")
	end

	if bob_step > 1 then
		map:set_entities_enabled("bob_bag")
	end

	if spencer_step > 1 then
		map:set_entities_enabled("spencer_bag")
	end

	if dave_step == 11 then
		bob:set_enabled(false)
		spencer:set_enabled(false)
	end

end


function bag_expectation()
	local expected_content = {}
	local bag_cookies = {}
	local ret = {}
	ret.expect = function(item_names)
		for _, name in ipairs(item_names) do
			expected_content[name] = -1
		end
	end
	ret.post = function()
		init_bag_content(expected_content, bag_cookies)
	end
	ret.showCheck = function( onSucceed )
		local items = get_bag_items(bag_cookies, bag_url..".jsp")
		show_item_box( items )
		if check_deliveries(expected_content, items) == true then 
			onSucceed()
		end
	end
	ret.attachNpc = function(npc, cb)
		npc.on_interaction = function()
			ret.showCheck(cb)
		end
	end
	return ret
end

function do_delivery(delivery, cookies) 
	local body = ""
	if delivery.ref ~= nil then
		body = body .. string.format("ref=%s", delivery.ref)
	end
	if delivery.amount ~= nil then
		if body ~= "" then
			body = body .. "&"
		end
		body = body .. string.format("qty=%s", delivery.amount)
	end
	local ctx = {
		headers = {},
		cookies = cookies
	}
	ctx.headers["Content-Type"] = "application/x-www-form-urlencoded"
	sol.log.debug("[POST] "..bag_url.." "..body)
	sol.log.debug("[JSESSIONID] "..(cookies and cookies['JSESSIONID'] or "-vide-"))
	local code, html, headers = sol.net.http_post(bag_url, body, ctx)
	return code, (headers ~= nil and headers.cookies or nil)
end







function check_html_1(html)
	local html = parse_html(html, false)
	local form = html_search(html, "form")
	if form == nil then
		return "Il n'y a pas de formulaire dans la page"
	end
	-- print ( dump(form) )
	if form.attr.method:upper() ~= "POST" then
		return "La méthode de transmission des données du formulaire n'est pas correcte"
	end
	local inputs = html_all(form.childNodes, "input")
	local foundInput = { ref = false, qty = false, submit = false }
	if inputs ~= nil then
		for k, v in pairs(inputs) do
			if v.attr.type == "submit" then
				foundInput["submit"] = true
			end
			if v.attr.name ~= nil or v.attr.type == "text" then
				foundInput[v.attr.name] = true
			end
		end
	end
	for k, v in pairs(foundInput) do 
		if v == false then 
			return "Il manque la zone '" .. k .. "' dans le formulaire"
		end
	end
	return ""
end

function extract_item(node) 
	if node.attr == nil 
		or node.attr.class == nil 
		or node.childNodes == nil
		or node.childNodes[1].value == nil 
	then return nil, nil end
	return node.attr.class, tonumber(node.childNodes[1].value)
end

function html_to_items(html)
	local ul = html_search(html, "ul")
	local items = {}
	if ul ~= nill then 
		for _, li in ipairs(html_all(ul.childNodes, "li")) do
			local item_id, item_nb = extract_item(li)
			if item_id ~= nil then
				local item = {} 
				item["ref"] = item_id
				item["qte"] = item_nb
				table.insert(items, item)
				-- print(item_id, item_nb)
			end
		end
	end
	return items
end

function check_deliveries(expected, items)
	-- print( "expected", dump(expected) )
	-- print( "items", dump(items) )
	local valid_items = {}
	for k, item in pairs(expected) do
		valid_items[k] = false
	end
	for _, item in pairs(items) do
		local k = item.ref
		valid_items[k] = false
		if expected[k] == item.qte then valid_items[k] = true end
	end
	-- print( "valid_items", dump(valid_items) )
	for k, valid in pairs(valid_items) do
		if valid == false then 
			sol.log.error(string.format("L'item %s ne possède pas la bonne quantité (%03d)", k, expected[k]))
			return false 
		end
	end
	return true
end

function show_item_box(items)
	local items_box = game:get_items_box()
	items_box:set_size(5, 1)
	for _, item in pairs(items) do
		items_box:add_item("items/"..item.ref..".png", item.qte)
	end
	sol.menu.start( game, items_box )
end

function get_bag_items(cookies, url)
	local ctx = {
		headers = {},
		cookies = cookies
	}
	if url == nil then url = bag_url end
	local code, html = sol.net.http_get(url, ctx)
	sol.log.debug("[GET] "..url)
	sol.log.debug("[JSESSIONID] "..(cookies and cookies['JSESSIONID'] or "-vide-"))
	-- local code, html = 200, "<html><head></head><body><ul><li class='scroll'>5</li><li class='bomb'>3</li><li class='oil_lamp'>6</li></ul></body></html>"
	if code ~= 200 then 
		sol.log.error("Code de retour http incorrect: " .. code)
		sol.audio.play_sound("wrong")
		return {}
	end
	-- print(code, html)
	html = parse_html(html, false)
	local items = html_to_items(html)
	return items
end

function bob_bag_npc:on_interaction() 
	local items = get_bag_items( first_bag_cookies )
	show_item_box(items)
	local expected = {}
	if bob_step == 2 and check_deliveries(bob_expected, items) then
		sol.audio.play_sound("ok")
		bob_step = bob_step + 1
		spencer_step = spencer_step + 1
		dave_step = dave_step + 1

		map:set_entities_enabled("spencer_bag")
	end
end

function spencer_bag_npc:on_interaction()
	local items = get_bag_items( second_bag_cookies )
	show_item_box(items)
	if spencer_step == 2 and check_deliveries(spencer_expected, items) then
		sol.audio.play_sound("ok")
		bob_step = bob_step + 1
		spencer_step = spencer_step + 1
		dave_step = dave_step + 1
	end
end

function get_chest_over(other)
	local x, y, layer = other:get_position()
	local w, h = other:get_size()
	for entity in map:get_entities_in_rectangle(x, y, w, h) do
		-- print( entity:get_name() )
		if entity:get_name() ~= nil and
			entity:get_name():find("chest_") ~= nil then
			return entity
		end
	end
end

function reset_chest_around(switch)
	local chest = get_chest_over(switch)
	if chest == nil then return end
	local delivery = deliveries[chest:get_name()]
	-- local locations = { 144, 160, 176 }
	-- local i = tonumber(chest:get_name():sub(-1)) 
	chest:set_position( delivery.x, delivery.y )
	-- delivery.amount = math.random(10) + 3
	return chest
end

local in_bag = 0



function tapis_sw:on_activated()
	local chest = get_chest_over( self )
	local test_function = test_chest_fn[chest:get_name()]
	local switch = self
	local test_chest_result = test_function()

	if test_chest_result == false then
		local x, y, layer = self:get_position()
		local explosion = map:create_explosion({layer=layer, x=x, y=y})
	end

	sol.timer.start(map, 100, function() 
		local chest = reset_chest_around( switch )
		if chest ~= nil and test_chest_result == true then 
			chest:set_enabled(false) 
			-- switch:set_activated(false)
			sol.audio.play_sound("ok")
			in_bag = in_bag + 1
			if in_bag == 1 then dave_step = dave_step + 1 end
			if in_bag == 3 then dave_step = dave_step + 1 end
		end
	end)
end

function spencer:on_interaction()
	game:start_dialog("spencer.step_" .. spencer_step, function(r)
		if spencer_step == 1 then
			-- attente du sac de Dave
		elseif spencer_step == 2 then
			-- init content everytime.
			init_bag_content(bob_expected, first_bag_cookies)
			init_bag_content(spencer_expected, second_bag_cookies)
		end
	end)
end

function init_bag_content(expected, cookies)
	for k, v in pairs(expected) do
		expected[k] = math.random(7) + 2
		local item = { ref = k, amount = expected[k] }
		local code, ret_cookies = do_delivery(item, cookies)
		if ret_cookies ~= nil then
			for k, v in pairs(ret_cookies) do
				cookies[k] = v
			end
			-- print("cookies", dump(cookies) )
		end
	end
end

function bob:on_interaction()
	game:start_dialog("bob.step_" .. bob_step, function(r)
		if bob_step == 1 then
			-- attente du sac de Dave
		elseif bob_step == 2 then
			if r == 2 then
				init_bag_content(bob_expected, first_bag_cookies)
			end
		end
	end)
end

function dave:on_interaction()
	game:start_dialog("dave.step_" .. dave_step, function(r)
		if dave_step == 1 then
			if r == 1 then 
				dave_step = dave_step + 1 
				map:set_entities_enabled("dave_bag")
			else
				self:on_interaction()
			end
		elseif dave_step == 2 then
			local code, html = sol.net.http_get(bag_url)
			local err = ""
			if ( code == 200 ) then 
				err = check_html_1(html)
			else
				err = "La requête a retourné un code " .. code
			end

			if err == "" then
				dave_step = dave_step + 1
				sol.audio.play_sound("ok")
				map:set_entities_enabled("chest_1")
			else
				sol.log.error(err)
				sol.audio.play_sound("wrong")
			end
		elseif dave_step == 3 then
			-- attendre qu'une caisse soit délivrée.
		elseif dave_step == 4 then
			map:set_entities_enabled("chest_2")
			map:set_entities_enabled("chest_3")
			-- attendre après les 2 autres caisses
		elseif dave_step == 5 then
			map:set_entities_enabled("bob_bag")
			bob_step = 2
			dave_step = dave_step + 1
		elseif dave_step == 6 then
			-- attente livraison à Spencer.
		elseif dave_step == 7 then
			-- attente ok Spencer
		elseif dave_step == 8 and r == 1 then
			dave_step = dave_step + 1
			self:on_interaction()
		elseif dave_step == 9 then
			map:set_entities_enabled("jsp_bag")
			local checks = {false, false}
			local do_check_fn = function(i) 
				return function()
					if checks[i] == true then return end
					sol.audio.play_sound("ok")
					checks[i] = true
					for _, v in pairs(checks) do
						if checks[i] == false then return end
					end
					dave_step = 10
				end
			end
			local jsp1 = bag_expectation()
			jsp1.expect({"bread", "compass", "croissant"})
			jsp1.attachNpc(jsp_bag_npc1, do_check_fn(1))
			jsp1.post()
			local jsp2 = bag_expectation()
			jsp2.expect({"flower_rose", "hookshot", "quiver"})
			jsp2.attachNpc(jsp_bag_npc2, do_check_fn(2))
			jsp2.post()
		elseif dave_step == 10 then
			local hero = game:get_hero()
			hero:start_treasure("item_bag", 1)
			map:set_entities_enabled("dave_bag", false)
			dave_step = dave_step + 1
		elseif dave_step > 11 then
			sol.log.warn("no more steps")
		end
		
	end)
end 