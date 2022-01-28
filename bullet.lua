require("object")
cron = require("cron")

Bullet = Object.create()

local lg = love.graphics

local BULLET_RADIUS = 5
local IMPULSE = 5500
local BULLET_DAMAGE = 10
local BULLET_LIVE_DURATION = 3

local FILTER_MASK = bit.bor(CATEGORY_ENEMY, CATEGORY_SCENE)

function Bullet.create(x, y, directionRad)
  local self = setmetatable({}, { __index = Bullet })
  self.x = x
  self.y = y
  self.radius = BULLET_RADIUS
  self.directionRad = directionRad
  self.damage = BULLET_DAMAGE
  self.collider = bf.Collider.new(stage.world, "circle", self.x, self.y, self.radius)
  self.collider:setType("dynamic")
  self.collider:setBullet(true)
  self.collider:setFilterData(CATEGORY_BULLET, FILTER_MASK, 0)
  self.collider.shell = self

  self.collider:applyLinearImpulse(IMPULSE * math.cos(self.directionRad), -IMPULSE * math.sin(self.directionRad))
  self.timer = cron.after(BULLET_LIVE_DURATION, function()
    self:destroy()
  end)

  function self.collider.preSolve(_, object)
    if not (object == stage.scene) then
      if object.shell and object.shell.getsDamage then
        object.shell:getDamage(self.damage)
        if self.timer then
          self.timer:reset()
        end
        self:destroy()
      end
    end
  end

  return self
end

function Bullet:update(dt)
  self.x = self.collider:getX()
  self.y = self.collider:getY()

  if self.timer then self.timer:update(dt) end
  -- TODO: Self deletion
end

function Bullet:draw()
  lg.setColor(1, 1, 1)
  lg.circle("fill", self.x, self.y, self.radius)
end
