--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    
    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    self.powerup = Powerup(1)
    self.powerup.x = 225
    self.powerup.y = 0
    self.powerup.dy = 20

    self.ball1 = Ball(math.random(7))
    self.ball2 = Ball(math.random(7))


    self.ball1.x = self.paddle.x
    self.ball1.y = self.paddle.y - 8
        
    self.ball2.x = self.paddle.x + (self.paddle.width / 2)
    self.ball2.y = self.paddle.y - 8

    
    self.ball1.dx = math.random(-200, 200)
    self.ball1.dy = math.random(-50, -60)

    self.ball2.dx = math.random(-200, 200)
    self.ball2.dy = math.random(-50, -60)

    balls = {self.ball,self.ball1,self.ball2 }

    self.time1 = love.timer.getTime()
    self.canDraw = false
    self.powers = false
    counter = 1
end



function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    
    -- update positions based on velocity
    self.paddle:update(dt)
    self.powerup:update(dt)

    for i =0,2 do
        if balls[counter].current == true then
            balls[counter]:update(dt)

            if balls[counter]:collides(self.paddle) then
                -- raise ball above paddle in case it goes below it, then reverse dy
                balls[counter].y = self.paddle.y - 8
                balls[counter].dy = -balls[counter].dy
        
        
                --
                -- tweak angle of bounce based on where it hits the paddle
                --
        
                -- if we hit the paddle on its left side while moving left...
                if balls[counter].x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                    balls[counter].dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - balls[counter].x))
                
                -- else if we hit the paddle on its right side while moving right...
                elseif balls[counter].x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                    balls[counter].dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - balls[counter].x))
                end
        
                gSounds['paddle-hit']:play()
            end

                    -- detect collision across all bricks with the ball
            for k, brick in pairs(self.bricks) do

                -- only check collision if we're in play
                if brick.inPlay and balls[counter]:collides(brick) then
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                    brick:hit()
                    
                    if self.score > self.recoverPoints then
                        self.health = math.min(3, self.health + 1)
                        self.recoverPoints = math.min(100000, self.recoverPoints * 2)
                        gSounds['recover']:play()
                    end
                    
                    if self:checkVictory() then
                        gSounds['victory']:play()
                        
                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            ball = self.ball,
                            recoverPoints = self.recoverPoints
                        })
                    end

                    --
                    -- collision code for bricks
                    --
                    -- we check to see if the opposite side of our velocity is outside of the brick;
                    -- if it is, we trigger a collision on that side. else we're within the X + width of
                    -- the brick and should check to see if the top or bottom edge is outside of the brick,
                    -- colliding on the top or bottom accordingly 
                    --

                    -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    if balls[counter].x + 2 < brick.x and balls[counter].dx > 0 then
                
                        -- flip x velocity and reset position outside of brick
                        balls[counter].dx = -balls[counter].dx
                        balls[counter].x = brick.x - 8
            
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    elseif balls[counter].x + 6 > brick.x + brick.width and balls[counter].dx < 0 then
                
                    -- flip x velocity and reset position outside of brick
                        balls[counter].dx = -balls[counter].dx
                        balls[counter].x = brick.x + 32
            
                    -- top edge if no X collisions, always check
                    elseif balls[counter].y < brick.y then
                
                    -- flip y velocity and reset position outside of brick
                        balls[counter].dy = -balls[counter].dy
                        balls[counter].y = brick.y - 8
            
                    -- bottom edge if no X collisions or top collision, last possibility
                    else
                
                    -- flip y velocity and reset position outside of brick
                        balls[counter].dy = -balls[counter].dy
                        balls[counter].y = brick.y + 16
                    end

                    -- slightly scale the y velocity to speed up the game, capping at +- 150
                    if math.abs(balls[counter].dy) < 150 then
                        balls[counter].dy = balls[counter].dy * 1.02
                    end

                    -- only allow colliding with one brick, for corners
                    break
                end
            end

                    -- if ball goes below bounds, revert to serve state and decrease health
            if balls[counter].y >= VIRTUAL_HEIGHT then
                self.health = self.health - 1
                gSounds['hurt']:play()
                
                self.ball1.current = false
                self.ball2.current = false
                self.powers = false

                if self.health == 0 then
                    gStateMachine:change('game-over', {score = self.score,highScores = self.highScores})
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end

            -- for rendering particle systems
            for k, brick in pairs(self.bricks) do
                brick:update(dt)
            end

            if love.keyboard.wasPressed('escape') then
                love.event.quit()
            end
        end
        counter = counter + 1
    end
    counter = 1
end




function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()

    if love.timer.getTime()-self.time1 > 2 then
        self.canDraw = true
    end

    if self.canDraw == true then
        self.powerup:render()
    end

    if self.powerup:collides(self.paddle) then
        self.powers = true
        self.ball1.current = true
        self.ball2.current = true
        self.canDraw = false
    end

    if self.powers then
        self.ball1:render()
        self.ball2:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end