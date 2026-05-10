local hopping_bass = import "music/bass/hopping"
local walking_bass = import "music/bass/walking"
local house_drums  = import "music/drums/house"
local swing_drums  = import "music/drums/swing"
local lead_melody  = import "music/melodies/lead"
local skank        = import "music/tidbits/skank"
local camel_slide  = import "music/tidbits/camel_slide"

import "CoreLibs/math"

local sd = playdate.sound

-- ===========================
-- GLOBAL CONSTANTS
-- ===========================
local TEMPO_NORMAL = 175
local TEMPO_HALF   = 87.5
local TRANSPOSE    = 13

local VELOCITY_RANDOM_MIN = -0.1
local VELOCITY_RANDOM_MAX =  0.1

local OCTAVE_BASS        = 0
local OCTAVE_VIBRAPHONE  = 12
local OCTAVE_CAMEL_SLIDE = 12
local OCTAVE_SKANK       = 0
local OCTAVE_HALF_BASS   = -24

-- ===========================
-- SONG‑SPECIFIC EFFECTS
-- ===========================
local SONG_PARAMS = {
    [1] = { bass_filter_cutoff = 840, bass_filter_res = 0.44 },
    [2] = { bass_filter_cutoff = 360, bass_filter_res = 0.1 },
    [3] = { bass_filter_cutoff = 600, bass_filter_res = 0.3 },
    [4] = { bass_filter_cutoff = 300, bass_filter_res = 0.1 },
}

-- ===========================
-- MASTER VOLUME (0.0 – 1.0, >1.0 for boost)
-- ===========================
local VOLUME_BASS         = 1.0
local VOLUME_VIBRAPHONE   = 3
local VOLUME_CAMEL_SLIDE  = 0.5
local VOLUME_SKANK        = 3
local VOLUME_909_DRUMS    = 3
local VOLUME_SWING_DRUMS  = 1.0

-- ===========================
-- BASS SYNTH PARAMETERS
-- ===========================
local BASS_WAVE            = sd.kWavePOPhase
local BASS_ATTACK          = 0.02
local BASS_DECAY           = 0.14
local BASS_SUSTAIN         = 0.4
local BASS_RELEASE         = 0.03
local BASS_LFO_RATE        = 0.1
local BASS_LFO_CENTER      = 0.5
local BASS_LFO_DEPTH       = 0.3

-- ===========================
-- VIBRAPHONE SYNTH
-- ===========================
local VIBRA_WAVE           = sd.kWavePOVosim
local VIBRA_ATTACK         = 0.001
local VIBRA_DECAY          = 0.23
local VIBRA_SUSTAIN        = 0
local VIBRA_RELEASE        = 0.23
local VIBRA_VIBRATO_RATE   = 5
local VIBRA_VIBRATO_DEPTH  = 0.02
local VIBRA_FILTER_FREQ    = 4400
local VIBRA_FILTER_RES     = 0.15

-- ===========================
-- PORTAMENTO ECHO SYNTH
-- ===========================
local CAMEL_WAVE       = sd.kWavePODigital
local CAMEL_ATTACK     = 0.8
local CAMEL_DECAY      = 0.5
local CAMEL_SUSTAIN    = 0.6
local CAMEL_RELEASE    = 2
local PORTAMENTO_TIME  = 1
local DELAY_TIME       = 0.1714 * 2
local DELAY_FEEDBACK   = 0.7
local DELAY_MIX        = 0.4

-- ===========================
-- SKANK SYNTH
-- ===========================
local SKANK_WAVE         = sd.kWavePOVosim
local SKANK_ATTACK       = 0.0
local SKANK_DECAY        = 0.08
local SKANK_SUSTAIN      = 0.0
local SKANK_RELEASE      = 0.12
local SKANK_LFO_RATE     = 0.01
local SKANK_LFO_CENTER   = 0.5
local SKANK_LFO_DEPTH    = 0.5
local SKANK_VOICES       = 3

