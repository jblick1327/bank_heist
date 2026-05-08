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
local rNum = math.random(1, 10)
local onOff = false
local carX = 400
local speed = 2
local number = math.random(1, 3)

local cars = {
    {x=carX, y=180},
    {x=carX, y=100},
    {x=carX, y=20}
}

function trafficTimer()
    
    
    traffic(cars[number])
    
end

function traffic(carObj)
    if carObj.x > -120 then
        car:draw(carObj.x, carObj.y)
        carObj.x -= speed
    else
        carObj.x = 400
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

function playdate.update() 
    gfx.clear()

    bg[imageCounter]:draw(0, 0)
    
    local acceleratedChange = pd.getCrankChange()
    
    pY = pY + (acceleratedChange/4)
    pY = math.max(-14, math.min(pY, 176))
    
    player:draw(pX, pY)

    animationPacing()
    
    trafficTimer()
   
end


