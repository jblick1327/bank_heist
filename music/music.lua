local hopping_bass = import "bass/hopping"
local walking_bass = import "bass/walking"
local house_drums  = import "drums/house"
local swing_drums  = import "drums/swing"
local lead_melody  = import "melodies/lead"
local skank        = import "tidbits/skank"
local camel_slide  = import "tidbits/camel_slide"

import "CoreLibs/math"

local sd = playdate.sound

local TEMPO = 175
local TRANSPOSE = 13

-- Randomisation ranges (used in non‑EDO mode)
local VELOCITY_RANDOM_MIN = -0.1
local VELOCITY_RANDOM_MAX = 0.1

-- Envelopes: {attack, decay, sustain, release}
local ENVELOPE_KICK          = {0, 0.09, 0, 0.09}
local ENVELOPE_SNARE_38      = {0, 0.15, 0, 0.15}
local ENVELOPE_SNARE_40      = {0, 0.1, 0, 0.1}
local ENVELOPE_HIHAT_CLOSED  = {0, 0.08, 0, 0.08}
local ENVELOPE_HIHAT_OPEN    = {0, 0.20, 0, 0.20}
local ENVELOPE_CRASH         = {0, 0.4, 0, 0.4}
local ENVELOPE_RIDE          = {0, 0.17, 0, 0.17}
local ENVELOPE_RIM           = {0, 0.05, 0, 0.05}

-- Pitches (MIDI note numbers)
local PITCH_KICK         = 24
local PITCH_SNARE_38     = 38
local PITCH_SNARE_40     = 43
local PITCH_HIHAT_CLOSED = 60
local PITCH_HIHAT_OPEN   = 62
local PITCH_CRASH        = 48
local PITCH_RIDE         = 53
local PITCH_RIM          = 46

-- Volume scaling per drum type (1.0 = original event velocity, 0.5 = half, 1.5 = louder, etc.)
local DRUM_VELOCITY_SCALE = {
    kick          = 1.2,
    snare_38      = 1.5,
    snare_40      = 1.2,
    hihat_closed  = 0.8,
    hihat_open    = 0.93,
    crash         = 1.0,
    ride          = 0.75,
    rim           = 0.3,
}

-- Bass synth parameters
local BASS_WAVE          = sd.kWavePOPhase
local BASS_ATTACK        = 0.02
local BASS_DECAY         = 0.14
local BASS_SUSTAIN       = 0.4
local BASS_RELEASE       = 0.03
local BASS_LFO_RATE      = 0.1
local BASS_LFO_CENTER    = 0.5
local BASS_LFO_DEPTH     = 0.3
local BASS_FILTER_CUTOFF = 940
local BASS_FILTER_RES    = 0.44

-- Mute flags for individual instruments (set to true to silence at load time)
local MUTE = {
    kick          = false,
    snare_38      = false,
    snare_40      = false,
    hihat_closed  = false,
    hihat_open    = false,
    crash         = false,
    ride          = false,
    rim           = false,
    bass          = false,
}

local DRUM_NOTE_TO_TYPE = {
    [37] = "rim",
    [38] = "snare_38",
    [40] = "snare_40",
    [41] = "kick",
    [42] = "hihat_closed",
    [46] = "hihat_open",
    [49] = "crash",
    [51] = "ride",
}

local DRUM_TYPE_TO_PITCH = {
    kick          = PITCH_KICK,
    snare_38      = PITCH_SNARE_38,
    snare_40      = PITCH_SNARE_40,
    hihat_closed  = PITCH_HIHAT_CLOSED,
    hihat_open    = PITCH_HIHAT_OPEN,
    crash         = PITCH_CRASH,
    ride          = PITCH_RIDE,
    rim           = PITCH_RIM,
}

local DRUM_TYPE_TO_ENVELOPE = {
    kick          = ENVELOPE_KICK,
    snare_38      = ENVELOPE_SNARE_38,
    snare_40      = ENVELOPE_SNARE_40,
    hihat_closed  = ENVELOPE_HIHAT_CLOSED,
    hihat_open    = ENVELOPE_HIHAT_OPEN,
    crash         = ENVELOPE_CRASH,
    ride          = ENVELOPE_RIDE,
    rim           = ENVELOPE_RIM,
}