-- ===========================
-- 909 DRUM SYNTHESIS
-- ===========================
local DRUM_909_NOTE_TO_TYPE = {
    [37] = "rim",
    [38] = "snare",
    [41] = "kick",
    [45] = "tom_mid",
    [46] = "hihat_open",
    [47] = "tom_hi",
    [48] = "crash",
}

local KICK_909_PITCH        = 36
local KICK_909_PITCH_DECAY  = 0.08
local KICK_909_PITCH_DEPTH  = 24.0
local KICK_909_AMP_DECAY    = 0.22
local KICK_909_AMP_SUSTAIN  = 0.0
local KICK_909_AMP_RELEASE  = 0.05

local SNARE_909_PITCH            = 47
local SNARE_909_PITCH_DECAY      = 0.05
local SNARE_909_PITCH_DEPTH      = 12.0
local SNARE_909_TONE_AMP_DECAY   = 0.12
local SNARE_909_TONE_AMP_SUSTAIN = 0.0
local SNARE_909_TONE_AMP_RELEASE = 0.05
local SNARE_909_NOISE_AMP_DECAY  = 0.15
local SNARE_909_NOISE_AMP_SUSTAIN = 0.0
local SNARE_909_NOISE_AMP_RELEASE = 0.05
local SNARE_909_NOISE_FILTER_FREQ = 2500
local SNARE_909_NOISE_FILTER_RES  = 0.4

local HIHAT_909_PITCH        = 67
local HIHAT_909_AMP_DECAY    = 0.06
local HIHAT_909_AMP_SUSTAIN  = 0.0
local HIHAT_909_AMP_RELEASE  = 0.03
local HIHAT_909_FILTER_FREQ  = 12000
local HIHAT_909_FILTER_RES   = 0.2

local CRASH_909_PITCH        = 72
local CRASH_909_AMP_DECAY    = 0.35
local CRASH_909_AMP_SUSTAIN  = 0.0
local CRASH_909_AMP_RELEASE  = 0.1
local CRASH_909_FILTER_FREQ  = 8000
local CRASH_909_FILTER_RES   = 0.3

local RIM_909_PITCH        = 54
local RIM_909_AMP_DECAY    = 0.02
local RIM_909_AMP_SUSTAIN  = 0.0
local RIM_909_AMP_RELEASE  = 0.02
local RIM_909_FILTER_FREQ  = 3000
local RIM_909_FILTER_RES   = 0.5

local TOM_909_PITCH_DECAY  = 0.07
local TOM_909_PITCH_DEPTH  = 18.0
local TOM_909_AMP_DECAY    = 0.18
local TOM_909_AMP_SUSTAIN  = 0.0
local TOM_909_AMP_RELEASE  = 0.05
local TOM_MID_909_PITCH    = 47
local TOM_HI_909_PITCH     = 55

local DRUM_909_VELOCITY_SCALE = {
    kick       = 1.0,
    snare      = 1.0,
    hihat_open = 1.0,
    crash      = 1.5,
    rim        = 1,
    tom_mid    = 1.0,
    tom_hi     = 1.0,
}

-- ===========================
-- ORIGINAL SONG (noise kit)
-- ===========================
local ENVELOPE_KICK          = {0, 0.09, 0, 0.09}
local ENVELOPE_SNARE_38      = {0, 0.15, 0, 0.15}
local ENVELOPE_SNARE_40      = {0, 0.1,  0, 0.1 }
local ENVELOPE_HIHAT_CLOSED  = {0, 0.08, 0, 0.08}
local ENVELOPE_HIHAT_OPEN    = {0, 0.20, 0, 0.20}
local ENVELOPE_CRASH         = {0, 0.4,  0, 0.4 }
local ENVELOPE_RIDE          = {0, 0.17, 0, 0.17}
local ENVELOPE_RIM           = {0, 0.05, 0, 0.05}

