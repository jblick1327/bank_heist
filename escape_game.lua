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

local imageCounter = 1 
local frameCounter = 1
local carWiggle = 1 

local pX = 10
local pY = 75

local speed = 5
local cars = {}

local gameOver = false

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
       pX + (playerW-175) > carObj.x and
       pY < carObj.y + (carH-20) and
       pY + (playerH-40) > carObj.y then
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

        if cars[i].x > -120 then
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
        gfx.drawText("GAME OVER", 160, 110)
        
        return
    end
    
    local acceleratedChange = pd.getCrankChange()
    
    pY = pY + (acceleratedChange / 4)
    pY = math.max(-14, math.min(pY, 176))
    
    player:draw(pX, pY)

    animationPacing()
    trafficTimer()
end