function MusicPlayer()
    local MusicPlayer = {}

    function MusicPlayer.buildSequence(trackDefinitions)
        local sequence = sd.sequence.new()
        sequence:setTempo(TEMPO)

        for _, trackDef in ipairs(trackDefinitions) do
            local track = sd.track.new()
            track:setInstrument(trackDef.instrument[1])

            local useEdo22 = trackDef.instrument[2]
            local function modifyNote(note)
                if not useEdo22 then
                    return note
                else
                    return note * (12/22) + TRANSPOSE
                end
            end

            local scale = trackDef.velocityScale or 1.0
            local velocityRandom = 0
            for _, event in ipairs(trackDef.data) do
                if not useEdo22 then
                    velocityRandom = playdate.math.lerp(VELOCITY_RANDOM_MIN, VELOCITY_RANDOM_MAX, math.random())
                end

                local pitch = trackDef.pitch or event.note
                pitch = modifyNote(pitch)

                local velocity = event.velocity * scale + velocityRandom
                track:addNote(event.step, pitch, event.length, velocity)
            end

            sequence:addTrack(track)
        end

        return sequence
    end

    return MusicPlayer
end

local function createNoiseDrumInstrument(env)
    local synth = sd.synth.new(sd.kWaveNoise)
    synth:setADSR(env[1], env[2], env[3], env[4])
    local instrument = sd.instrument.new(synth)

    local channel = sd.channel.new()
    channel:addSource(instrument)

    return {instrument, false, channel}
end

local function createBassInstrument()
    local synth = sd.synth.new(BASS_WAVE)
    synth:setADSR(BASS_ATTACK, BASS_DECAY, BASS_SUSTAIN, BASS_RELEASE)
    local instrument = sd.instrument.new(synth)
    local lfo = sd.lfo.new(sd.kLFOSine)
    lfo:setRate(BASS_LFO_RATE)
    lfo:setCenter(BASS_LFO_CENTER)
    lfo:setDepth(BASS_LFO_DEPTH)
    synth:setParameterMod(1, lfo)

    local filter = sd.twopolefilter.new("lowpass")
    filter:setFrequency(BASS_FILTER_CUTOFF)
    filter:setResonance(BASS_FILTER_RES)

    local channel = sd.channel.new()
    local od = sd.overdrive.new()
    od:setGain(1.7)
    channel:addSource(instrument)
    channel:addEffect(od)
    channel:addEffect(filter)

    return {instrument, true}
end

local function splitDrumEvents(drumEvents)
    local parts = {}
    for _, event in ipairs(drumEvents) do
        local drumType = DRUM_NOTE_TO_TYPE[event.note]
        if drumType then
            if not parts[drumType] then parts[drumType] = {} end
            table.insert(parts[drumType], event)
        end
    end
    return parts
end

local drumEventsByType = splitDrumEvents(swing_drums)
local drumChannels = {}   -- table to hold each drum’s channel

local drumTrackDefinitions = {}
for drumType, events in pairs(drumEventsByType) do
    if not MUTE[drumType] then
        local instrumentData = createNoiseDrumInstrument(DRUM_TYPE_TO_ENVELOPE[drumType])
        local instrument = instrumentData[1]
        local channel    = instrumentData[3]

        table.insert(drumTrackDefinitions, {
            data          = events,
            instrument    = {instrument, instrumentData[2]},
            pitch         = DRUM_TYPE_TO_PITCH[drumType],
            velocityScale = DRUM_VELOCITY_SCALE[drumType] or 1.0,
        })

        drumChannels[drumType] = channel
    end
end

local bassTrackDefinition = nil
if not MUTE.bass then
    bassTrackDefinition = { data = walking_bass, instrument = createBassInstrument() }
end

local allTrackDefinitions = {}
for _, drumDef in ipairs(drumTrackDefinitions) do
    table.insert(allTrackDefinitions, drumDef)
end
if bassTrackDefinition then
    table.insert(allTrackDefinitions, bassTrackDefinition)
end

local mp = MusicPlayer()
local sequence = mp.buildSequence(allTrackDefinitions)
sequence:setLoops(0)
sequence:play()

----------------------------------
-- drum fx
----------------------------------
if drumChannels.ride then
    local filter = sd.twopolefilter.new("bandpass")
    local od = sd.overdrive.new()
    od:setGain(2)
    filter:setFrequency(5300)
    filter:setResonance(0.7)
    drumChannels.ride:addEffect(od)
    drumChannels.ride:addEffect(filter)
end

if drumChannels.kick then
    local od = sd.overdrive.new()
    od:setGain(3)
    local filter = sd.twopolefilter.new("lopass")
    filter:setFrequency(630)
    filter:setResonance(0.2)
    drumChannels.kick:addEffect(od)
    drumChannels.kick:addEffect(filter)
end


if drumChannels.snare_40 then
    local filter = sd.twopolefilter.new("lopass")
    filter:setFrequency(5000)
    filter:setResonance(0.5)
    drumChannels.snare_40:addEffect(filter)
end
if drumChannels.rim then
    local od = sd.overdrive.new()
    od:setGain(5)
    od:setOffset(0.8)
    drumChannels.rim:addEffect(od)
end
----------------------------------
function playdate.update()
end
