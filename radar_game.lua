import "CoreLibs/graphics"

-- ── Asset Paths ───────────────────────────────────────────────────────────────

local RADAR_BG_PATH   = "images/radar_game/radar_bg.png"
local RADAR_HAND_PATH = "images/radar_game/radar_hand.png"

-- ── Hand Sprite ───────────────────────────────────────────────────────────────

-- Pixel coords of the pivot point within the hand image
local HAND_PIVOT_X_PX = 9
local HAND_PIVOT_Y_PX = 11

-- Center of the elliptical orbit the hand moves along
local ORBIT_CENTER_X  = 254
local ORBIT_CENTER_Y  = 143
local ORBIT_RADIUS_X  = 13
local ORBIT_RADIUS_Y  = 14.4

-- Divides crank input before applying it to hand rotation (larger = subtler tilt)
local HAND_ROTATION_SCALE = 40

-- ── Sine Wave Display ─────────────────────────────────────────────────────────

local WAVE_START_X      = 90
local WAVE_END_X        = 191
local WAVE_Y            = 140
local WAVE_WAVELENGTH_PX = 101                          -- pixel-space period of the drawn wave
local WAVE_TARGET_PHASE_PX = WAVE_WAVELENGTH_PX / 2    -- crank phase that sounds "most detuned"

-- ── Amplitude (Signal Strength) ───────────────────────────────────────────────

local AMPLITUDE_MAX     = 27
local AMPLITUDE_MIN     = -AMPLITUDE_MAX
local AMPLITUDE_INITIAL = 10

-- ── Crank Mapping ─────────────────────────────────────────────────────────────

-- Random offset so the tuned position isn't always at the same crank angle
local CRANK_OFFSET_DEGREES = math.random(22, 333)

-- Crank must be within this many pixels of the tuned position to win
local WIN_PHASE_TOLERANCE_PX = 3.5

-- ── Sound ─────────────────────────────────────────────────────────────────────

local NOISE_NOTE               = 'C3'
local NOISE_RELEASE_SEC        = 2

local FILTER_BASE_FREQUENCY    = 6000
local FILTER_BASE_RESONANCE    = 0.85
local FILTER_MIN_MIX           = 0.8   -- wet mix floor (maximally detuned); perfect alignment drives mix to 1.0

-- How much the crank's phase offset shifts the post-tuning filter frequency
local FILTER_FREQ_CRANK_MULTIPLIER = 40

-- Overdrive gain formula: gain = (amplitude / AMPLITUDE_MAX) * GAIN_SCALE + GAIN_BASE
local GAIN_BASE  = 6
local GAIN_SCALE = 3

-- Win synth envelope — slow swell intentional, crossfades with the noise cutoff
local WIN_SYNTH_VOLUME  = 0.35  -- kept low; 6kHz sine is shrill at full volume
local WIN_SYNTH_ATTACK  = 2
local WIN_SYNTH_DECAY   = 2
local WIN_SYNTH_SUSTAIN = 0
local WIN_SYNTH_RELEASE = 2

-- ── Z-Indices ─────────────────────────────────────────────────────────────────

local ZINDEX_HAND       =  1000
local ZINDEX_BACKGROUND = -1000

-- ── Images & Sprites ─────────────────────────────────────────────────────────

local background_image = playdate.graphics.image.new(RADAR_BG_PATH)
local hand_image       = playdate.graphics.image.new(RADAR_HAND_PATH)

playdate.graphics.setColor(playdate.graphics.kColorBlack)

local hand_width, hand_height = hand_image:getSize()

local hand_sprite = playdate.graphics.sprite.new(hand_image)
hand_sprite:setCenter(HAND_PIVOT_X_PX / hand_width, HAND_PIVOT_Y_PX / hand_height)
hand_sprite:setZIndex(ZINDEX_HAND)

local background_sprite = playdate.graphics.sprite.new(background_image)
background_sprite:setCenter(0, 0)
background_sprite:moveTo(0, 0)
background_sprite:setZIndex(ZINDEX_BACKGROUND)

hand_sprite:add()
background_sprite:add()

-- ── Sound Setup ───────────────────────────────────────────────────────────────

local sd = playdate.sound

local noise_synth = sd.synth.new(sd.kWaveNoise)
noise_synth:setRelease(NOISE_RELEASE_SEC)

local noise_instrument = sd.instrument.new(noise_synth)
local channel = sd.channel.new()
channel:addSource(noise_instrument)
noise_instrument:playNote(NOISE_NOTE)

-- Bandpass applied before the bitcrusher; mix is modulated by crank detuning
local pre_tuning_filter = sd.twopolefilter.new("bandpass")
pre_tuning_filter:setFrequency(FILTER_BASE_FREQUENCY)
pre_tuning_filter:setResonance(FILTER_BASE_RESONANCE)
pre_tuning_filter:setMix(FILTER_MIN_MIX)

-- Bandpass applied after the bitcrusher; frequency is modulated by crank detuning
local post_tuning_filter = sd.twopolefilter.new("bandpass")
post_tuning_filter:setFrequency(FILTER_BASE_FREQUENCY)
post_tuning_filter:setResonance(FILTER_BASE_RESONANCE)

local bitcrusher = sd.bitcrusher.new()
bitcrusher:setUndersampling(1)
bitcrusher:setAmount(0.5)  -- quantization crush; 0.0 = clean, 1.0 = maximum crunch

local overdrive = sd.overdrive.new()
overdrive:setGain(AMPLITUDE_INITIAL / AMPLITUDE_MAX * GAIN_SCALE + GAIN_BASE)

