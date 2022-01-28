local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

local function defaults(defaultObj, newObj, seen)
  if not newObj then return defaultObj
  elseif type(newObj) ~= 'table' then return newObj end
  if seen and seen[newObj] then return seen[newObj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(newObj))
  s[newObj] = res
  for k, v in pairs(newObj) do res[copy(k, s)] = copy(v, s) end
  return res
end

local function increaseRGB(rgb)
  local r = rgb[1]
  local g = rgb[2]
  local b = rgb[3]
  local a = rgb[4]

  if r == 1 and g == 0 and b < 1 then
    b = b + 0.25
  elseif r > 0 and g == 0 and b == 1 then
    r = r - 0.25
  elseif r == 0 and g < 1 and b == 1 then
    g = g + 0.25
  elseif r == 0 and g == 1 and b > 0 then
    b = b - 0.25
  elseif r < 1 and g == 1 and b == 0 then
    r = r + 0.25
  elseif r == 1 and g > 0 and b == 0 then
    g = g - 0.25
  end

  return { r, g, b, a }
end

return {
  copy = copy,
  defaults = defaults,
  increaseRGB = increaseRGB,
}