local PITCH_KICK         = 24
local PITCH_SNARE_38     = 38
local PITCH_SNARE_40     = 43
local PITCH_HIHAT_CLOSED = 60
local PITCH_HIHAT_OPEN   = 62
local PITCH_CRASH        = 48
local PITCH_RIDE         = 53
local PITCH_RIM          = 46

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
    snare         = false,
    tom_mid       = false,
    tom_hi        = false,
}

-- ===========================
-- HELPERS
-- ===========================
local function splitDrumEventsByMapping(drumEvents, noteToType)
    local parts = {}
    for _, event in ipairs(drumEvents) do
        local drumType = noteToType[event.note]
        if drumType then
            if not parts[drumType] then
                parts[drumType] = {}
            end
            table.insert(parts[drumType], event)
        end
    end
    return parts
end

local function createBassInstrument(filterCutoff, filterResonance)
    local synth = sd.synth.new(BASS_WAVE)
    synth:setADSR(BASS_ATTACK, BASS_DECAY, BASS_SUSTAIN, BASS_RELEASE)
    local instrument = sd.instrument.new(synth)
    local lfo = sd.lfo.new(sd.kLFOSine)
    lfo:setRate(BASS_LFO_RATE)
    lfo:setCenter(BASS_LFO_CENTER)
    lfo:setDepth(BASS_LFO_DEPTH)
    synth:setParameterMod(1, lfo)

    local filter = sd.twopolefilter.new("lowpass")
    filter:setFrequency(filterCutoff)
    filter:setResonance(filterResonance)

    local channel = sd.channel.new()
    local od = sd.overdrive.new()
    od:setGain(1.7)
    channel:addSource(instrument)
    channel:addEffect(od)
    channel:addEffect(filter)

    return instrument, channel
end

local function buildMelodicTrack(data, instrument, velocityScale, useEdo22, pitchOffset)
    local track = sd.track.new()
    track:setInstrument(instrument)

    for _, event in ipairs(data) do
        local pitch = event.note
        if useEdo22 then
            pitch = pitch * (12 / 22) + TRANSPOSE
        end
        pitch = pitch + (pitchOffset or 0)
        local velocity = event.velocity * (velocityScale or 1.0)
        track:addNote(event.step, pitch, event.length, velocity)
    end
    return track
end

local function makePitchSweepSynth(waveform, pitchEnvelope)
    local synth = sd.synth.new(waveform)
    synth:setFrequencyMod(pitchEnvelope)
    local instrument = sd.instrument.new(synth)
    return synth, instrument
end

local function setupAmplitudeEnvelope(synth, attack, decay, sustain, release)
    local ampEnv = sd.envelope.new(attack, decay, sustain, release)
    synth:setAmplitudeMod(ampEnv)
    return ampEnv
end

-- 909 drum builders
local function createKick909()
    local channel = sd.channel.new()
    local pitchEnv = sd.envelope.new(0.0, KICK_909_PITCH_DECAY, 0.0, 0.0)
    pitchEnv:setRetrigger(true)
    local synth, instrument = makePitchSweepSynth(sd.kWaveSine, pitchEnv)
    setupAmplitudeEnvelope(synth, 0.0, KICK_909_AMP_DECAY, KICK_909_AMP_SUSTAIN, KICK_909_AMP_RELEASE)
    channel:addSource(instrument)
    return {instrument}, { channel }
end

local function createSnare909()
    local channel = sd.channel.new()
    local pitchEnv = sd.envelope.new(0.0, SNARE_909_PITCH_DECAY, 0.0, 0.0)
    pitchEnv:setRetrigger(true)
    local toneSynth, toneInstrument = makePitchSweepSynth(sd.kWaveTriangle, pitchEnv)
    setupAmplitudeEnvelope(toneSynth, 0.0, SNARE_909_TONE_AMP_DECAY,
                           SNARE_909_TONE_AMP_SUSTAIN, SNARE_909_TONE_AMP_RELEASE)

    local noiseSynth = sd.synth.new(sd.kWaveNoise)
    local noiseInstrument = sd.instrument.new(noiseSynth)
    setupAmplitudeEnvelope(noiseSynth, 0.0, SNARE_909_NOISE_AMP_DECAY,
                           SNARE_909_NOISE_AMP_SUSTAIN, SNARE_909_NOISE_AMP_RELEASE)
    local noiseFilter = sd.twopolefilter.new("bandpass")
    noiseFilter:setFrequency(SNARE_909_NOISE_FILTER_FREQ)
    noiseFilter:setResonance(SNARE_909_NOISE_FILTER_RES)

    channel:addSource(toneInstrument)
    channel:addSource(noiseInstrument)
    channel:addEffect(noiseFilter)

    return {toneInstrument, noiseInstrument}, { channel }
