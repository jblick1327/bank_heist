-- radar_game.lua
-- Refactored Playdate module version

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound

local RadarGame = {}

-- ─────────────────────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────────────────────

local RADAR_BG_PATH   = "images/radar_game/radar_bg"
local RADAR_HAND_PATH = "images/radar_game/radar_hand"

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

-- Crank
local WIN_PHASE_TOLERANCE_PX = 5.0

-- Sound
local NOISE_NOTE = "C3"
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

-- Timer
local TIMER_LENGTH = 20

-- Z-Indices
local ZINDEX_HAND = 1000
local ZINDEX_BACKGROUND = -1000

-- ─────────────────────────────────────────────────────────────
-- Constructor
-- ─────────────────────────────────────────────────────────────

function RadarGame.new()

    local self = {}

    setmetatable(self, { __index = RadarGame })

    -- =========================================================
    -- State
    -- =========================================================

    self.startTime = pd.getCurrentTimeMilliseconds()

    self.gameOver = false
    self.fail = false

    self.score = 0
    self.timeScore = 0

    self.has_won = false

    self.base_hand_angle = 0

    self.current_amplitude = AMPLITUDE_INITIAL
    self.target_amplitude = math.random(2, AMPLITUDE_MAX)

    self.CRANK_OFFSET_DEGREES = math.random(22, 333)

    self.win_hand_x = 0
    self.win_hand_y = 0

    -- =========================================================
    -- Images & Sprites
    -- =========================================================

    self.background_image = gfx.image.new(RADAR_BG_PATH)
    self.hand_image = gfx.image.new(RADAR_HAND_PATH)

    local hand_width, hand_height =
        self.hand_image:getSize()

    self.hand_sprite = gfx.sprite.new(self.hand_image)

    self.hand_sprite:setCenter(
        HAND_PIVOT_X_PX / hand_width,
        HAND_PIVOT_Y_PX / hand_height
    )

    self.hand_sprite:setZIndex(ZINDEX_HAND)

    self.background_sprite =
        gfx.sprite.new(self.background_image)

    self.background_sprite:setCenter(0, 0)
    self.background_sprite:moveTo(0, 0)
    self.background_sprite:setZIndex(ZINDEX_BACKGROUND)

    self.background_sprite:add()
    self.hand_sprite:add()

    gfx.setColor(gfx.kColorBlack)

    -- =========================================================
    -- Sound Setup
    -- =========================================================

    self.noise_synth = snd.synth.new(snd.kWaveNoise)
    self.noise_synth:setRelease(NOISE_RELEASE_SEC)

    self.noise_instrument =
        snd.instrument.new(self.noise_synth)

    self.channel = snd.channel.new()
    self.channel:addSource(self.noise_instrument)

    self.noise_instrument:playNote(NOISE_NOTE)

    self.pre_tuning_filter =
        snd.twopolefilter.new("bandpass")

    self.pre_tuning_filter:setFrequency(
        FILTER_BASE_FREQUENCY
    )

    self.pre_tuning_filter:setResonance(
        FILTER_BASE_RESONANCE
    )

    self.pre_tuning_filter:setMix(FILTER_MIN_MIX)

    self.post_tuning_filter =
        snd.twopolefilter.new("bandpass")

    self.post_tuning_filter:setFrequency(
        FILTER_BASE_FREQUENCY
    )

    self.post_tuning_filter:setResonance(
        FILTER_BASE_RESONANCE
    )

    self.bitcrusher = snd.bitcrusher.new()
    self.bitcrusher:setUndersampling(1)
    self.bitcrusher:setAmount(0.5)

    self.overdrive = snd.overdrive.new()

    self.overdrive:setGain(
        AMPLITUDE_INITIAL / AMPLITUDE_MAX
        * GAIN_SCALE
        + GAIN_BASE
    )

    self.channel:addEffect(self.pre_tuning_filter)
    self.channel:addEffect(self.bitcrusher)
    self.channel:addEffect(self.post_tuning_filter)
    self.channel:addEffect(self.overdrive)

    -- =========================================================
    -- Win Synth
    -- =========================================================

    self.win_synth = snd.synth.new(snd.kWaveSine)

    self.win_synth:setADSR(
        WIN_SYNTH_ATTACK,
        WIN_SYNTH_DECAY,
        WIN_SYNTH_SUSTAIN,
        WIN_SYNTH_RELEASE
    )

    return self
end

-- ─────────────────────────────────────────────────────────────
-- Timer
-- ─────────────────────────────────────────────────────────────

function RadarGame:timerLimit()

    local currentTime =
        pd.getCurrentTimeMilliseconds()

    local elapsedTime =
        (currentTime - self.startTime) / 1000

    local timeLeft =
        math.ceil(TIMER_LENGTH - elapsedTime)

    if timeLeft < 0 then
        timeLeft = 0
    end

    self.timeScore = timeLeft

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    gfx.drawText(
        "Time: " .. timeLeft,
        280,
        10
    )

    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    if timeLeft <= 0 and not self.has_won then

        self.fail = true
        self.gameOver = true

        self.noise_instrument:allNotesOff()
    end
end

