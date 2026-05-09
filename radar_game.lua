import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics

-- Asset Paths
local RADAR_BG_PATH   = "images/radar_game/radar_bg.png"
local RADAR_HAND_PATH = "images/radar_game/radar_hand.png"

-- Hand Sprite
local HAND_PIVOT_X_PX = 9
local HAND_PIVOT_Y_PX = 11

local ORBIT_CENTER_X  = 254
local ORBIT_CENTER_Y  = 143
local ORBIT_RADIUS_X  = 13
local ORBIT_RADIUS_Y  = 14.4

local HAND_ROTATION_SCALE = 40

-- Sine Wave Display
local WAVE_START_X = 90
local WAVE_END_X = 191
local WAVE_Y = 140
local WAVE_WAVELENGTH_PX = 101
local WAVE_TARGET_PHASE_PX = WAVE_WAVELENGTH_PX / 2

-- Amplitude
local AMPLITUDE_MAX = 27
local AMPLITUDE_MIN = -AMPLITUDE_MAX
local AMPLITUDE_INITIAL = 10

-- Crank Mapping
local CRANK_OFFSET_DEGREES = math.random(22, 333)
local WIN_PHASE_TOLERANCE_PX = 3.5

-- Sound
local NOISE_NOTE = 'C3'
local NOISE_RELEASE_SEC = 2

local FILTER_BASE_FREQUENCY = 6000
local FILTER_BASE_RESONANCE = 0.85
local FILTER_MIN_MIX = 0.8
local FILTER_FREQ_CRANK_MULTIPLIER = 40

local GAIN_BASE = 6
local GAIN_SCALE = 3

local WIN_SYNTH_VOLUME = 0.35
local WIN_SYNTH_ATTACK = 2
local WIN_SYNTH_DECAY = 2
local WIN_SYNTH_SUSTAIN = 0
local WIN_SYNTH_RELEASE = 2

-- Timer / Score
local timerLength = 8 -- seconds
local startTime = pd.getCurrentTimeMilliseconds()

local gameOver = false
local fail = false
local score = 0
local timeScore = 0

-- Z-Indices
local ZINDEX_HAND = 1000
local ZINDEX_BACKGROUND = -1000

-- Images & Sprites
local background_image = gfx.image.new(RADAR_BG_PATH)
local hand_image = gfx.image.new(RADAR_HAND_PATH)

gfx.setColor(gfx.kColorBlack)

local hand_width, hand_height = hand_image:getSize()

local hand_sprite = gfx.sprite.new(hand_image)
hand_sprite:setCenter(HAND_PIVOT_X_PX / hand_width, HAND_PIVOT_Y_PX / hand_height)
hand_sprite:setZIndex(ZINDEX_HAND)

local background_sprite = gfx.sprite.new(background_image)
background_sprite:setCenter(0, 0)
background_sprite:moveTo(0, 0)
background_sprite:setZIndex(ZINDEX_BACKGROUND)

hand_sprite:add()
background_sprite:add()

-- Sound Setup
local sd = pd.sound

local noise_synth = sd.synth.new(sd.kWaveNoise)
noise_synth:setRelease(NOISE_RELEASE_SEC)

local noise_instrument = sd.instrument.new(noise_synth)
local channel = sd.channel.new()
channel:addSource(noise_instrument)
noise_instrument:playNote(NOISE_NOTE)

local pre_tuning_filter = sd.twopolefilter.new("bandpass")
pre_tuning_filter:setFrequency(FILTER_BASE_FREQUENCY)
pre_tuning_filter:setResonance(FILTER_BASE_RESONANCE)
pre_tuning_filter:setMix(FILTER_MIN_MIX)

local post_tuning_filter = sd.twopolefilter.new("bandpass")
post_tuning_filter:setFrequency(FILTER_BASE_FREQUENCY)
post_tuning_filter:setResonance(FILTER_BASE_RESONANCE)

local bitcrusher = sd.bitcrusher.new()
bitcrusher:setUndersampling(1)
bitcrusher:setAmount(0.5)

local overdrive = sd.overdrive.new()
overdrive:setGain(AMPLITUDE_INITIAL / AMPLITUDE_MAX * GAIN_SCALE + GAIN_BASE)

channel:addEffect(pre_tuning_filter)
channel:addEffect(bitcrusher)
channel:addEffect(post_tuning_filter)
channel:addEffect(overdrive)

local win_synth = sd.synth.new(sd.kWaveSine)
win_synth:setADSR(WIN_SYNTH_ATTACK, WIN_SYNTH_DECAY, WIN_SYNTH_SUSTAIN, WIN_SYNTH_RELEASE)