end

local function createHihat909()
    local channel = sd.channel.new()
    local noiseSynth = sd.synth.new(sd.kWaveNoise)
    local instrument = sd.instrument.new(noiseSynth)
    setupAmplitudeEnvelope(noiseSynth, 0.0, HIHAT_909_AMP_DECAY,
                           HIHAT_909_AMP_SUSTAIN, HIHAT_909_AMP_RELEASE)
    local hpf = sd.twopolefilter.new("hipass")
    hpf:setFrequency(HIHAT_909_FILTER_FREQ)
    hpf:setResonance(HIHAT_909_FILTER_RES)
    channel:addSource(instrument)
    channel:addEffect(hpf)
    return {instrument}, { channel }
end

local function createCrash909()
    local channel = sd.channel.new()
    local noiseSynth = sd.synth.new(sd.kWaveNoise)
    local instrument = sd.instrument.new(noiseSynth)
    setupAmplitudeEnvelope(noiseSynth, 0.0, CRASH_909_AMP_DECAY,
                           CRASH_909_AMP_SUSTAIN, CRASH_909_AMP_RELEASE)
    local bpf = sd.twopolefilter.new("bandpass")
    bpf:setFrequency(CRASH_909_FILTER_FREQ)
    bpf:setResonance(CRASH_909_FILTER_RES)
    channel:addSource(instrument)
    channel:addEffect(bpf)
    return {instrument}, { channel }
end

local function createRim909()
    local channel = sd.channel.new()
    local noiseSynth = sd.synth.new(sd.kWaveNoise)
    local instrument = sd.instrument.new(noiseSynth)
    setupAmplitudeEnvelope(noiseSynth, 0.0, RIM_909_AMP_DECAY,
                           RIM_909_AMP_SUSTAIN, RIM_909_AMP_RELEASE)
    local bpf = sd.twopolefilter.new("bandpass")
    bpf:setFrequency(RIM_909_FILTER_FREQ)
    bpf:setResonance(RIM_909_FILTER_RES)
    channel:addSource(instrument)
    channel:addEffect(bpf)
    return {instrument}, { channel }
end

local function createTom909(basePitch)
    local channel = sd.channel.new()
    local pitchEnv = sd.envelope.new(0.0, TOM_909_PITCH_DECAY, 0.0, 0.0)
    pitchEnv:setRetrigger(true)
    local synth, instrument = makePitchSweepSynth(sd.kWaveSine, pitchEnv)
    setupAmplitudeEnvelope(synth, 0.0, TOM_909_AMP_DECAY,
                           TOM_909_AMP_SUSTAIN, TOM_909_AMP_RELEASE)
    channel:addSource(instrument)
    return {instrument}, { channel }
end

