import "CoreLibs/crank"
local ps = playdate.sound
playdate.setCrankSoundsDisabled(true)

local clickSynth = ps.synth.new(ps.kWaveNoise)
local clickDrive = ps.overdrive.new()
local clickFilter = ps.twopolefilter.new("bandpass")
local clickChannel = ps.channel.new()
clickChannel:addEffect(clickDrive)
clickChannel:addEffect(clickFilter)
clickChannel:addSource(clickSynth)


local function playTumblerClick()
    local pitch = math.random(2200,2400)
    local gain = 0.8 + math.random()
    clickDrive:setGain(gain)
    clickFilter:setFrequency(pitch)
    clickFilter:setResonance(0.85)
    local decay = math.random(14,20) / 1000
    clickSynth:setADSR(0, decay, 0, 0) 
    clickSynth:playNote(pitch, 0.7, decay)
end

function playdate.update()
    local ticks = playdate.getCrankTicks(20)
    if ticks ~= 0 then
        playTumblerClick()
    end
end
