--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety)
    
    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety
    self.shine = false

    if math.random(1,100) == 5 then
        self.shine = true
    end


    self.particles = love.graphics.newParticleSystem(gTextures['particle'],32)
    self.particles:setParticleLifetime(1,5)
    self.particles:setAreaSpread('normal',6,6)

    self.particles:setColors(251,242,54,100,251,242,54,0)

    if self.shine then
        Timer.every(0.1,function()
            self.particles:emit(32)
        end)
    end

end

function Tile:update(dt)
    self.particles:update(dt)
end

function Tile:render(x, y)
    
    -- draw shadow
    love.graphics.setColor(34, 32, 52, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    if self.shine then
        love.graphics.draw(self.particles,self.x+x+16,self.y+y+16)
    end
end