local function build909DrumTracks()
    local drumEventsByType = splitDrumEventsByMapping(house_drums, DRUM_909_NOTE_TO_TYPE)
    local tracks = {}
    local channels = {}

    local function addDrumTrack(drumType, instruments, eventList, noteNumber)
        if MUTE[drumType] then return end
        local velScale = DRUM_909_VELOCITY_SCALE[drumType] or 1.0
        for _, instr in ipairs(instruments) do
            local track = sd.track.new()
            track:setInstrument(instr)
            for _, event in ipairs(eventList) do
                track:addNote(event.step, noteNumber, event.length, event.velocity * velScale)
            end
            table.insert(tracks, track)
        end
    end

    for drumType, events in pairs(drumEventsByType) do
        if drumType == "kick" then
            local instrs, chans = createKick909()
            channels.kick = chans[1]
            addDrumTrack("kick", instrs, events, KICK_909_PITCH)
        elseif drumType == "snare" then
            local instrs, chans = createSnare909()
            channels.snare = chans[1]
            addDrumTrack("snare", instrs, events, SNARE_909_PITCH)
        elseif drumType == "hihat_open" then
            local instrs, chans = createHihat909()
            channels.hihat_open = chans[1]
            addDrumTrack("hihat_open", instrs, events, HIHAT_909_PITCH)
        elseif drumType == "crash" then
            local instrs, chans = createCrash909()
            channels.crash = chans[1]
            addDrumTrack("crash", instrs, events, CRASH_909_PITCH)
        elseif drumType == "rim" then
            local instrs, chans = createRim909()
            channels.rim = chans[1]
            addDrumTrack("rim", instrs, events, RIM_909_PITCH)
        elseif drumType == "tom_mid" then
            local instrs, chans = createTom909(TOM_MID_909_PITCH)
            channels.tom_mid = chans[1]
            addDrumTrack("tom_mid", instrs, events, TOM_MID_909_PITCH)
        elseif drumType == "tom_hi" then
            local instrs, chans = createTom909(TOM_HI_909_PITCH)
            channels.tom_hi = chans[1]
            addDrumTrack("tom_hi", instrs, events, TOM_HI_909_PITCH)
        end
    end

    -- Apply overdrive boost if VOLUME_909_DRUMS > 1.0
    if VOLUME_909_DRUMS > 1.0 then
        for _, ch in pairs(channels) do
            local od = sd.overdrive.new()
            od:setGain(VOLUME_909_DRUMS)
            ch:addEffect(od)
        end
    end

    return tracks, channels
end

local function buildSwingDrumTracks()
    local drumEventsByType = splitDrumEventsByMapping(swing_drums, {
        [37] = "rim",
        [38] = "snare_38",
        [40] = "snare_40",
        [41] = "kick",
        [42] = "hihat_closed",
        [46] = "hihat_open",
        [49] = "crash",
        [51] = "ride",
    })

    local ENVELOPE_MAP = {
        kick          = ENVELOPE_KICK,
        snare_38      = ENVELOPE_SNARE_38,
        snare_40      = ENVELOPE_SNARE_40,
        hihat_closed  = ENVELOPE_HIHAT_CLOSED,
        hihat_open    = ENVELOPE_HIHAT_OPEN,
        crash         = ENVELOPE_CRASH,
        ride          = ENVELOPE_RIDE,
        rim           = ENVELOPE_RIM,
    }

    local PITCH_MAP = {
        kick          = PITCH_KICK,
        snare_38      = PITCH_SNARE_38,
        snare_40      = PITCH_SNARE_40,
        hihat_closed  = PITCH_HIHAT_CLOSED,
        hihat_open    = PITCH_HIHAT_OPEN,
        crash         = PITCH_CRASH,
        ride          = PITCH_RIDE,
        rim           = PITCH_RIM,
    }

    local tracks = {}
    local channels = {}

    for drumType, events in pairs(drumEventsByType) do
        if not MUTE[drumType] then
            local env = ENVELOPE_MAP[drumType]
            local pitch = PITCH_MAP[drumType]
            local velScale = DRUM_VELOCITY_SCALE[drumType] or 1.0

            local noiseSynth = sd.synth.new(sd.kWaveNoise)
            noiseSynth:setADSR(env[1], env[2], env[3], env[4])
            local instrument = sd.instrument.new(noiseSynth)
            local channel = sd.channel.new()
            channel:addSource(instrument)
            channels[drumType] = channel

            local track = sd.track.new()
            track:setInstrument(instrument)
            for _, event in ipairs(events) do
                local velRand = playdate.math.lerp(VELOCITY_RANDOM_MIN, VELOCITY_RANDOM_MAX, math.random())
                local vel = event.velocity * velScale + velRand
                track:addNote(event.step, pitch, event.length, vel)
            end
            table.insert(tracks, track)
        end
    end

    return tracks, channels
