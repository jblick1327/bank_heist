-- glass_game.lua
-- Refactored Playdate module version - Easy Mode

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound

local GlassGame = {}

-- ─────────────────────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────────────────────

local SCREEN_WIDTH_PX = 400
local SCREEN_HEIGHT_PX = 240

local BG_PATH   = "images/glass_game/glass_game"
local HAND_PATH = "images/glass_game/glass_game_glove"
local FAIL_PATH = "images/glass_game/glass_game_fail"

local HAND_PIVOT_X_PX = 125
local HAND_PIVOT_Y_PX = 9

local ORBIT_CENTER_X = SCREEN_WIDTH_PX / 2
local ORBIT_CENTER_Y = SCREEN_HEIGHT_PX / 2
local ORBIT_RADIUS   = ORBIT_CENTER_Y * 0.85

local HAND_ROTATION_SCALE = 40

local ZINDEX_HAND       = 1000
local ZINDEX_BACKGROUND = -1000
local ZINDEX_FAIL       = -2000

-- DIFFICULTY SETTINGS
local FORGIVENESS_DEG_PER_FRAME = 15 -- Increased from 6 (Allows more jitter)
local MAX_STOPPED_FRAMES = 30        -- Allows stopping for ~1 second before failing

-- ─────────────────────────────────────────────────────────────
-- Constructor
-- ─────────────────────────────────────────────────────────────

function GlassGame.new()
    local self = {}
    setmetatable(self, { __index = GlassGame })

    -- State
    self.accum = 0
    self.degrees_last_frame = 0
    self.stop_counter = 0

    self.lost = false
    self.won = false
    self.fail = false
    self.gameOver = false

    self.score = 0
    self.timeScore = 0
    self.wait = 60
    self.waitCounter = 0

    self.timerLength = 12
    self.startTime = pd.getCurrentTimeMilliseconds()

    self.alreadyWon = false
    self.hasPlayedFailSound = false
    self.crankedThisFrame = false

    -- Images / Sprites
    self.background_image = gfx.image.new(BG_PATH)
    self.fail_background_image = gfx.image.new(FAIL_PATH)
    self.hand_image = gfx.image.new(HAND_PATH)
    self.trail_image = gfx.image.new(SCREEN_WIDTH_PX, SCREEN_HEIGHT_PX, gfx.kColorClear)

    local hand_width, hand_height = self.hand_image:getSize()
    self.hand_sprite = gfx.sprite.new(self.hand_image)
    self.hand_sprite:setCenter(HAND_PIVOT_X_PX / hand_width, HAND_PIVOT_Y_PX / hand_height)
    self.hand_sprite:setZIndex(ZINDEX_HAND)

    self.background_sprite = gfx.sprite.new(self.background_image)
    self.background_sprite:setCenter(0,0)
    self.background_sprite:moveTo(0,0)
    self.background_sprite:setZIndex(ZINDEX_BACKGROUND)

    self.fail_background_sprite = gfx.sprite.new(self.fail_background_image)
    self.fail_background_sprite:setCenter(0,0)
    self.fail_background_sprite:moveTo(0,0)
    self.fail_background_sprite:setZIndex(ZINDEX_FAIL)

    self.trail_sprite = gfx.sprite.new(self.trail_image)
    self.trail_sprite:setCenter(0,0)
    self.trail_sprite:moveTo(0,0)
    self.trail_sprite:setZIndex(ZINDEX_BACKGROUND + 1)

    self.background_sprite:add()
    self.fail_background_sprite:add()
    self.trail_sprite:add()
    self.hand_sprite:add()

    -- Audio Setup
    pd.setCrankSoundsDisabled(true)
    self.traceSynth = snd.synth.new(snd.kWaveNoise)
    self.traceFilter1 = snd.twopolefilter.new("bandpass")
    self.traceFilter2 = snd.twopolefilter.new("bandpass")
    self.traceChannel = snd.channel.new()
    self.traceChannel:addEffect(self.traceFilter1)
    self.traceChannel:addEffect(self.traceFilter2)
    self.traceChannel:addSource(self.traceSynth)

    self.centerPitch, self.pitchSpeedRange, self.maxSpeedForPitch = 6800, 600, 25
    self.resonance = 0.92
    self.wobble1Rate, self.wobble2Rate = 1.0, 1.7
    self.wobble1Depth, self.wobble2Depth = 25, 12
    self.volumeMultiplier, self.maxVolume = 0.04, 0.8
    self.volumeDecay, self.volumeSmoothing, self.pitchSmoothing = 0.1, 0.35, 0.2
    self.traceVolumeTarget, self.traceVolumeLevel = 0, 0
    self.tracePitchTarget, self.tracePitchLevel = self.centerPitch, self.centerPitch
    self.wobble1Phase, self.wobble2Phase = 0, 0

    self.traceFilter1:setFrequency(self.centerPitch)
    self.traceFilter1:setResonance(self.resonance)
    self.traceFilter2:setFrequency(self.centerPitch)
    self.traceFilter2:setResonance(self.resonance)

    self.traceSynth:setADSR(0.02, 0, 1.0, 0.05)
    self.traceSynth:playNote(100, nil)
    self.traceSynth:setVolume(0)

    self.crackSynth = snd.synth.new(snd.kWaveNoise)
    self.crackFilter = snd.twopolefilter.new("highpass")
    self.crackChannel = snd.channel.new()
    self.crackChannel:addEffect(self.crackFilter)
    self.crackChannel:addSource(self.crackSynth)

    self.discSynths = {snd.synth.new(snd.kWaveSine), snd.synth.new(snd.kWaveSine), snd.synth.new(snd.kWaveSine)}
    self.discChannel = snd.channel.new()
    for _, s in ipairs(self.discSynths) do self.discChannel:addSource(s) end

    self.shatterPlayer = snd.sampleplayer.new("shatter.wav")

    return self