channel:addEffect(pre_tuning_filter)
channel:addEffect(bitcrusher)
channel:addEffect(post_tuning_filter)
channel:addEffect(overdrive)

local win_synth = sd.synth.new(sd.kWaveSine)
win_synth:setADSR(WIN_SYNTH_ATTACK, WIN_SYNTH_DECAY, WIN_SYNTH_SUSTAIN, WIN_SYNTH_RELEASE)

-- Win overlay panel (drawn over gameplay on success)
local WIN_OVERLAY_X = 110
local WIN_OVERLAY_Y =  55
local WIN_OVERLAY_W = 180
local WIN_OVERLAY_H =  44
local WIN_OVERLAY_PADDING = 10

-- ── Game State ────────────────────────────────────────────────────────────────

local base_hand_angle   = 0
local target_amplitude  = math.random(2, AMPLITUDE_MAX)
local current_amplitude = AMPLITUDE_INITIAL
local has_won           = false
local win_hand_x        = 0   -- hand position frozen at the moment of winning
local win_hand_y        = 0

-- ── Update Loop ───────────────────────────────────────────────────────────────

function playdate.update()
    playdate.graphics.clear()

    local crank_degrees = playdate.getCrankPosition()
    local crank_radians = math.rad(crank_degrees)

    -- Move hand along its elliptical orbit, or hold it frozen at the tuned position
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

    -- Map crank angle into wave pixel space [0, WAVE_WAVELENGTH_PX)
    local crank_wave_position = ((CRANK_OFFSET_DEGREES + crank_degrees) % 360) / 360 * WAVE_WAVELENGTH_PX

    -- Distance from the "detuned centre" in pixel space; used to drive both filters
    local phase_offset_px = math.abs(WAVE_TARGET_PHASE_PX - crank_wave_position)

    -- Circular distance from the aligned phase (phase 0 ≡ WAVE_WAVELENGTH_PX);
    -- accounts for the wrap so values near 0 and near 101 are both treated as close to aligned
    local phase_distance          = math.abs(crank_wave_position - WAVE_WAVELENGTH_PX)
    local circular_phase_distance = math.min(phase_distance, WAVE_WAVELENGTH_PX - phase_distance)

    -- 1.0 = perfectly aligned (win position), 0.0 = half a wavelength away (maximum detuning)
    local alignment_normalized = 1 - circular_phase_distance / (WAVE_WAVELENGTH_PX / 2)

    -- Mix scales from FILTER_MIN_MIX (worst alignment) up to 1.0 (perfect alignment)
    pre_tuning_filter:setMix(FILTER_MIN_MIX + (1 - FILTER_MIN_MIX) * alignment_normalized)
    post_tuning_filter:setFrequency(FILTER_BASE_FREQUENCY + phase_offset_px * FILTER_FREQ_CRANK_MULTIPLIER)

    -- Amplitude controls
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        current_amplitude = math.min(AMPLITUDE_MAX, current_amplitude + 1)
        overdrive:setGain(math.abs(current_amplitude) / AMPLITUDE_MAX * GAIN_SCALE + GAIN_BASE)
    end
    if playdate.buttonJustPressed(playdate.kButtonDown) then
        current_amplitude = math.max(AMPLITUDE_MIN, current_amplitude - 1)
        overdrive:setGain(math.abs(current_amplitude) / AMPLITUDE_MAX * GAIN_SCALE + GAIN_BASE)
    end

    -- Win: crank tuned to the correct phase AND amplitude matched
    local crank_is_tuned    = circular_phase_distance < WIN_PHASE_TOLERANCE_PX
    local amplitude_matched = math.abs(current_amplitude) == target_amplitude

    if crank_is_tuned and amplitude_matched and not has_won then
        win_synth:playNote(FILTER_BASE_FREQUENCY, WIN_SYNTH_VOLUME, 2)
        noise_instrument:allNotesOff()
        print("win!")
        has_won  = true
        win_hand_x = ORBIT_CENTER_X + math.sin(crank_radians) * ORBIT_RADIUS_X
        win_hand_y = ORBIT_CENTER_Y - math.cos(crank_radians) * ORBIT_RADIUS_Y
    end

    playdate.graphics.sprite.update()

    -- Target wave (what the player must match)
    playdate.graphics.drawSineWave(
        WAVE_START_X, WAVE_Y, WAVE_END_X, WAVE_Y,
        target_amplitude, target_amplitude, WAVE_WAVELENGTH_PX
    )
    -- Player's current tuning attempt (phase driven by crank); on win, draw it perfectly aligned
    local display_phase = has_won and 0 or crank_wave_position
    playdate.graphics.drawSineWave(
        WAVE_START_X, WAVE_Y, WAVE_END_X, WAVE_Y,
        current_amplitude, current_amplitude, WAVE_WAVELENGTH_PX, display_phase
    )

    -- Win overlay: filled panel with an inverted "SIGNAL LOCKED" label
    if has_won then
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        playdate.graphics.fillRect(WIN_OVERLAY_X, WIN_OVERLAY_Y, WIN_OVERLAY_W, WIN_OVERLAY_H)
        playdate.graphics.setColor(playdate.graphics.kColorWhite)
        playdate.graphics.drawRect(WIN_OVERLAY_X, WIN_OVERLAY_Y, WIN_OVERLAY_W, WIN_OVERLAY_H)
        playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        playdate.graphics.drawText(
            "*SIGNAL LOCKED*",
            WIN_OVERLAY_X + WIN_OVERLAY_PADDING,
            WIN_OVERLAY_Y + WIN_OVERLAY_PADDING
        )
        playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
    end
end