end

-- ===========================
-- MUSIC PLAYER
-- ===========================
function MusicPlayer()
    local MusicPlayer = {}
    function MusicPlayer.buildSequence(tracks, tempo)
        local sequence = sd.sequence.new()
        sequence:setTempo(tempo or TEMPO_NORMAL)
        for _, t in ipairs(tracks) do
            sequence:addTrack(t)
        end
        return sequence
    end
    return MusicPlayer
end

local mp = MusicPlayer()

-- ===========================
-- SONG BUILDERS
-- ===========================
local function buildOriginalSong(params)
    local drumTracks, drumChannels = buildSwingDrumTracks()
    for _, ch in pairs(drumChannels) do
        ch:setVolume(VOLUME_SWING_DRUMS)
    end

    local bassInstrument, bassChannel = createBassInstrument(
        params.bass_filter_cutoff,
        params.bass_filter_res
    )
    bassChannel:setVolume(VOLUME_BASS)

    local bassTrack = buildMelodicTrack(walking_bass, bassInstrument, 1.0, true, OCTAVE_BASS)

    local allTracks = {}
    for _, dt in ipairs(drumTracks) do table.insert(allTracks, dt) end
    table.insert(allTracks, bassTrack)

    local sequence = mp.buildSequence(allTracks, TEMPO_NORMAL)

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

    return sequence
end

local function buildSong1(params)
    local tracks = {}

    local bassInstrument, bassChannel = createBassInstrument(
        params.bass_filter_cutoff,
        params.bass_filter_res
    )
    bassChannel:setVolume(VOLUME_BASS)
    local bassTrack = buildMelodicTrack(hopping_bass, bassInstrument, 1.0, true, OCTAVE_BASS)
    table.insert(tracks, bassTrack)

    local drumTracks, _ = build909DrumTracks()
    for _, dt in ipairs(drumTracks) do table.insert(tracks, dt) end

    local vibraSynth = sd.synth.new(VIBRA_WAVE)
    vibraSynth:setADSR(VIBRA_ATTACK, VIBRA_DECAY, VIBRA_SUSTAIN, VIBRA_RELEASE)
    local vibratoLfo = sd.lfo.new(sd.kLFOSine)
    vibratoLfo:setRate(VIBRA_VIBRATO_RATE)
    vibratoLfo:setCenter(0)
    vibratoLfo:setDepth(VIBRA_VIBRATO_DEPTH)
    vibraSynth:setFrequencyMod(vibratoLfo)

    local vibraFilter = sd.twopolefilter.new("lowpass")
    vibraFilter:setFrequency(VIBRA_FILTER_FREQ)
    vibraFilter:setResonance(VIBRA_FILTER_RES)
    local vibraOD = sd.overdrive.new()
    vibraOD:setGain(2)
    local vibraChannel = sd.channel.new()
    local vibraInstrument = sd.instrument.new(vibraSynth)
    vibraChannel:addSource(vibraInstrument)
    vibraChannel:addEffect(vibraFilter)
    vibraChannel:addEffect(vibraOD)
    vibraChannel:setVolume(VOLUME_VIBRAPHONE)

    local leadTrack = buildMelodicTrack(lead_melody, vibraInstrument, 1.0, true, OCTAVE_VIBRAPHONE)
    table.insert(tracks, leadTrack)

    return mp.buildSequence(tracks, TEMPO_NORMAL)
end