end

-- ─────────────────────────────────────────────────────────────
-- Methods
-- ─────────────────────────────────────────────────────────────

function GlassGame:updateTrace(change)
    local speed = math.abs(change)
    if speed > 0 then
        self.traceVolumeTarget = math.min(speed * self.volumeMultiplier, self.maxVolume)
        self.tracePitchTarget = self.centerPitch + (math.min(speed/self.maxSpeedForPitch, 1) * self.pitchSpeedRange)
    else
        self.traceVolumeTarget *= self.volumeDecay
    end

    self.traceVolumeLevel += (self.traceVolumeTarget - self.traceVolumeLevel) * self.volumeSmoothing
    self.traceSynth:setVolume(self.traceVolumeLevel)

    self.tracePitchLevel += (self.tracePitchTarget - self.tracePitchLevel) * self.pitchSmoothing
    self.wobble1Phase += self.wobble1Rate
    self.wobble2Phase += self.wobble2Rate
    local wobble = math.sin(self.wobble1Phase) * self.wobble1Depth + math.sin(self.wobble2Phase) * self.wobble2Depth
    self.traceFilter1:setFrequency(self.tracePitchLevel + wobble)
    self.traceFilter2:setFrequency(self.tracePitchLevel + wobble)
end

function GlassGame:playPopOut()
    if self.alreadyWon then return end
    self.alreadyWon = true
    local f = 920
    self.crackFilter:setFrequency(f * 4.25)
    self.crackSynth:setADSR(0.12, 0.06, 0, 0, 0)
    self.crackSynth:playNote(100, 0.4, 5)

    pd.timer.performAfterDelay(120, function()
        local ratios = {1.0, 2.32, 4.25}
        local gains = {0.6, 0.25, 0.12}
        for i = 1, 3 do
            self.discSynths[i]:setADSR(0.05, (i==1 and 1 or 0.2), 0, 0, 1)
            self.discSynths[i]:playNote(f * ratios[i], gains[i] * 0.2, 1)
        end
    end)
