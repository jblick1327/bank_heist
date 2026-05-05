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



function playdate.update() 
    gfx.clear()

    bgI:draw(0, 0)

    local acceleratedChange = pd.getCrankChange()
    

    if acceleratedChange < 15 and pHeight < 175 and fallen == false then
        pHeight = pHeight + (acceleratedChange/6)

        gfx.drawLine(303, 8, 303, pHeight)
        gfx.drawLine(303, 8, 303, pHeight)

        player:draw(283, pHeight)
    
    --player wins
    elseif pHeight >= 175 then
        gfx.drawLine(303, 8, 303, 175)

        player:draw(283, 175)
        fallen = false
    
    --player loses
    else
        gfx.drawLine(303, 8, 303, pHeight)
        playerLose:draw(260, 205)
        fallen = true
    end


end


