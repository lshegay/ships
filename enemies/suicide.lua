bf = require("breezefield")
require("object")
require("bullet")
cron = require("cron")

SuicideEnemy = Object.create()

local lg = love.graphics

local MAX_VELOCITY = 500
local ACCELERATION = 1000
local MAX_HEALTH = 20
local RADIUS = 20
local DAMPING = 2

local DAMAGE = 5
local EXPLODE_DAMAGE = 20
local EXPLODE_TIME = 1
local EXPLODE_RADIUS = 100

local FILTER_MASK = bit.bor(CATEGORY_PLAYER, CATEGORY_SCENE, CATEGORY_ENEMY, CATEGORY_BULLET)
local FILTER_MASK_EXPLOSION = CATEGORY_PLAYER

function SuicideEnemy.create(x, y)
  local self = setmetatable({}, { __index = SuicideEnemy })
  self.x = x
  self.y = y
  self.radius = RADIUS
  self.health = MAX_HEALTH
  self.healthTimer = nil
  self.healthVisible = false

  self.isExpanding = false
  self.isExploded = false
  self.explodingRadius = 0
  self.explodingTimer = nil

  self.collider = bf.Collider.new(stage.world, "Circle", self.x, self.y, self.radius)
  self.collider:setType("dynamic")
  self.collider:setLinearDamping(DAMPING)
  self.collider:setFilterData(CATEGORY_ENEMY, FILTER_MASK, 0)
  self.collider.shell = self

  self.explodeCollider = bf.Collider.new(stage.world, "Circle", self.x, self.y, EXPLODE_RADIUS)
  self.explodeCollider:setFilterData(CATEGORY_ENEMY, FILTER_MASK_EXPLOSION, 0)
  self.explodeCollider:setSensor(true)
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
      if not self.isExpanding and not self.isExploded then
        self.isExpanding = true
        self.explodingTimer = cron.after(EXPLODE_TIME, function()
          self:destroy()
        end)
      end
    end
  end

  function self.explodeCollider.exit(_, object)
    if object.shell == player then
      self.playerInsideTheExplode = false
    end
  end

  return self
end

function SuicideEnemy:getDamage(damage)
  -- BEGIN: enemy healthbar
  self.healthVisible = true
  if self.healthTimer then
    self.healthTimer:reset()
  end
  self.healthTimer = cron.after(2, function ()
    self.healthVisible = false
    self.healthTimer = nil
  end)
  -- END: enemy healthbar

  Object.getDamage(self, damage)
end

function SuicideEnemy:followTo(dt)
  if player then
    if not self.isExploded then
      local x, y = player.x, player.y
      local velX, velY = self.collider:getLinearVelocity()

      if x < self.x and velX > -MAX_VELOCITY then
        velX = velX - ACCELERATION * dt
      end
      if x > self.x and velX < MAX_VELOCITY then
        velX = velX + ACCELERATION * dt
      end
      if y < self.y and velY > -MAX_VELOCITY then
        velY = velY - ACCELERATION * dt
      end
      if y > self.y and velY < MAX_VELOCITY then
        velY = velY + ACCELERATION * dt
      end

      self.collider:setLinearVelocity(velX, velY)
      self.collider:setAngle(math.atan2(velY, velX))
    end
  end
end

function SuicideEnemy:destroy()
  self.isExpanding = false
  self.isExploded = true
  self.explodingRadius = EXPLODE_RADIUS

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

function SuicideEnemy:expandToExplode(dt)
  if self.isExpanding then
    self.explodingRadius = self.explodingRadius + EXPLODE_RADIUS / EXPLODE_TIME * dt
  end
end

function SuicideEnemy:update(dt)
  self.x, self.y = self.collider:getPosition()
  self.radius = self.collider:getRadius()
  self.explodeCollider:setPosition(self.x, self.y)

  if self.healthTimer then self.healthTimer:update(dt) end
  if self.explodingTimer then self.explodingTimer:update(dt) end

  self:followTo(dt)
  self:expandToExplode(dt)

  if self.health <= 0 and not self.isExpanding and not self.isExploded then
    self:destroy()
  end
end

function SuicideEnemy:draw()
  lg.setColor(1, 1, 1, 1)
  local angle = self.collider:getAngle()
  lg.push()
  lg.translate(self.x, self.y)
  lg.rotate(angle)
  lg.polygon("line", {
    self.radius, 0,
    -self.radius, -self.radius,
    -self.radius, self.radius,
  })
  lg.pop()

  lg.setColor(0, 0, 1, 0.4)
  lg.circle("line", self.x, self.y, EXPLODE_RADIUS)

  -- draw exploding thing
  lg.setColor(1, 1, 1, 0.4)
  if self.isExploded then
    lg.setColor(0, 1, 1, 0.4)
  end
  lg.circle("fill", self.x, self.y, self.explodingRadius)

  -- draw healthbar
  lg.setColor(1, 1, 1, 1)
  if self.health < MAX_HEALTH then
    if not self.healthVisible then
      lg.setColor(1, 1, 1, 0.2)
    end
    lg.rectangle("line", self.x + self.radius + 10, self.y + self.radius + 2, 30, 10)

    local currentHealth = self.health * 30 / MAX_HEALTH
    lg.rectangle("fill", self.x + self.radius + 10, self.y + self.radius + 2, currentHealth, 10)
  end
end
