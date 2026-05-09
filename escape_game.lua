import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/easing"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local bg = {
    gfx.image.new("images/escape_game/road_game_f1.png"),
    gfx.image.new("images/escape_game/road_game_f2.png"),
    gfx.image.new("images/escape_game/road_game_f3.png"),
    gfx.image.new("images/escape_game/road_game_f4.png")
}

local player = gfx.image.new("images/escape_game/road_game_player.png")
local car = gfx.image.new("images/escape_game/road_game_car.png")

local gameStart = 1
local framesBeforeGameStart = 40
local imageCounter = 1 
local frameCounter = 1
local carWiggle = 1 

local pX = 10
local pY = 75

local speed = 12
local cars = {}

-- timer
local timerLength = 5 -- seconds
local startTime = pd.getCurrentTimeMilliseconds()

local gameOver = false
local fail = false
local score = 0
local timeScore = 0

function timerLimit()
    local currentTime = pd.getCurrentTimeMilliseconds()
    local elapsedTime = (currentTime - startTime) / 1000

    local timeLeft = math.ceil(timerLength - elapsedTime)

    if timeLeft < 0 then
        timeLeft = 0
    end

    timeScore = timeLeft

    -- draw timer after background so it is visible
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Time Left: " .. timeLeft, 280, 10)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    if timeLeft <= 0 then
        fail = false
        gameOver = true
    end
end

function spawnCars()
    local tempLanes = {180, 100, 20}

    local lane1 = table.remove(tempLanes, math.random(#tempLanes))
    local lane2 = table.remove(tempLanes, math.random(#tempLanes))

    cars = {
        {x = 400, y = lane1},
        {x = 400, y = lane2}
    }
end

function checkCollision(carObj)
    local playerW, playerH = player:getSize()
    local carW, carH = car:getSize()

    if pX < carObj.x + carW and
       pX + (playerW - 175) > carObj.x and
       pY < carObj.y + (carH - 20) and
       pY + (playerH - 40) > carObj.y then

        fail = true
        gameOver = true
    end
end

function traffic(carObj)
    car:draw(carObj.x, carObj.y)
    carObj.x -= speed
    checkCollision(carObj)
end

function trafficTimer()
    local allGone = true

    for i = 1, #cars do
        traffic(cars[i])

        if cars[i].x > -100 then
            allGone = false
        end
    end

    if allGone then
        spawnCars()
    end
end

function animationPacing()
    if frameCounter == 2 then
        imageCounter += 1

        if imageCounter == 5 then
            imageCounter = 1
            pY = pY + carWiggle
            carWiggle = carWiggle * -1
        end

        frameCounter = 1
    else
        frameCounter += 1    
    end
end

spawnCars()

function playdate.update() 
    gfx.clear()

    bg[imageCounter]:draw(0, 0)


    if gameOver == true then
        gfx.clear()
        if fail then
            score = 0 + (timerLength - timeScore)
        else
            score = 5 + (timerLength - timeScore)
        end

        gfx.drawText("Score: " .. score, 150, 130)

        return score
    end

    timerLimit()
    
    local acceleratedChange = pd.getCrankChange()
    
    pY = pY + (acceleratedChange / 4)
    pY = math.max(-14, math.min(pY, 176))
    
    player:draw(pX, pY)

    animationPacing()

    if gameStart == framesBeforeGameStart then
        trafficTimer()
    else
        gameStart += 1
    end
end