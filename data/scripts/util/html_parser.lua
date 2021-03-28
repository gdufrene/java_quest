
-- LUA HTML parser
-- code from https://gist.github.com/exebetche/6126573



local empty_tags = {
	br = true,
	hr = true,
	img = true,
	embed = true,
	param = true,
	area = true,
	col = true,
	input = true,
	meta = true,
	link = true,
	base = true,
	basefont = true,
	frame = true,
	isindex = true
}

-- omittable tags siblings
-- if an open tag from the primary entry  follow
-- an unclosed tag of the secondary,
-- the secondary is automatically closed
-- See http://www.w3.org/TR/html5/syntax.html#optional-tags
local omittable_tags = {
	tbody = {
		thead = true,
		tbody = true,
		tfoot = true
	},
	thead = {
		thead = true,
		tbody = true,
		tfoot = true
	},
	tfoot = {
		thead = true,
		tbody = true,
		tfoot = true
	},
	td = {
		td = true,
		th = true
	},
	th = {
		td = true,
		th = true
	},
	tr = {
		tr = true
	},
	dd = {
		dd = true,
		dt = true
	},
	dt = {
		dd = true,
		dt = true
	},
	optgroup = {
		optgroup = true,
		option = true
	},
	optgroup = {
		optgroup = true,
		option = true
	},
	address = { p = true},
	article = { p = true},
	aside = { p = true},
	blockquote = { p = true},
	dir = { p = true},
	div = { p = true},
	dl = { p = true},
	fieldset = { p = true},
	footer = { p = true},
	form = { p = true},
	h1 = { p = true},
	h2 = { p = true},
	h3 = { p = true},
	h4 = { p = true},
	h5 = { p = true},
	h6 = { p = true},
	header = { p = true},
	hgroup = { p = true},
	hr = { p = true},
	menu = { p = true},
	nav = { p = true},
	ol = { p = true},
	p = { p = true},
	pre = { p = true},
	section = { p = true},
	table = { p = true},
	ul= { p = true}
}

-- omittable tags children
local omittable_tags2 = {
	table = { 
		tr = true,
		td = true,
		p = true,
	},
	tr = { 
		td = true,
		p = true
	},
	td = {
		p = true
	}
}

