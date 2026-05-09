import "CoreLibs/graphics"
local SCREEN_WIDTH_PX = 400
local SCREEN_HEIGHT_PX = 240

-- ── Asset Paths ───────────────────────────────────────────────────────────────

local BG_PATH   = "images/glass_game/glass_game.png"
local HAND_PATH = "images/glass_game/glass_game_glove.png"
local FAIL_PATH = "images/glass_game/glass_game_fail.png"

-- ── Hand Sprite ───────────────────────────────────────────────────────────────

-- Pixel coords of the pivot point within the hand image
local HAND_PIVOT_X_PX = 114
local HAND_PIVOT_Y_PX = 18

-- Circle centre coords
local ORBIT_CENTER_X  = SCREEN_WIDTH_PX / 2
local ORBIT_CENTER_Y  = SCREEN_HEIGHT_PX / 2
local ORBIT_RADIUS = ORBIT_CENTER_Y * 0.8

-- SECRET SAUCE (larger = subtler juj)
local HAND_ROTATION_SCALE = 40

-- ── Z-Indices ─────────────────────────────────────────────────────────────────

local ZINDEX_HAND       =  1000
local ZINDEX_BACKGROUND = -1000
local ZINDEX_FAIL = -2000

-- ── Images & Sprites ─────────────────────────────────────────────────────────

local background_image = playdate.graphics.image.new(BG_PATH)
local fail_background_image = playdate.graphics.image.new(FAIL_PATH)
local hand_image       = playdate.graphics.image.new(HAND_PATH)

local hand_width, hand_height = hand_image:getSize()

local hand_sprite = playdate.graphics.sprite.new(hand_image)
hand_sprite:setCenter(HAND_PIVOT_X_PX / hand_width, HAND_PIVOT_Y_PX / hand_height)
hand_sprite:setZIndex(ZINDEX_HAND)

local background_sprite = playdate.graphics.sprite.new(background_image)
background_sprite:setCenter(0, 0)
background_sprite:moveTo(0, 0)
background_sprite:setZIndex(ZINDEX_BACKGROUND)

local fail_background_sprite = playdate.graphics.sprite.new(fail_background_image)
fail_background_sprite:setCenter(0,0)
fail_background_sprite:moveTo(0,0)
fail_background_sprite:setZIndex(ZINDEX_FAIL)

hand_sprite:add()
background_sprite:add()


-- ── Audio ─────────────────────────────────────────────────────────────────

local sound = playdate.sound
playdate.setCrankSoundsDisabled(true)

local traceSynth = sound.synth.new(sound.kWaveNoise)
local traceFilter1 = sound.twopolefilter.new("bandpass")
local traceFilter2 = sound.twopolefilter.new("bandpass")
local traceChannel = sound.channel.new()
traceChannel:addEffect(traceFilter1)
traceChannel:addEffect(traceFilter2)
traceChannel:addSource(traceSynth)

local centerPitch = 6800
local pitchSpeedRange = 600
local maxSpeedForPitch = 25
local resonance = 0.92

local wobble1Rate = 1.0
local wobble2Rate = 1.7
local wobble1Depth = 25
local wobble2Depth = 12

local volumeMultiplier = 0.04
local maxVolume = 0.8
local volumeDecay = 0.1
local volumeSmoothing = 0.35
local pitchSmoothing = 0.2

local traceVolumeTarget = 0
local traceVolumeLevel = 0
local tracePitchTarget = centerPitch
local tracePitchLevel = centerPitch
local wobble1Phase = 0
local wobble2Phase = 0
local crankedThisFrame = false

traceFilter1:setFrequency(centerPitch)
traceFilter1:setResonance(resonance)
traceFilter2:setFrequency(centerPitch)
traceFilter2:setResonance(resonance)

traceSynth:setADSR(0.02, 0, 1.0, 0.05)
traceSynth:playNote(100, 1) 
traceSynth:setVolume(0)

function playdate.cranked(change, accelerated)
    local speed = math.abs(change)
    local normSpeed = math.min(speed / maxSpeedForPitch, 1)

    traceVolumeTarget = math.min(speed * volumeMultiplier, maxVolume)
    tracePitchTarget = centerPitch + normSpeed * pitchSpeedRange
    crankedThisFrame = true
end

local function updateTrace()
    if not crankedThisFrame then
        traceVolumeTarget = traceVolumeTarget * volumeDecay
    end
    crankedThisFrame = false

    traceVolumeLevel = traceVolumeLevel + (traceVolumeTarget - traceVolumeLevel) * volumeSmoothing
    traceSynth:setVolume(traceVolumeLevel)

    tracePitchLevel = tracePitchLevel + (tracePitchTarget - tracePitchLevel) * pitchSmoothing
    wobble1Phase = wobble1Phase + wobble1Rate
    wobble2Phase = wobble2Phase + wobble2Rate
    local wobble = math.sin(wobble1Phase) * wobble1Depth
                 + math.sin(wobble2Phase) * wobble2Depth

    local cutoff = tracePitchLevel + wobble
    traceFilter1:setFrequency(cutoff)
    traceFilter2:setFrequency(cutoff)
end


--Win Sound
local crackSynth = sound.synth.new(sound.kWaveNoise)
local crackFilter = sound.twopolefilter.new("highpass")
local crackChannel = sound.channel.new()
crackChannel:addEffect(crackFilter)
crackChannel:addSource(crackSynth)

local discSynths = {
    sound.synth.new(sound.kWaveSine),
    sound.synth.new(sound.kWaveSine),
    sound.synth.new(sound.kWaveSine),
}
local discChannel = sound.channel.new()


local function playPopOut()

    local ratios = {1.0, 2.32, 4.25}
    local decays = {1.0, 0.25, 0.10}
    local gains  = {0.6, 0.25, 0.12}
    local f = 920
    crackFilter:setFrequency(f*ratios[3])
    crackFilter:setResonance(0.6)
    crackSynth:setADSR(0.12, 0.06, 0, 0, 0)
    crackSynth:playNote(100, 0.4, 5)
    
    playdate.timer.performAfterDelay(120, function() 
        
        for i = 1, 3 do
            discSynths[i]:setADSR(0.05, decays[i], 0, 0, 1)
            discSynths[i]:playNote(f * ratios[i], gains[i]*0.2, 1)
        end
    end)
end
------

local degrees_last_frame = 0
local FORGIVENESS_DEG_PER_FRAME = 5 --plus or minus

local is_consistent = true
function playdate.update()


    local degrees_this_frame = playdate.getCrankChange()
    print(degrees_this_frame)

    local crank_degrees = playdate.getCrankPosition()
    local crank_radians = math.rad(crank_degrees)

    is_consistent = math.abs(degrees_this_frame - degrees_last_frame) <= FORGIVENESS_DEG_PER_FRAME

    degrees_last_frame = degrees_this_frame

    if is_consistent then print("GOOD") else print("BAD") end

    if not is_consistent then
        fail_background_sprite:setZIndex(ZINDEX_BACKGROUND + 1)
    end
    hand_sprite:moveTo(
        ORBIT_CENTER_X + math.sin(crank_radians) * ORBIT_RADIUS,
        ORBIT_CENTER_Y - math.cos(crank_radians) * ORBIT_RADIUS
    )
    hand_sprite:setRotation(math.sin(crank_radians) * (180 / HAND_ROTATION_SCALE))


    playdate.graphics.sprite.update()
end
