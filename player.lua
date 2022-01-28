bf = require("breezefield")
require("object")
require("bullet")
helpers = require("helpers")
cron = require("cron")

Player = Object.create()

local lg = love.graphics

local MAX_VELOCITY = 500
local ACCELERATION = 2500
local DAMPING = 2
local MASS = 1
local MAX_HEALTH = 200
local RADIUS = 25
local FIRE_DELAY = 0.2

local FILTER_MASK = 0xFFFF

function Player.create(x, y)
  local self = setmetatable({}, { __index = Player })
  self.x = x
  self.y = y
  self.radius = RADIUS
  self.health = MAX_HEALTH
  self.collider = bf.Collider.new(stage.world, "circle", self.x, self.y, self.radius)
  self.collider:setType("dynamic")
  self.collider:setMass(MASS)
  self.collider:setFixedRotation(true)
  self.collider:setFilterData(CATEGORY_PLAYER, FILTER_MASK, 0)
  self.collider:setLinearDamping(DAMPING)
  self.collider.shell = self
  self.weapon = {
    x = 0,
    y = 0,
    position = {},
    startY = 0,
    distance = 10,
    fired = false,
    fireTimer = nil,
    angleRad = 0,
  }

  -- BEGIN: particles part
  local canv = lg.newCanvas(RADIUS, RADIUS)
  lg.setCanvas(canv)
      lg.clear()
      lg.setColor(1, 1, 1)
      lg.polygon('fill', RADIUS, RADIUS, 0, RADIUS / 2, RADIUS, 0)
  lg.setCanvas()

  self.particles = lg.newParticleSystem(canv, 100)
  self.particles:setParticleLifetime(1)
  self.particles:setEmissionRate(30)
  self.particles:setSpread(50)
  self.particles:setRelativeRotation(true)
  -- END: particles part

  return self
end

function Player:getDamage(damage)
  Object.getDamage(self, damage)

  camera:shake(8, 0.5, 50)
end

function Player:updateMovement(dt)
  local velX, velY = self.collider:getLinearVelocity()

  if love.keyboard.isDown("a") and velX > -MAX_VELOCITY then
    velX = velX - ACCELERATION * dt
  end
  if love.keyboard.isDown("d") and velX < MAX_VELOCITY then
    velX = velX + ACCELERATION * dt
  end
  if love.keyboard.isDown("w") and velY > -MAX_VELOCITY then
    velY = velY - ACCELERATION * dt
  end
  if love.keyboard.isDown("s") and velY < MAX_VELOCITY then
    velY = velY + ACCELERATION * dt
  end

  self.collider:setLinearVelocity(velX, velY)
end

function Player:updateWeapon(dt)
  local mouseX, mouseY = love.mouse.getPosition()

  if camera then
    mouseX, mouseY = camera:toWorldCoords(mouseX, mouseY)
  end

  local atan = math.atan2(self.y - mouseY, mouseX - self.x)
  local R = self.radius + self.weapon.distance

  local x = math.cos(atan) * (R + 5)
  local y = math.sin(atan) * (R + 5)

  self.weapon.x = self.x + x
  self.weapon.y = self.y - y

  self.weapon.angleRad = atan
  self.weapon.position = {
    self.weapon.x,
    self.weapon.y,
    self.x + math.cos(atan - math.rad(5)) * R,
    self.y - math.sin(atan - math.rad(5)) * R,
    self.x + math.cos(atan + math.rad(5)) * R,
    self.y - math.sin(atan + math.rad(5)) * R,
  }
end

function Player:updateBullets(dt)
  if not self.fired and love.keyboard.isDown('space') then
    self.fired = true
    local bullet = Bullet.create(self.weapon.x, self.weapon.y, self.weapon.angleRad)
    self.weapon.fireTimer = cron.after(FIRE_DELAY, function()
      self.fired = false
    end)
    stage:addChild(bullet)
  end

  if self.weapon.fireTimer then
    self.weapon.fireTimer:update(dt)
  end
end

function Player:updateParticles(dt)
  self.particles:update(dt)

  if love.keyboard.isDown("a")
    or love.keyboard.isDown("d")
    or love.keyboard.isDown("w")
    or love.keyboard.isDown("s") then
      self.particles:start()

      self.particles:setColors({1, 0.5, 0, 0.4}, {1, 0, 0, 0})
    elseif not self.particles:isPaused() then
    self.particles:pause()
  end

  local velX, velY = self.collider:getLinearVelocity()
  local randX = math.random(-1000, 1000)
  local randY = math.random(-1000, 1000)
  self.particles:setLinearAcceleration(-velX + randX, -velY + randY)
  self.particles:setPosition(self.x, self.y)
end

function Player:update(dt)
  self.x = self.collider:getX()
  self.y = self.collider:getY()
  self.radius = self.collider:getRadius()

  self:updateMovement(dt)
  self:updateWeapon(dt)
  self:updateBullets(dt)
  self:updateParticles(dt)
end

function Player:draw()
  lg.setColor(1, 1, 1)

  -- draw weapon
  lg.polygon("line", self.weapon.position)

  -- draw tail (particles)
  lg.draw(self.particles, 0, 0)

  -- draw player
  lg.setColor(1, 0.5, 0.9, 0.1)
  lg.circle("fill", self.x, self.y, self.radius + 50)

  lg.setColor(1, 1, 1)
  lg.circle("fill", self.x, self.y, self.radius)
end
