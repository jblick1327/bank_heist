import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/easing"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local bgI = gfx.image.new("images/rappel_game/rappel_game.png")
local player = gfx.image.new("images/rappel_game/rappel_game_player.png")
local playerLose = gfx.image.new("images/rappel_game/rappel_game_player_Lose.png")

local pHeight = 8
local fallen = false

-- timer
local timerLength = 10 -- seconds
local startTime = pd.getCurrentTimeMilliseconds()

local gameOver = false
local fail = false
local score = 0
local timeScore = 0

local wait = 30
local waitCounter = 0

function timerLimit()
    local currentTime = pd.getCurrentTimeMilliseconds()
    local elapsedTime = (currentTime - startTime) / 1000

    local timeLeft = math.ceil(timerLength - elapsedTime)

    if timeLeft < 0 then
        timeLeft = 0
    end

    timeScore = timeLeft

    
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Time: " .. timeLeft, 12, 190)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    if timeLeft <= 0 then
        fail = true
        gameOver = true
    end
end

function playdate.update() 
    gfx.clear()

    bgI:draw(0, 0)


    if gameOver == true then
        gfx.clear()

        if fail then
            score = 1
        else
            score = 5 + timeScore
        end

        gfx.drawText("Score: " .. score, 150, 130)

        return score
    end

    timerLimit()

    local acceleratedChange = pd.getCrankChange()

    -- player is safely rappelling
    if acceleratedChange < 15 and pHeight < 175 and fallen == false then
        pHeight = pHeight + (acceleratedChange / 6)

        gfx.drawLine(303, 8, 303, pHeight)
        player:draw(283, pHeight)

    -- player wins
    elseif pHeight >= 175 then
        gfx.drawLine(303, 8, 303, 175)
        player:draw(283, 175)

        fallen = false
        waitCounter += 1

        if waitCounter >= wait then
            fail = false
            gameOver = true
        end

    -- player loses
    else
        gfx.drawLine(303, 8, 303, pHeight)
        playerLose:draw(260, 205)

        fallen = true
        waitCounter += 1

        if waitCounter >= wait then
            fail = true
            gameOver = true
        end
    end
end