local function buildSong2(params)
    local tracks = {}

    local bassInstrument, bassChannel = createBassInstrument(
        params.bass_filter_cutoff,
        params.bass_filter_res
    )
    bassChannel:setVolume(VOLUME_BASS)
    local bassTrack = buildMelodicTrack(hopping_bass, bassInstrument, 1.0, true, OCTAVE_BASS)
    table.insert(tracks, bassTrack)

    local drumTracks, _ = build909DrumTracks()
    for _, dt in ipairs(drumTracks) do table.insert(tracks, dt) end

    local HALF_LOOP = 1536

    local camelSynth = sd.synth.new(CAMEL_WAVE)
    camelSynth:setADSR(CAMEL_ATTACK, CAMEL_DECAY, CAMEL_SUSTAIN, CAMEL_RELEASE)

    local glide = sd.lfo.new(sd.kLFOSquare)
    glide:setRate(0.01)
    glide:setRetrigger(true)
    glide:setDelay(0, PORTAMENTO_TIME)
    glide:setCenter(-0.5)   -- fix: centre + depth = 0 → sweep lands on target pitch
    glide:setDepth(0.5)
    camelSynth:setFrequencyMod(glide)
    --camelSynth:setLegato(true)
    camelSynth:setParameter(1, 0.6)
    local camelLFO = sd.lfo.new(sd.kWaveSine)
    camelLFO:setRate(0.3)
    camelLFO:setCenter(0.5)
    camelLFO:setDepth(0.5)
    camelSynth:setParameterMod(1, camelLFO)
    local camelLFO2 = sd.lfo.new(sd.kLFOSampleAndHold)
    camelLFO2:setRate(1)
    camelLFO2:setCenter(0.5)
    camelLFO2:setDepth(0.22)
    camelSynth:setParameterMod(2, camelLFO2)

    local camelInstrument = sd.instrument.new(camelSynth)
    local camelChannel = sd.channel.new()
    local delay = sd.delayline.new(DELAY_TIME)
    delay:setFeedback(DELAY_FEEDBACK)
    delay:setMix(DELAY_MIX)

    local camelFilter = sd.twopolefilter.new('lowpass')
    camelFilter:setFrequency(6666)
    camelFilter:setResonance(0.4)
    camelChannel:addSource(camelInstrument)
    camelChannel:addEffect(camelFilter)
    camelChannel:addEffect(delay)
    camelChannel:setVolume(VOLUME_CAMEL_SLIDE)

    local camelTrack = sd.track.new()
    camelTrack:setInstrument(camelInstrument)
    for _, event in ipairs(camel_slide) do
        if event.step < HALF_LOOP then
            local pitch22 = event.note * (12 / 22) + TRANSPOSE + OCTAVE_CAMEL_SLIDE
            camelTrack:addNote(event.step, pitch22, event.length, event.velocity)
        end
    end
    table.insert(tracks, camelTrack)

    local skankInstrument = sd.instrument.new()
    for _ = 1, SKANK_VOICES do
        local voiceSynth = sd.synth.new(SKANK_WAVE)
        voiceSynth:setADSR(SKANK_ATTACK, SKANK_DECAY, SKANK_SUSTAIN, SKANK_RELEASE)

        local lfo1 = sd.lfo.new(sd.kLFOSampleAndHold)
        lfo1:setRate(SKANK_LFO_RATE)
        lfo1:setCenter(SKANK_LFO_CENTER)
        lfo1:setDepth(SKANK_LFO_DEPTH)
        lfo1:setRetrigger(true)
        voiceSynth:setParameterMod(1, lfo1)

        local lfo2 = sd.lfo.new(sd.kLFOSampleAndHold)
        lfo2:setRate(SKANK_LFO_RATE)
        lfo2:setCenter(SKANK_LFO_CENTER)
        lfo2:setDepth(SKANK_LFO_DEPTH)
        lfo2:setRetrigger(true)
        voiceSynth:setParameterMod(2, lfo2)

        skankInstrument:addVoice(voiceSynth)
    end

    local skankChannel = sd.channel.new()
    local skankOD = sd.overdrive.new()
    skankOD:setGain(2)
    skankChannel:addSource(skankInstrument)
    skankChannel:setVolume(VOLUME_SKANK)
    skankChannel:addEffect(skankOD)

    local skankTrack = sd.track.new()
    skankTrack:setInstrument(skankInstrument)
    for _, event in ipairs(skank) do
        local step = event.step + HALF_LOOP
        local pitch22 = event.note * (12 / 22) + TRANSPOSE + OCTAVE_SKANK
        skankTrack:addNote(step, pitch22, event.length, event.velocity)
    end
    table.insert(tracks, skankTrack)

    return mp.buildSequence(tracks, TEMPO_NORMAL)