-- ─────────────────────────────────────────────────────────────
-- Update
-- ─────────────────────────────────────────────────────────────

function RadarGame:update()

    gfx.clear()

    local crank_degrees =
        pd.getCrankPosition()

    local crank_radians =
        math.rad(crank_degrees)

    -- =========================================================
    -- Game Over
    -- =========================================================

    if self.gameOver then

        gfx.clear()

        if self.fail then
            self.score = 1
        else
            self.score = 4 + self.timeScore
        end

        gfx.drawText(
            "Score: " .. self.score,
            150,
            130
        )

        return self.score
    end

    -- =========================================================
    -- Hand Movement
    -- =========================================================

    if self.has_won then

        self.hand_sprite:moveTo(
            self.win_hand_x,
            self.win_hand_y
        )

    else

        self.hand_sprite:moveTo(
            ORBIT_CENTER_X +
            math.sin(crank_radians) * ORBIT_RADIUS_X,

            ORBIT_CENTER_Y -
            math.cos(crank_radians) * ORBIT_RADIUS_Y
        )
    end

    if not self.has_won then

        self.hand_sprite:setRotation(
            self.base_hand_angle +
            math.sin(crank_radians)
            * (180 / HAND_ROTATION_SCALE)
        )
    end

    -- =========================================================
    -- Wave / Tuning
    -- =========================================================

    local crank_wave_position =
        ((self.CRANK_OFFSET_DEGREES + crank_degrees) % 360)
        / 360
        * WAVE_WAVELENGTH_PX

    local phase_offset_px =
        math.abs(
            WAVE_TARGET_PHASE_PX -
            crank_wave_position
        )

    local phase_distance =
        math.abs(
            crank_wave_position -
            WAVE_WAVELENGTH_PX
        )

    local circular_phase_distance =
        math.min(
            phase_distance,
            WAVE_WAVELENGTH_PX - phase_distance
        )

    local alignment_normalized =
        1 -
        circular_phase_distance
        / (WAVE_WAVELENGTH_PX / 2)

    self.pre_tuning_filter:setMix(
        FILTER_MIN_MIX +
        (1 - FILTER_MIN_MIX)
        * alignment_normalized
    )

    self.post_tuning_filter:setFrequency(
        FILTER_BASE_FREQUENCY +
        phase_offset_px
        * FILTER_FREQ_CRANK_MULTIPLIER
    )

    -- =========================================================
    -- Amplitude Controls
    -- =========================================================

    if pd.buttonJustPressed(pd.kButtonUp) then

        self.current_amplitude =
            math.min(
                AMPLITUDE_MAX,
                self.current_amplitude + 1
            )

        self.overdrive:setGain(
            math.abs(self.current_amplitude)
            / AMPLITUDE_MAX
            * GAIN_SCALE
            + GAIN_BASE
        )
    end

    if pd.buttonJustPressed(pd.kButtonDown) then

        self.current_amplitude =
            math.max(
                AMPLITUDE_MIN,
                self.current_amplitude - 1
            )

        self.overdrive:setGain(
            math.abs(self.current_amplitude)
            / AMPLITUDE_MAX
            * GAIN_SCALE
            + GAIN_BASE
        )
    end

    -- =========================================================
    -- Win Check
    -- =========================================================

    local crank_is_tuned =
        circular_phase_distance
        < WIN_PHASE_TOLERANCE_PX

    local amplitude_matched =
        math.abs(self.current_amplitude)
        == self.target_amplitude

    if crank_is_tuned
    and amplitude_matched
    and not self.has_won then

        self.win_synth:playNote(
            FILTER_BASE_FREQUENCY,
            WIN_SYNTH_VOLUME,
            2
        )

        self.noise_instrument:allNotesOff()

        self.has_won = true
        self.fail = false
        self.gameOver = true

        self.win_hand_x =
            ORBIT_CENTER_X +
            math.sin(crank_radians)
            * ORBIT_RADIUS_X

        self.win_hand_y =
            ORBIT_CENTER_Y -
            math.cos(crank_radians)
            * ORBIT_RADIUS_Y
    end

    -- =========================================================
    -- Draw
    -- =========================================================

    gfx.sprite.update()

    gfx.drawSineWave(
        WAVE_START_X,
        WAVE_Y,
        WAVE_END_X,
        WAVE_Y,

        self.target_amplitude,
        self.target_amplitude,

        WAVE_WAVELENGTH_PX
    )

    local display_phase =
        self.has_won and 0 or crank_wave_position

    gfx.drawSineWave(
        WAVE_START_X,
        WAVE_Y,
        WAVE_END_X,
        WAVE_Y,

        self.current_amplitude,
        self.current_amplitude,

        WAVE_WAVELENGTH_PX,
        display_phase
    )

    self:timerLimit()
end

-- ─────────────────────────────────────────────────────────────
function RadarGame:isComplete()
    return self.has_won and self.gameOver
end

function RadarGame:didFail()
    return self.fail and self.gameOver
end

function RadarGame:cleanup()
    self.hand_sprite:remove()
    self.background_sprite:remove()
    -- Add any other sprites used in radar_game here
    if self.noise_instrument then
        self.noise_instrument:allNotesOff()
    end
end
return RadarGame