-- Win overlay
local WIN_OVERLAY_X = 110
local WIN_OVERLAY_Y = 55
local WIN_OVERLAY_W = 180
local WIN_OVERLAY_H = 44
local WIN_OVERLAY_PADDING = 10

-- Game State
local base_hand_angle = 0
local target_amplitude = math.random(2, AMPLITUDE_MAX)
local current_amplitude = AMPLITUDE_INITIAL
local has_won = false
local win_hand_x = 0
local win_hand_y = 0

function timerLimit()
    local currentTime = pd.getCurrentTimeMilliseconds()
    local elapsedTime = (currentTime - startTime) / 1000

    local timeLeft = math.ceil(timerLength - elapsedTime)

    if timeLeft < 0 then
        timeLeft = 0
    end

    timeScore = timeLeft

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Time Left: " .. timeLeft, 280, 10)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    if timeLeft <= 0 and not has_won then
        fail = true
        gameOver = true
        noise_instrument:allNotesOff()
    end
end

function playdate.update()
    gfx.clear()

    local crank_degrees = pd.getCrankPosition()
    local crank_radians = math.rad(crank_degrees)

    if gameOver then
        gfx.clear()

        if fail then
            score = 1
        else
            score = 4 + timeScore
        end

        gfx.drawText("Score: " .. score, 150, 130)

        return score
    end

    -- Move hand
    if has_won then
        hand_sprite:moveTo(win_hand_x, win_hand_y)
    else
        hand_sprite:moveTo(
            ORBIT_CENTER_X + math.sin(crank_radians) * ORBIT_RADIUS_X,
            ORBIT_CENTER_Y - math.cos(crank_radians) * ORBIT_RADIUS_Y
        )
    end

    if not has_won then
        hand_sprite:setRotation(base_hand_angle + math.sin(crank_radians) * (180 / HAND_ROTATION_SCALE))
    end

    local crank_wave_position = ((CRANK_OFFSET_DEGREES + crank_degrees) % 360) / 360 * WAVE_WAVELENGTH_PX

    local phase_offset_px = math.abs(WAVE_TARGET_PHASE_PX - crank_wave_position)

    local phase_distance = math.abs(crank_wave_position - WAVE_WAVELENGTH_PX)
    local circular_phase_distance = math.min(phase_distance, WAVE_WAVELENGTH_PX - phase_distance)

    local alignment_normalized = 1 - circular_phase_distance / (WAVE_WAVELENGTH_PX / 2)

    pre_tuning_filter:setMix(FILTER_MIN_MIX + (1 - FILTER_MIN_MIX) * alignment_normalized)
    post_tuning_filter:setFrequency(FILTER_BASE_FREQUENCY + phase_offset_px * FILTER_FREQ_CRANK_MULTIPLIER)

    -- Amplitude controls
    if pd.buttonJustPressed(pd.kButtonUp) then
        current_amplitude = math.min(AMPLITUDE_MAX, current_amplitude + 1)
        overdrive:setGain(math.abs(current_amplitude) / AMPLITUDE_MAX * GAIN_SCALE + GAIN_BASE)
    end

    if pd.buttonJustPressed(pd.kButtonDown) then
        current_amplitude = math.max(AMPLITUDE_MIN, current_amplitude - 1)
        overdrive:setGain(math.abs(current_amplitude) / AMPLITUDE_MAX * GAIN_SCALE + GAIN_BASE)
    end

    local crank_is_tuned = circular_phase_distance < WIN_PHASE_TOLERANCE_PX
    local amplitude_matched = math.abs(current_amplitude) == target_amplitude

    if crank_is_tuned and amplitude_matched and not has_won then
        win_synth:playNote(FILTER_BASE_FREQUENCY, WIN_SYNTH_VOLUME, 2)
        noise_instrument:allNotesOff()

        has_won = true
        fail = false
        gameOver = true

        win_hand_x = ORBIT_CENTER_X + math.sin(crank_radians) * ORBIT_RADIUS_X
        win_hand_y = ORBIT_CENTER_Y - math.cos(crank_radians) * ORBIT_RADIUS_Y
    end

    gfx.sprite.update()

    gfx.drawSineWave(
        WAVE_START_X, WAVE_Y, WAVE_END_X, WAVE_Y,
        target_amplitude, target_amplitude, WAVE_WAVELENGTH_PX
    )

    local display_phase = has_won and 0 or crank_wave_position

    gfx.drawSineWave(
        WAVE_START_X, WAVE_Y, WAVE_END_X, WAVE_Y,
        current_amplitude, current_amplitude, WAVE_WAVELENGTH_PX, display_phase
    )

    timerLimit()
end