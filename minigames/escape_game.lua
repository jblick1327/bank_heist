-- escape_game.lua
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/easing"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local EscapeGame = {}

function EscapeGame.new()
    local self = {}
    setmetatable(self, { __index = EscapeGame })

    -- -------------------------------------------------------------------------
    -- IMAGES (Using self. so they don't disappear)
    -- -------------------------------------------------------------------------
    self.bg = {
        gfx.image.new("images/escape_game/road_game_f1"),
        gfx.image.new("images/escape_game/road_game_f2"),
        gfx.image.new("images/escape_game/road_game_f3"),
        gfx.image.new("images/escape_game/road_game_f4")
    }

    self.player = gfx.image.new("images/escape_game/road_game_player")
    self.car = gfx.image.new("images/escape_game/road_game_car")

    -- -------------------------------------------------------------------------
    -- GAME STATE
    -- -------------------------------------------------------------------------
    self.gameStart = 1
    self.framesBeforeGameStart = 40
    self.imageCounter = 1
    self.frameCounter = 1
    self.carWiggle = 1

    self.pX = 10
    self.pY = 75

    self.speed = 10
    self.cars = {}

    self.timerLength = 10
    self.startTime = pd.getCurrentTimeMilliseconds()

    self.gameOver = false
    self.fail = false
    self.score = 0
    self.timeScore = 0
    self.waitCounter = 0

    self:spawnCars()

    return self
end

function EscapeGame:timerLimit()
    local currentTime = pd.getCurrentTimeMilliseconds()
    local elapsedTime = (currentTime - self.startTime) / 1000

    local timeLeft = math.ceil(self.timerLength - elapsedTime)

    if timeLeft < 0 then
        timeLeft = 0
    end

    self.timeScore = timeLeft

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Time Left: " .. timeLeft, 280, 10)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    if timeLeft <= 0 then
        self.fail = false
        self.gameOver = true
    end
end

function EscapeGame:spawnCars()
    local tempLanes = {180, 100, 20}

    local lane1 = table.remove(tempLanes, math.random(#tempLanes))
    local lane2 = table.remove(tempLanes, math.random(#tempLanes))

    self.cars = {
        {x = 400, y = lane1},
        {x = 400, y = lane2}
    }
end

function EscapeGame:checkCollision(carObj)
    local playerW, playerH = self.player:getSize()
    local carW, carH = self.car:getSize()

    if self.pX < carObj.x + carW and
       self.pX + (playerW - 175) > carObj.x and
       self.pY < carObj.y + (carH - 20) and
       self.pY + (playerH - 40) > carObj.y then

        self.fail = true
        self.gameOver = true
    end
end

function EscapeGame:traffic(carObj)
    self.car:draw(carObj.x, carObj.y)
    carObj.x -= self.speed
    self:checkCollision(carObj)
end

function EscapeGame:trafficTimer()
    local allGone = true

    for i = 1, #self.cars do
        self:traffic(self.cars[i])

        if self.cars[i].x > -100 then
            allGone = false
        end
    end

    if allGone then
        self:spawnCars()
    end
end

function EscapeGame:animationPacing()
    if self.frameCounter == 2 then
        self.imageCounter += 1

        if self.imageCounter == 5 then
            self.imageCounter = 1
            self.pY = self.pY + self.carWiggle
            self.carWiggle = self.carWiggle * -1
        end

        self.frameCounter = 1
    else
        self.frameCounter += 1
    end
end

function EscapeGame:update()
    if self.gameOver == true then
        self.waitCounter += 1

        if self.fail then
            self.score = 0 + (self.timerLength - self.timeScore)
        else
            self.score = 5 + (self.timerLength - self.timeScore)
        end

        return
    end

    self:timerLimit()

    local acceleratedChange = pd.getCrankChange()

    self.pY = self.pY + (acceleratedChange / 4)
    self.pY = math.max(-14, math.min(self.pY, 176))

    self:animationPacing()
end

function EscapeGame:draw()
    gfx.clear()

    self.bg[self.imageCounter]:draw(0, 0)

    if self.gameOver == true then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

        if self.fail then
            gfx.drawTextAligned("CRASHED!", 200, 95, kTextAlignment.center)
        else
            gfx.drawTextAligned("ESCAPED!", 200, 95, kTextAlignment.center)
        end

        gfx.drawTextAligned("Score: " .. self.score, 200, 130, kTextAlignment.center)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        return
    end

-- -------------------------------------------------------------------------
-- TRANSITION HELPERS
-- -------------------------------------------------------------------------
    self.player:draw(self.pX, self.pY)

    if self.gameStart == self.framesBeforeGameStart then
        self:trafficTimer()
    else
        self.gameStart += 1
    end
end

function EscapeGame:isComplete()
    return not self.fail and self.gameOver and self.waitCounter > 60
end

function EscapeGame:didFail()
    return self.fail and self.gameOver and self.waitCounter > 60
end

function EscapeGame:cleanup()
    self.cars = {}
end

return EscapeGame