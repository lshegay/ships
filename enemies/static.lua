bf = require("breezefield")
require("object")
require("bullet")
cron = require("cron")

StaticEnemy = Object.create()

local lg = love.graphics

local WIDTH = 50
local HEIGHT = 50
local DAMAGE = 5
local EXPLODE_DAMAGE = 20
local EXPLODE_HEIGHT = 50
local EXPLODE_TIME = 1

local FILTER_MASK = bit.bor(CATEGORY_PLAYER, CATEGORY_SCENE, CATEGORY_ENEMY, CATEGORY_BULLET)
local FILTER_MASK_EXPLOSION = CATEGORY_PLAYER

function StaticEnemy.create(x, y, sceneRadius, explodeTime, isVertical)
  local self = setmetatable({}, { __index = StaticEnemy })
  self.x = x
  self.y = y
  self.width = WIDTH
  self.height = HEIGHT
  self.getsDamage = false

  if not isVertical then
    self.explosionWidth = sceneRadius * 2
    self.explosionHeight = EXPLODE_HEIGHT
  else
    self.explosionWidth = EXPLODE_HEIGHT
    self.explosionHeight = sceneRadius * 2
  end
  self.isExpanding = true
  self.isExploded = false
  self.explodingTimer = nil

  self.collider = bf.Collider.new(
    stage.world, "Rectangle",
    self.x, self.y,
    self.width, self.height
  )
  self.collider:setType("static")
  self.collider:setFilterData(CATEGORY_ENEMY, FILTER_MASK, 0)
  self.collider.shell = self

  self.explodeCollider = bf.Collider.new(
    stage.world, "Rectangle",
    self.x, self.y,
    self.explosionWidth, self.explosionHeight
  )
  self.explodeCollider:setSensor(true)
  self.explodeCollider:setFilterData(CATEGORY_ENEMY, FILTER_MASK_EXPLOSION, 0)
  self.playerInsideTheExplode = false

  function self.collider.postSolve(_, object)
    if object.shell == player then
      player:getDamage(DAMAGE)
      local nx, ny = player.x - self.x, player.y - self.y
      player.collider:applyLinearImpulse(nx * 10, ny * 10)
    end
  end

  function self.explodeCollider.enter(_, object)
    if object.shell == player then
      self.playerInsideTheExplode = true
    end
  end

  function self.explodeCollider.exit(_, object)
    if object.shell == player then
      self.playerInsideTheExplode = false
    end
  end

  self.explodingTimer = cron.after(explodeTime or EXPLODE_TIME, function()
    self:destroy()
  end)

  return self
end

function StaticEnemy:getDamage()
  -- nothing happens
end

function StaticEnemy:destroy()
  self.isExpanding = false
  self.isExploded = true

  self.explodingTimer = cron.after(0.1, function()
    if player and player.collider and not player.collider:isDestroyed() and self.playerInsideTheExplode then
      player:getDamage(EXPLODE_DAMAGE)
      local nx, ny = player.x - self.x, player.y - self.y
      player.collider:applyLinearImpulse(nx * 100, ny * 100)
    end

    if self.explodeCollider then
      self.explodeCollider:destroy()
    end
    Object.destroy(self)
  end)
end

function StaticEnemy:update(dt)
  self.x, self.y = self.collider:getPosition()
  self.radius = self.collider:getRadius()
  self.explodeCollider:setPosition(self.x, self.y)

  if self.explodingTimer then self.explodingTimer:update(dt) end
end

function StaticEnemy:draw()
  lg.setColor(0, 1, 1,1)
  lg.rectangle("fill",
    self.x - self.width / 2, self.y - self.height / 2,
    self.width, self.height
  )

  -- draw exploding thing
  local eX, eY = self.explodeCollider:getPosition()
  if self.isExploded then
    lg.setColor(1, 1, 0, 1)
    lg.rectangle("fill",
      eX - self.explosionWidth / 2, eY - self.explosionHeight / 2,
      self.explosionWidth, self.explosionHeight
    )
  else
    lg.setColor(0, 1, 1, 0.4)
    lg.rectangle("line",
      eX - self.explosionWidth / 2, eY - self.explosionHeight / 2,
      self.explosionWidth, self.explosionHeight
    )
  end
end
