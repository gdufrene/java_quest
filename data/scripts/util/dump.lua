function dump(o, d)
  if type(o) ~= 'table' then
    return tostring(o)
  end
  if d == nil then d = 0 end

 local s = '{ '
 local first = true
 for k,v in pairs(o) do
    if type(k) ~= 'number' then k = tostring(k) end
    if first == false then s = s .. ", " end
    first = false
    s = s .. string.rep("  ", d*2) .. k .. ' => ' .. dump(v) .. "\n"
 end
 return s .. '} '

end