end

local function buildSong3(params)
    local tracks = {}

    local drumTracks, drumChannels = buildSwingDrumTracks()
    for _, ch in pairs(drumChannels) do
        ch:setVolume(VOLUME_SWING_DRUMS)
    end
    for _, dt in ipairs(drumTracks) do table.insert(tracks, dt) end

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

    local bassInstrument, bassChannel = createBassInstrument(
        params.bass_filter_cutoff,
        params.bass_filter_res
    )
    bassChannel:setVolume(VOLUME_BASS)

    local SWING_LOOP_LENGTH = 6144
    local BLOCK = 3072
    local leadEvents = lead_melody

    local leadTrack = sd.track.new()
    leadTrack:setInstrument(bassInstrument)

    for copy = 0, 1 do
        local offset = copy * BLOCK
        for i, event in ipairs(leadEvents) do
            local step = event.step + offset
            local length = event.length
            if copy == 1 and i == #leadEvents then
                length = SWING_LOOP_LENGTH - step
            end
            local pitch22 = event.note * (12 / 22) + TRANSPOSE + OCTAVE_HALF_BASS
            leadTrack:addNote(step, pitch22, length, event.velocity)
        end
    end

    table.insert(tracks, leadTrack)

    return mp.buildSequence(tracks, TEMPO_HALF)
end

-- ===========================
-- SONG CONTROL
-- ===========================
local songBuilders = {buildOriginalSong, buildSong1, buildSong2, buildSong3}
local currentSongIndex = 1
local currentSequence = nil

local function stopCurrentSequence()
    if currentSequence then
        currentSequence:stop()
        currentSequence = nil
    end
end

local function startSong(index)
    stopCurrentSequence()
    local params = SONG_PARAMS[index]
    local sequence = songBuilders[index](params)
    sequence:setLoops(0)
    sequence:play()
    currentSequence = sequence
end

-- ===========================
-- MODULE WRAPPER
-- ===========================
local songPlayer = {}

local currentSequence = nil
songPlayer.currentSongIndex = 1

local function stopCurrentSequence()
    if currentSequence then
        currentSequence:stop()
        currentSequence = nil
    end
end

local function startSong(index)
    stopCurrentSequence()
    local params = SONG_PARAMS[index]
    local sequence = songBuilders[index](params)
    sequence:setLoops(0)
    sequence:play()
    currentSequence = sequence
end

-- Public API
function songPlayer.play(index)
    if index < 1 or index > #songBuilders then
        error("Song index out of range (1.." .. #songBuilders .. ")")
    end
    songPlayer.currentSongIndex = index
    startSong(index)
end

function songPlayer.stop()
    stopCurrentSequence()
end

function songPlayer.next()
    songPlayer.currentSongIndex = (songPlayer.currentSongIndex % #songBuilders) + 1
    startSong(songPlayer.currentSongIndex)
end
--[[
  === songPlayer API ===

  Usage:
    local sp = import "songPlayer"

    sp.play(index)   -- Play song (1-4). Stops whatever was playing.
    sp.stop()        -- Stop the current song.
    sp.next()        -- Switch to the next song (1→2→3→4→1…) and play it.
    sp.currentSongIndex  -- (read only) the index of the current/last played song.

  Example:
    sp.play(2)   -- start song 2
    sp.next()    -- switch to song 3

  Songs loop forever. Only one plays at a time.
]]
return songPlayer