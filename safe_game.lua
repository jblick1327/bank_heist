import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/easing"
import "CoreLibs/crank"


local pd <const> = playdate
local gfx <const> = playdate.graphics
local ps <const> = playdate.sound

pd.setCrankSoundsDisabled(true)

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

local bg_noHand = gfx.image.new("images/safe_game/safe_game_nohand.png")
local bg_HandC = gfx.image.new("images/safe_game/safe_game_handc.png")
local bg_HandCC = gfx.image.new("images/safe_game/safe_game_handcc.png")
local bg_HandC2 = gfx.image.new("images/safe_game/safe_game_handc2.png")
local bg_HandCC2 = gfx.image.new("images/safe_game/safe_game_handcc2.png")
local bg_Win = gfx.image.new("images/safe_game/safe_game_win.png")

local faceButton = {
    gfx.image.new("images/safe_game/a.png"),
    gfx.image.new("images/safe_game/b.png")
}
local dButton = {
    gfx.image.new("images/safe_game/left.png"),
    gfx.image.new("images/safe_game/up.png"),
    gfx.image.new("images/safe_game/right.png"),
    gfx.image.new("images/safe_game/down.png")
}
local arrow = {
    gfx.image.new("images/safe_game/c.png"),
    gfx.image.new("images/safe_game/cc.png")
}

local intro = 1
local introFrameCount = 30
local clockwise = true
local count = 0
local safeCracks = 0
local safeCracksToWin = 3


local spotRange = 5
local randomSpot = math.random((0 + spotRange), (359 - spotRange))
local spotHigh = randomSpot + spotRange
local spotLow = randomSpot - spotRange

local randomDirection = math.random(1, 4)
local direction = {
    playdate.kButtonLeft, playdate.kButtonUp, 
    playdate.kButtonRight, playdate.kButtonDown
}
local randomButton = math.random(1, 2)
local button = {
    playdate.kButtonA, playdate.kButtonB
}


local function randomBool()
    return math.random() < 0.5
end

local clockOrCounterClock = randomBool()

function turnKnobAnimation()
    local change, acceleratedChange = pd.getCrankChange()
    local absoluteChange = math.min(20, math.abs(change))
    local tickSpeed = math.max(2, 7 - (absoluteChange/4))

    if acceleratedChange > 0 then
        if count > tickSpeed then 
            local ticks = pd.getCrankTicks(20)
            if ticks ~= 0 then
                playTumblerClick()
            end
            bg_HandC2:draw(0, 0)
            count += 1
            if count >= (tickSpeed*2) then
                count = 0
            end
        else
            bg_HandC:draw(0, 0)
            count += 1
        end    
        clockwise = true

    elseif acceleratedChange < 0 then
        if count > tickSpeed then 
            local ticks = pd.getCrankTicks(20)
            if ticks ~= 0 then
                playTumblerClick()
            end
            bg_HandCC2:draw(0, 0)
            count += 1
            if count >= (tickSpeed*2) then
                count = 0
            end
        else
            bg_HandCC:draw(0, 0)
            count += 1
        end 
        clockwise = false 

    elseif clockwise then
        bg_HandC:draw(0, 0)
    elseif not clockwise then
        bg_HandCC:draw(0, 0)
    end
end

function pd.update() 
    gfx.clear()
    turnKnobAnimation()

    if intro ~= introFrameCount then
        bg_noHand:draw(0, 0)
        intro += 1
    end

    --for debug
    --gfx.clear()
    if clockOrCounterClock then
        arrow[1]:draw(0, 0)
    else
        arrow[2]:draw(0, 0)   
    end

    local crankPosition = playdate.getCrankPosition()

    if crankPosition >= spotLow and crankPosition <= spotHigh and clockOrCounterClock == clockwise then
        gfx.drawText("Click", 160, 170)
        dButton[randomDirection]:draw(255, 157)
        faceButton[randomButton]:draw(340, 170)

        if playdate.buttonJustPressed(direction[randomDirection]) 
        and playdate.buttonJustPressed(button[randomButton]) then
            clockOrCounterClock = not clockOrCounterClock

            randomDirection = math.random(1, 4)
            randomButton = math.random(1, 2)
            safeCracks += 1
        end
    end

    if safeCracks >= safeCracksToWin then
        gfx.clear()
        bg_Win:draw(0, 0)
        return
    
    end

     --for debug
    --gfx.drawText(crankPosition, 160, 110)
    --gfx.drawText(randomSpot, 160, 130)
    --gfx.drawText(tostring(clockOrCounterClock), 160, 150)
end


