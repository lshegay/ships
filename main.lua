--require("lovedebug")
local Camera = require("camera")
require("stage")
require("player")

SCENE_RADIUS = 1000

function love.load()
  camera = Camera.new()
  --camera.draw_deadzone = true
  camera:setFollowLead(5)
  camera:setFollowLerp(0.1)
  camera.scale = 0.8
  camera:setFollowStyle('TOPDOWN_TIGHT')

  stage = Stage.create()
  player = Player.create(0, 0)
  stage:addChild(player)

  -- local enemy = NinjaEnemy.create(100, 100)
  -- stage:addChild(enemy)

  stage:generateNewEnemies()
end

function love.update(dt)
  camera:update(dt)
  local mouseX, mouseY = love.mouse.getPosition()
  camera:follow((player.x + (mouseX - stage.screenWidth / 2)), (player.y + (mouseY - stage.screenHeight / 2)))

  stage:update(dt)
end

function love.draw()
  camera:attach()
  stage:draw()
  camera:detach()
  camera:draw()
end
