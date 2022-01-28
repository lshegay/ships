bf = require("breezefield")
require("object")
require("bullet")
cron = require("cron")

NinjaEnemy = Object.create()

local lg = love.graphics

local MAX_VELOCITY = 500
local ACCELERATION = 1000
local MAX_HEALTH = 40
local RADIUS = 40
local WEAPON_WIDTH = 200
local WEAPON_HEIGHT = 10
local DAMPING = 2

local DAMAGE = 5
local WEAPON_DAMAGE = 15

local FILTER_MASK = bit.bor(CATEGORY_PLAYER, CATEGORY_SCENE, CATEGORY_ENEMY, CATEGORY_BULLET)

function NinjaEnemy.create(x, y)
  local self = setmetatable({}, { __index = NinjaEnemy })
  self.x = x
  self.y = y
  self.radius = RADIUS
  self.health = MAX_HEALTH
  self.healthTimer = nil
  self.healthVisible = false
  self.angle = 0
  self.collider = bf.Collider.new(stage.world, "Circle", self.x, self.y, self.radius)
  self.collider:setType("dynamic")
  self.collider:setLinearDamping(DAMPING)
  self.collider:setFilterData(CATEGORY_ENEMY, FILTER_MASK, 0)
  self.collider.shell = self

  self.weaponWidth = WEAPON_WIDTH
  self.weaponHeight = WEAPON_HEIGHT
  self.weapon = bf.Collider.new(stage.world, "Rectangle", self.x, self.y, self.weaponWidth, self.weaponHeight)
  self.weapon:setType("dynamic")
  self.weapon:setFilterData(CATEGORY_ENEMY, FILTER_MASK, 0)

  love.physics.newWeldJoint(self.collider.body, self.weapon.body, self.x, self.y)

  function self.collider.postSolve(_, object)
    if object.shell == player then
      player:getDamage(DAMAGE)
      local nx, ny = player.x - self.x, player.y - self.y
      player.collider:applyLinearImpulse(nx * 10, ny * 10)
    end
  end

  function self.weapon.postSolve(_, object)
    if object.shell == player then
      player:getDamage(WEAPON_DAMAGE)
      local nx, ny = player.x - self.x, player.y - self.y
      player.collider:applyLinearImpulse(nx * 100, ny * 100)
    end
  end

  return self
end

function NinjaEnemy:getDamage(damage)
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

function NinjaEnemy:destroy()
  self.weapon:destroy()
  self.weapon:release()
  Object.destroy(self)
end

function NinjaEnemy:followTo(dt)
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
    end
  end
end


function NinjaEnemy:update(dt)
  self.x, self.y = self.collider:getPosition()
  self.radius = self.collider:getRadius()
  self.angle = self.weapon:getAngle()
  self.collider:setAngle(self.angle + 70 * dt)

  if self.healthTimer then self.healthTimer:update(dt) end

  self:followTo(dt)

  if self.health <= 0 then
    self:destroy()
  end
end

function NinjaEnemy:draw()
  lg.setColor(1, 1, 1, 1)
  lg.circle("line", self.x, self.y, self.radius)

  lg.push()
    lg.translate(self.x, self.y)
    lg.rotate(self.angle)
    lg.rectangle("line", -self.weaponWidth / 2, -self.weaponHeight / 2, self.weaponWidth, self.weaponHeight)
  lg.pop()

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
