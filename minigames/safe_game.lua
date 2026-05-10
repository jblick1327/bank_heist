-- safe_game.lua
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/crank"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local ps <const> = playdate.sound

local SafeGame = {}

function SafeGame.new()
    local self = {}
    setmetatable(self, { __index = SafeGame })

    pd.setCrankSoundsDisabled(true)

    -- -------------------------------------------------------------------------
    -- SOUND
    -- -------------------------------------------------------------------------
    self.clickSynth = ps.synth.new(ps.kWaveNoise)
    self.clickDrive = ps.overdrive.new()
    self.clickFilter = ps.twopolefilter.new("bandpass")
    self.clickChannel = ps.channel.new()

    self.clickChannel:addEffect(self.clickDrive)
    self.clickChannel:addEffect(self.clickFilter)
    self.clickChannel:addSource(self.clickSynth)

    -- -------------------------------------------------------------------------
    -- IMAGES & STATE
    -- -------------------------------------------------------------------------
    self.bg_noHand = gfx.image.new("images/safe_game/safe_game")
    self.bg_hand = gfx.image.new("images/safe_game/safe_game_handc")
    self.arrow = {
        gfx.image.new("images/safe_game/c"),
        gfx.image.new("images/safe_game/cc")
    }
    self.dButton = {
        gfx.image.new("images/safe_game/up"),
        gfx.image.new("images/safe_game/down"),
        gfx.image.new("images/safe_game/left"),
        gfx.image.new("images/safe_game/right")
    }
    self.faceButton = {
        gfx.image.new("images/safe_game/a"),
        gfx.image.new("images/safe_game/b")
    }

    self.direction = {pd.kButtonUp, pd.kButtonDown, pd.kButtonLeft, pd.kButtonRight}
    self.button = {pd.kButtonA, pd.kButtonB}

    self.randomDirection = math.random(1, 4)
    self.randomButton = math.random(1, 2)

    self.spotLow = math.random(0, 310)
    self.spotHigh = self.spotLow + 50
    self.clockwise = true
    self.clockOrCounterClock = self.clockwise

    self.safeCracks = 0
    self.safeCracksToWin = 3
    self.score = 0
    self.timeScore = 0

    self.timerLength = 60
    self.startTime = pd.getCurrentTimeMilliseconds()

    self.gameOver = false
    self.fail = false
    self.waitCounter = 0

    return self
end

function SafeGame:playTumblerClick()
    local pitch = math.random(2200, 2400)
    local gain = 0.8 + math.random()
    self.clickDrive:setGain(gain)
    self.clickFilter:setFrequency(pitch)
    self.clickFilter:setResonance(0.85)
    local decay = math.random(14, 20) / 1000
    self.clickSynth:setADSR(0, decay, 0, 0)
    self.clickSynth:playNote(pitch, 0.7, decay)
end

function SafeGame:timerLimit()
    local currentTime = pd.getCurrentTimeMilliseconds()
    local elapsedTime = (currentTime - self.startTime) / 1000
    local timeLeft = math.ceil(self.timerLength - elapsedTime)
    if timeLeft < 0 then timeLeft = 0 end
    self.timeScore = timeLeft

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Time: " .. timeLeft, 300, 15)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    if timeLeft <= 0 then
        self.fail = true
        self.gameOver = true
    end
end

function SafeGame:update()
    -- 1. TIMER & GAME OVER LOGIC
    if self.gameOver then
        self.waitCounter += 1
        return 
    end

    self:timerLimit()

    -- 2. CRANK & INPUT LOGIC
    local crankPosition = pd.getCrankPosition()
    local spotBuffer = 80 
    local inSpot = (crankPosition >= self.spotLow and crankPosition <= (self.spotLow + spotBuffer))

    if inSpot then
        local dPadHit = pd.buttonIsPressed(self.direction[self.randomDirection])
        local faceHit = pd.buttonJustPressed(self.button[self.randomButton])

        if dPadHit and faceHit then
            self.clockOrCounterClock = not self.clockOrCounterClock
            self.randomDirection = math.random(1, 4)
            self.randomButton = math.random(1, 2)
            self.spotLow = math.random(0, 280) 
            self.safeCracks += 1
            self:playTumblerClick()
        end
    end

    if self.safeCracks >= self.safeCracksToWin then
        self.score = self.timeScore
        self.fail = false
        self.gameOver = true
    end
end

-- NEW FUNCTION: Move all drawing here
function SafeGame:draw()
    local change = pd.getCrankChange()
    
    -- Draw background based on movement
    if not self.gameOver and math.abs(change) > 0.1 then
        if self.bg_hand then self.bg_hand:draw(0, 0) end
    else
        if self.bg_noHand then self.bg_noHand:draw(0, 0) end
    end

    if self.gameOver then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("* SAFE CRACKED *", 200, 110, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        return
    end

    -- Draw UI elements
    if self.clockOrCounterClock then
        if self.arrow[1] then self.arrow[1]:draw(0, 0) end
    else
        if self.arrow[2] then self.arrow[2]:draw(0, 0) end
    end

    local crankPosition = pd.getCrankPosition()
    if crankPosition >= self.spotLow and crankPosition <= (self.spotLow + 80) then
        gfx.drawTextAligned("! CLICK !", 200, 185, kTextAlignment.center)
        if self.dButton[self.randomDirection] then self.dButton[self.randomDirection]:draw(255, 157) end
        if self.faceButton[self.randomButton] then self.faceButton[self.randomButton]:draw(340, 170) end
    end
end

-- -------------------------------------------------------------------------
-- SCENE TRANSITION HELPERS
-- -------------------------------------------------------------------------

function SafeGame:isComplete()
    return not self.fail and self.gameOver and self.waitCounter > 60
end

function SafeGame:didFail()
    return self.fail and self.gameOver and self.waitCounter > 60
end

function SafeGame:cleanup()
    pd.setCrankSoundsDisabled(false)
end

return SafeGame