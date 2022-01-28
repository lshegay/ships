require("enemies.suicide")
require("enemies.static")
require("enemies.ninja")

local function circularPattern(SCENE_RADIUS)
  local pattern = {
    enemies = {},
    duration = 5,
  }
  for i = 0, 7 do
    local pointX = (SCENE_RADIUS - 40) * math.cos(math.rad(i * 45))
    local pointY = (SCENE_RADIUS - 40) * math.sin(math.rad(i * 45))
    table.insert(pattern.enemies, {
      obj = SuicideEnemy,
      args = { pointX, pointY }
    })
  end

  return pattern
end

local function circularPatternMomentally(SCENE_RADIUS)
  local pattern = circularPattern(SCENE_RADIUS)
  pattern.duration = 1

  return pattern
end

local function staticHell(SCENE_RADIUS)
  local pattern = {
    enemies = {},
    duration = 2,
  }
  for i = 1, 5 do
    local pointX = math.random(SCENE_RADIUS - 40) * math.cos(math.rad(math.random(0, 359)))
    local pointY = math.random(SCENE_RADIUS - 40) * math.sin(math.rad(math.random(0, 359)))
    table.insert(pattern.enemies, {
      obj = StaticEnemy,
      args = { pointX, pointY, SCENE_RADIUS, 1 + i * 0.1, i % 2 == 0 }
    })
  end

  return pattern
end

local function staticHellButMomentally(SCENE_RADIUS)
  local pattern = staticHell(SCENE_RADIUS)
  pattern.duration = 0.1
  return pattern
end

local function ninjas(SCENE_RADIUS)
  local pattern = {
    enemies = {},
    duration = 4,
  }
  for i = 1, 3 do
    local pointX = (SCENE_RADIUS - 400) * math.cos(math.rad(math.random(0, 359)))
    local pointY = (SCENE_RADIUS - 400) * math.sin(math.rad(math.random(0, 359)))
    table.insert(pattern.enemies, {
      obj = NinjaEnemy,
      args = { pointX, pointY }
    })
  end

  return pattern
end

return {
  circularPattern,
  circularPatternMomentally,
  staticHell,
  staticHellButMomentally,
  ninjas,
}