function parse_html(data, lazy)
	local tree = {}
	local stack = {}
	local level = 0
	local new_level = 0
	table.insert(stack, tree)
	local node
	local lower_tag
	local script_open = false
	local script_val = ""
	local script_node = nil
	local tag_match = ""
	lazy = lazy or false

	for b, op, tag, attr, op2, bl1, val, bl2 in string.gmatch(
		data,
		"(<)(%/?!?)([%w:_-'\\\"%[]+)(.-)(%/?%-?)>"..
		"([%s\r\n\t]*)([^<]*)([%s\r\n\t]*)"
	) do
		lower_tag = string.lower(tag)
		
		if script_open then
			if lower_tag == "script" and op == "/" then
				node.childNodes[1].value = 	string.gsub(script_val, "^<!%[CDATA%[", "<!--//%1")				
				if val ~= "" then
					table.insert(stack[level], {
						tagName = "textNode",
						value = val
					})
				end
				level = level - 1
				script_open = false
			else
				script_val = script_val..b..op..tag..attr..op2..bl1..val..bl2
			end
		elseif op == "!" then
		elseif op == "/" then
			-- Check if the previous children elements end tag have been omitted
			-- and should be close automatically
			
			while not lazy 
			and omittable_tags2[lower_tag]	
			and #stack[level] > 0
			and omittable_tags2[lower_tag][stack[level][#stack[level]].tagName]
			do
				print("Auto closing "..
				stack[level][#stack[level]].tagName..
				" followed by ending "..lower_tag)
				
				level = level - 1
				table.remove(stack)
			end
			if level==0 then return tree end
			
			if lower_tag ~= stack[level][#stack[level]].tagName 
			then
				print("Mismatch: "..lower_tag..
				", (has "..stack[level][#stack[level]].tagName..")")
			end
			
			level = level - 1
			table.remove(stack)
		else
			
			level = level + 1
			node = nil
			node = {}
			node.tagName = lower_tag
			node.childNodes = {}
			
			if attr ~= "" then
				node.attr = {}
				local nbAttr = 0
				
				for n, v in string.gmatch(
					attr, 
					"%s([^%s=]+)=\"([^\"]+)\""
				) do
					node.attr[n] = string.gsub(v, '"', '[^\\]\\"')
					nbAttr = nbAttr + 1
				end
				
				for n, v in string.gmatch(
					attr, 
					"%s([^%s=]+)='([^']+)'"
				) do
					node.attr[n] = string.gsub(v, '"', '[^\\]\\"')
					nbAttr = nbAttr + 1
				end

				if nbAttr == 0 then
					for n, v in string.gmatch(
						attr, 
						"%s([^%s=]+)=([^ ]+)"
					) do
						node.attr[n] = string.gsub(v, '"', '[^\\]\\"')
						nbAttr = nbAttr + 1
					end
				end
			end
			
			if lower_tag == "script" 
			and node.attr
			and not node.attr["src"] 
			then
				script_val = bl1..val..bl2
				table.insert(node.childNodes, {
					tagName = "textNode",
					value = ""
				})
				
				table.insert(stack[level], node)
				script_open = true
			else
				-- Check if the previous sibling element end tag has been omitted
				-- and should be close automatically
					
				if not lazy 
				and omittable_tags[lower_tag]
				and level > 1 
				and stack[level-1]
				and #stack[level-1] > 0
				and omittable_tags[lower_tag][stack[level-1][#stack[level-1]].tagName] == true
				then
					print("Auto closing "..
					stack[level-1][#stack[level-1]].tagName..
					" followed by "..lower_tag)
					
					level = level - 1
					table.remove(stack)
					if level==0 then return tree end
				end
				
				table.insert(stack[level], node)
				
				if empty_tags[lower_tag] then
					if val ~= "" then
						table.insert(stack[level], {
							tagName = "textNode",
							value = val
						})
					end
					node.childNodes = nil
					level = level - 1
				else
					if val ~= "" then
						table.insert(node.childNodes, {
							tagName = "textNode",
							value = val
						})
					end
					table.insert(stack, node.childNodes)
				end
					
			end
		end
	end
	if level~=0 then
		vlc.msg.dbg("Parse error: "..level)
	end
	collectgarbage()	
	return tree
end

function dump_html(data)
	local stack = {data}
	local d = ""
	local node = nil
	
	while #stack ~= 0 do
		node = nil
		node = stack[#stack][1]
		
		if not node then break end
		
		if node.tagName == "textNode" then
			d = d..trim(node.value)
		else
			d = d.."\n"..string.rep (" ", #stack-1)
			d = d.."<"..node.tagName
				
			if node.attr then
				for a, v in pairs(node.attr) do
					d = d.." "..a..'="'..v..'"'
				end
			end
			
			if empty_tags[node.tagName] then
				d = d.."/>"
			else
				d = d..">"
			end
		end
		
		if node.childNodes and #node.childNodes > 0 then
			node.l = #node.childNodes
			table.insert(stack, node.childNodes)
		else
			table.remove(stack[#stack], 1)
			if node.childNodes and #node.childNodes == 0 and not empty_tags[node.tagName] then
				d = d.."</"..node.tagName..">"
			end
			while #stack > 0 and #stack[#stack] == 0 do
				table.remove(stack)
				if #stack > 0 then
					if stack[#stack][1].l > 1 then
						d = d.."\n"..string.rep(" ", #stack-1).."</"..stack[#stack][1].tagName..">"
					else
						d = d.."</"..stack[#stack][1].tagName..">"
					end
					table.remove(stack[#stack], 1)
				end
			end
		end
	end
	return d
end


-----
--  This part is from G.Dufrene, not from the original author.
-----

function deep_search(html, tagName, cb)
	for k, v in ipairs(html) do
		if v.tagName:upper() == tagName:upper() then 
			if cb(v) then return v end
		end
		if v.childNodes ~= nil then 
			local res = deep_search(v.childNodes, tagName, cb) 
			if res ~= nil then return res end
		end
	end
	return nil
end

function html_search(html, tagName)
	local ret = nil
	deep_search(html, tagName, function(v) 
		ret = v
		return true
	end)
	return ret
end

function html_all(html, tagName)
	local arr = {}
	local i = 1
	deep_search(html, tagName, function(v)
		arr[i] = v
		i = i + 1
	end)
	return arr
end