end

function GlassGame:timerLimit()
    local elapsedTime = (pd.getCurrentTimeMilliseconds() - self.startTime) / 1000
    local timeLeft = math.max(0, math.ceil(self.timerLength - elapsedTime))
    self.timeScore = timeLeft
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Time: " .. timeLeft, 300, 15)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    if timeLeft <= 0 then self.fail, self.gameOver = true, true end
end

function GlassGame:update()
    if self.gameOver then
        pd.timer.updateTimers()
        gfx.clear()
        gfx.setColor(gfx.kColorWhite)
        local msg = self.fail and "Score: " .. self.score or "You Win! Score: " .. self.score
        gfx.drawText(msg, 130, 130)
        return
    end

    local change = pd.getCrankChange()
    self:updateTrace(change)

    -- Logic: Only start failing after the player has moved a bit
    if not self.fail then
        self.accum += change
        
        if math.abs(self.accum) > 10 then
            -- 1. Check for consistency (too fast/jittery)
            local diff = math.abs(change - self.degrees_last_frame)
            if diff > FORGIVENESS_DEG_PER_FRAME then
                self.fail = true
            end

            -- 2. Check for backwards cranking (Instant Fail)
            if self.accum > 0 and change < -2 then self.fail = true end
            if self.accum < 0 and change > 2 then self.fail = true end

            -- 3. Check for stopping (Grace period)
            if math.abs(change) < 0.1 then
                self.stop_counter += 1
                if self.stop_counter > MAX_STOPPED_FRAMES then self.fail = true end
            else
                self.stop_counter = 0 -- Reset grace period if they move
            end
        end
    end

    self.degrees_last_frame = change

    if self.fail then
        self.score = 1

        if not self.hasPlayedFailSound then
            if self.shatterPlayer then
                self.shatterPlayer:play()
            else
                print("Warning: shatter.wav not found or failed to load.")
            end
            self.hasPlayedFailSound = true
            -- Hide the hand and trail so only the broken glass shows
            self.hand_sprite:setVisible(false)
            self.trail_sprite:setVisible(false)
        end

        self.traceSynth:setVolume(0)

        -- Bring the fail image to the very front
        self.fail_background_sprite:setZIndex(ZINDEX_HAND + 100)

        gfx.sprite.update()

        -- Buffer Timer: 90 frames is roughly 3 seconds at 30fps
        self.waitCounter += 1
        if self.waitCounter >= 90 then 
            self.gameOver = true
        end

        return
    end

    -- Win Condition: One full circle (360 degrees)
    if math.abs(self.accum) >= 360 then
        self.won = true
        self.score = self.timeScore
        self:playPopOut()
        self.gameOver = true
        return
    end

    -- Hand/Trail Rendering
    local crank_radians = math.rad(pd.getCrankPosition())
    local new_x = ORBIT_CENTER_X + math.sin(crank_radians) * ORBIT_RADIUS
    local new_y = ORBIT_CENTER_Y - math.cos(crank_radians) * ORBIT_RADIUS
    self.hand_sprite:moveTo(new_x, new_y)
    self.hand_sprite:setRotation(math.sin(crank_radians) * (180 / HAND_ROTATION_SCALE))

    gfx.pushContext(self.trail_image)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawPixel(new_x, new_y)
    gfx.popContext()
    self.trail_sprite:markDirty()

    gfx.sprite.update()
    self:timerLimit()
end

function GlassGame:isComplete() return self.won and self.gameOver end
function GlassGame:didFail() return self.fail and self.gameOver end
function GlassGame:cleanup()
    self.hand_sprite:remove()
    self.background_sprite:remove()
    self.fail_background_sprite:remove()
    self.trail_sprite:remove()
    
    -- Stop any looping synths
    self.traceSynth:setVolume(0)
    
    -- Ensure crank sounds are back to normal for the rest of the game
    playdate.setCrankSoundsDisabled(false)
end
return GlassGame