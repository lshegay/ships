bf = require("breezefield")
cron = require("cron")

CATEGORY_PLAYER   = 0x0001
CATEGORY_BULLET   = 0x0002
CATEGORY_ENEMY    = 0x0004
CATEGORY_SCENE    = 0x0008

patterns = require("patterns")

Stage = {}

local lg = love.graphics
local MAX_HEALTH = 200

function Stage.create()
  local self = setmetatable({}, { __index = Stage })
  self.children = {}
  self.screenWidth = love.graphics.getWidth()
  self.screenHeight = love.graphics.getHeight()
  self.world = bf.newWorld(0, 0)
  self.generationTimer = nil
  self.gameOver = false

  -- BEGIN: create circular repeated background
  local sceneVertices = {}
  for i = 0, 49 do
    local pointX = SCENE_RADIUS * math.cos(math.rad(i * 15))
    local pointY = SCENE_RADIUS * math.sin(math.rad(i * 15))
    table.insert(sceneVertices, pointX)
    table.insert(sceneVertices, pointY)
  end

  self.scene = bf.Collider.new(self.world, "Chain", true, sceneVertices)
  self.scene:setFilterData(CATEGORY_SCENE, 0xFFFF, 0)
  self.scene:setType("static")
  self.scene:setRestitution(0.4)
  self.scene:setFriction(0)

  self.sceneBackgroundImage = lg.newImage("assets/background.png")
  self.sceneBackgroundImage:setWrap("repeat", "repeat")
  self.sceneQuad = lg.newQuad(0, 0, SCENE_RADIUS * 2, SCENE_RADIUS * 2, self.sceneBackgroundImage)
  -- END: create circular repeated background

  self.timeLeft = 0

  return self
end

function Stage:generateNewEnemies()
  local function generate()
    local indexPattern = math.random(#patterns)
    local pattern = patterns[indexPattern](SCENE_RADIUS)
    
    for i = 1, #pattern.enemies do
      local situation = pattern.enemies[i]
      local enemy = situation.obj.create(unpack(situation.args))
      
      self:addChild(enemy)
    end

    self.timeLeft = pattern.duration
    self.generationTimer = cron.after(pattern.duration, generate)
  end

  generate()
end

function Stage:addChild(child)
  if (child ~= nil) then
    if (child.update ~= nil and child.draw ~= nil) then
      self.children[child] = true
    end
  end
end

function Stage:gameMechanics()
  if not self.gameOver and player.health <= 0 then
    self.gameOver = true
    player:destroy()
    self.generationTimer:reset()
  end

  if self.gameOver and love.keyboard.isDown("r") then
    self.gameOver = false

    for object, _ in pairs(stage.children) do
      if stage.children[object] and object then
        object:destroy()
      end
    end
    
    self:generateNewEnemies()
    player = Player.create(0, 0)
    stage:addChild(player)
  end
end

function Stage:update(dt)
  self.world:update(dt)

  if self.generationTimer then
    self.generationTimer:update(dt)
    self.timeLeft = self.timeLeft - dt
  end

  self:gameMechanics()

  for object, _ in pairs(self.children) do
    if (object) then
      object:update(dt)
    end
  end
end

function Stage:drawScene()
  local function sceneStencil()
    lg.circle("fill", 0, 0, SCENE_RADIUS)
  end

  lg.setColor(1, 1, 1, 0.3)
  lg.circle("line", 0, 0, SCENE_RADIUS)
  lg.setColor(1, 1, 1, 1)
  lg.stencil(sceneStencil)
  lg.setStencilTest("greater", 0)
  lg.push()
    lg.rotate(15)
    lg.draw(self.sceneBackgroundImage, self.sceneQuad, -SCENE_RADIUS, -SCENE_RADIUS)
  lg.pop()
  lg.setStencilTest()
end

function Stage:drawGUI()
  lg.setColor(1, 1, 1)
  lg.setNewFont()
  lg.print("New wave after: " ..  math.floor(self.timeLeft + 1), camera:toWorldCoords(self.screenWidth - 120, 20))
  
  -- draw healthbar GUI
  local posX, posY = camera:toWorldCoords(30, 30)
  lg.rectangle("line", posX, posY, 200, 20)
  local currentHealth = player.health * 200 / MAX_HEALTH
  lg.rectangle("fill", posX, posY, math.max(currentHealth, 0), 20)

  if self.gameOver then
    lg.setNewFont(50)
    local pX, pY = camera:toWorldCoords(self.screenWidth / 2 - 400, self.screenHeight / 2 - 50)
    lg.printf("Game Is Over.\nPress R to restart", pX, pY, 1000, "center")
  end
end

function Stage:draw()
  self:drawScene()
  self:drawGUI()
  --self.world:draw()

  for object, _ in pairs(self.children) do
    if object then
      object:draw()
    end
  end
end
