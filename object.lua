Object = {}

function Object.create()
  local self = setmetatable({}, { __index = Object })
  self.x = 0
  self.y = 0
  self.width = 0
  self.height = 0
  self.radius = 0
  self.collider = nil
  self.health = 0
  self.getsDamage = true

  return self
end

function Object:getDamage(damage)
  if self.getsDamage then
    self.health = self.health - damage
  end
end

function Object:destroy()
  if stage.children[self] then
    if (self.collider) then
      self.collider:destroy()
    end

    stage.children[self] = nil
  end
end

function Object:update(dt)
  
end

function Object:draw()

end
