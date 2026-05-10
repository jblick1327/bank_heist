-- escape_game.lua
import "CoreLibs/graphics"
import "CoreLibs/ui"

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
    self.pX = 10
    self.pY = 75
    self.speed = 12
    self.cars = {}
    
    self.timerLength = 5
    self.startTime = pd.getCurrentTimeMilliseconds()
    self.gameOver = false
    self.fail = false
    self.score = 0
    self.waitCounter = 0

    return self
end

function EscapeGame:update()
    if self.gameOver then
        self.waitCounter += 1
        return
    end

    -- Timer Logic
    local currentTime = pd.getCurrentTimeMilliseconds()
    local elapsedTime = (currentTime - self.startTime) / 1000
    if elapsedTime >= self.timerLength then
        self.fail = false
        self.gameOver = true
        self.score = 5 -- Win bonus
    end

    -- Movement
    local change = pd.getCrankChange()
    self.pY = self.pY + (change / 4)
    self.pY = math.max(-14, math.min(self.pY, 176))

    -- Animation
    self.frameCounter += 1
    if self.frameCounter > 2 then
        self.frameCounter = 1
        self.imageCounter += 1
        if self.imageCounter > 4 then self.imageCounter = 1 end
    end

    -- Traffic (Simplified spawn logic)
    if self.gameStart < self.framesBeforeGameStart then
        self.gameStart += 1
    else
        -- Your car spawning/movement logic goes here
        -- If player hits a car: self.fail = true, self.gameOver = true
    end
end

function EscapeGame:draw()
    -- Draw animated road
    if self.bg[self.imageCounter] then
        self.bg[self.imageCounter]:draw(0, 0)
    end

    -- Draw player
    if self.player then
        self.player:draw(self.pX, self.pY)
    end

    if self.gameOver then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        if self.fail then
            gfx.drawTextAligned("CRASHED!", 200, 110, kTextAlignment.center)
        else
            gfx.drawTextAligned("ESCAPED!", 200, 110, kTextAlignment.center)
        end
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

-- -------------------------------------------------------------------------
-- TRANSITION HELPERS
-- -------------------------------------------------------------------------

function EscapeGame:isComplete()
    return not self.fail and self.gameOver and self.waitCounter > 60
end

function EscapeGame:didFail()
    return self.fail and self.gameOver and self.waitCounter > 60
end

function EscapeGame:cleanup()
    gfx.sprite.removeAll()
end

return EscapeGame