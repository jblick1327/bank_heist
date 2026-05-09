-- Authors: Darryn, James, and Robert
-- Game: Bank Heist

import "CoreLibs/graphics"

--#region CONSTANTS AND VARIABLES

local pd <const> = playdate
local gfx <const> = playdate.graphics
local screenWidth <const> = 400
local screenHeight <const> = 240
local rand = math.random

local state = "title"
local score = 0
local highScore = 0

--#endregion

--#region LOADING IMAGES

-- Loading Font
local font = gfx.font.new("Nontendo/Nontendo-Bold-2x")
    assert(font, "Could not load Nontendo font")
gfx.setFont(font)

-- Loading Player images
local playerIdleImage = gfx.image.new("playerIdle_spr.pdi")
    assert(playerIdleImage, "Could not load player idle image")
local playerWalkImage = gfx.image.new("playerWalking_spr.pdi")
    assert(playerWalkImage, "Could not load player walk image")

-- Loading Title Screen Van
local vanSheet = gfx.image.new("titleVan_spr.pdi")
    assert(vanSheet, "Could not load van spritesheet")

-- Loading Cutscene images
local backgroundImage1 = gfx.image.new("cutScene1_spr.pdi")
    assert(backgroundImage1, "Could not load background image for cutscene 1")
local backgroundImage2 = gfx.image.new("cutScene2_spr.pdi")
    assert(backgroundImage2, "Could not load background image for cutscene 2")
local backgroundImage3 = gfx.image.new("cutScene3_spr.pdi")
    assert(backgroundImage3, "Could not load background image for cutscene 3")
local backgroundImage4 = gfx.image.new("cutScene4_spr.pdi")
    assert(backgroundImage4, "Could not load background image for cutscene 4")
local backgroundImage5 = gfx.image.new("cutScene5_spr.pdi")
    assert(backgroundImage5, "Could not load background image for cutscene 5")

-- Loading Cut the Glass mini-game images
local glassBackgroundImage = gfx.image.new("glass_game.pdi")
    assert(glassBackgroundImage, "Could not load background image for Cut the Glass mini-game")
local glassBrokenBackgroundImage = gfx.image.new("glass_game_fail.pdi")
    assert(glassBrokenBackgroundImage, "Could not load background image for Cut the Glass mini-game failure state")
local glassGameGloveImage = gfx.image.new("glass_game_glove.pdi")
    assert(glassGameGloveImage, "Could not load glove image for Cut the Glass mini-game")

-- Loading Tune the Radar mini-game images
local radarBackgroundImage = {
    gfx.image.new("radar_bg.pdi"),
    gfx.image.new("radar_bg2.pdi"),
    gfx.image.new("radar_bg3.pdi"),
}
    for i, img in ipairs(radarBackgroundImage) do
        assert(img, "Could not load background image for Tune the Radar mini-game frame " .. i)
    end
local radarWaveImage = {
    gfx.image.new("radar_waveform1.pdi"),
    gfx.image.new("radar_waveform2.pdi"),
    gfx.image.new("radar_waveform3.pdi"),
    gfx.image.new("radar_waveform_win.pdi")
}
    for i, img in ipairs(radarWaveImage) do
        assert(img, "Could not load wave image for Tune the Radar mini-game frame " .. i)
    end
local radarHandImage = gfx.image.new("radar_hand.pdi")
    assert(radarHandImage, "Could not load hand image for Tune the Radar mini-game")

-- Loading Rope Rappel mini-game images
local ropeRappelBackgroundImage = gfx.image.new("rappel_game.pdi")
    assert(ropeRappelBackgroundImage, "Could not load background image for Rope Rappel mini-game")
local ropeRappelPlayerImage = gfx.image.new("rappel_game_player.pdi")
    assert(ropeRappelPlayerImage, "Could not load player image for Rope Rappel mini-game")
local ropeRappelPlayerLoseImage = gfx.image.new("rappel_game_player_lose.pdi")
    assert(ropeRappelPlayerLoseImage, "Could not load player lose image for Rope Rappel mini-game")

-- Loading Crack the Lock mini-game images
local safeGameNoHandImage = gfx.image.new("safe_game_nohand.pdi")
    assert(safeGameNoHandImage, "Could not load background image for Crack the Lock mini-game")
local safeGameHand1Image = gfx.image.new("safe_game_handc.pdi")
    assert(safeGameHand1Image, "Could not load hand image 1 for Crack the Lock mini-game")
local safeGameHand2Image = gfx.image.new("safe_game_handcc.pdi")
    assert(safeGameHand2Image, "Could not load hand image 2 for Crack the Lock mini-game")
local safeGameWinImage = gfx.image.new("safe_game_win.pdi")
    assert(safeGameWinImage, "Could not load win image for Crack the Lock mini-game")

-- Loading Escape in the Van mini-game images
local roadBackgroundImage = {
    gfx.image.new("road_game_f1.pdi"),
    gfx.image.new("road_game_f2.pdi"),
    gfx.image.new("road_game_f3.pdi"),
    gfx.image.new("road_game_f4.pdi")
}
    for i, img in ipairs(roadBackgroundImage) do
        assert(img, "Could not load background image for Escape in the Van mini-game frame " .. i)
    end
local roadPlayerImage = gfx.image.new("road_game_player.pdi")
    assert(roadPlayerImage, "Could not load player image for Escape in the Van mini-game")
local carImage = gfx.image.new("road_game_car.pdi")
    assert(carImage, "Could not load car image for Escape in the Van mini-game")

-- Loading Level 1 - Outside Platformer images
local level1Part1BackgroundImage = gfx.image.new("level1part1_spr.pdi")
    assert(level1Part1BackgroundImage, "Could not load background image for Level 1 - Part 1")

--#endregion

--#region INITIALIZE IMAGE VARIABLES

-- Getting Image Sizes
local playerW, playerH = playerIdleImage:getSize()
local level1Part1BackgroundW, level1Part1BackgroundH = level1Part1BackgroundImage:getSize()

-- Title animation variables
local titleY = 54
local bottomY = 152
local titleAnimSpeed = 4
local vanX = screenWidth / 2 - 64
local vanSpeed = 4

-- Van animation variables
local vanFrameSize = 128
local vanTotalFrames = 4
local vanFrameCounter = 0
local vanFrameDelay = 5

-- Player animation variables
local playerFrameSize = 96
local playerIdleTotalFrames = 4
local playerWalkTotalFrames = 8
local playerIdleFrameCounter = 0
local playerWalkFrameCounter = 0
local playerIdleFrameDelay = 8
local playerWalkFrameDelay = 4
local playerAnimState = "idle"

-- Cutscene reveal variables
local cutsceneRevealWidth = 0
local cutsceneRevealSpeed = 24
local debugDrawLevel1Part1Collision = true

--#endregion

--#region GAME OBJECTS / LEVEL VARIABLES

local playerFootOffset = 12
local playerFootBoxOffsetX = 32
local playerFootBoxWidth = 32

local player = {
    x = 256,
    y = 544,
    width = playerW,
    height = playerH,
    speed = 3,
    footOffset = playerFootOffset,
    collisionHeight = playerH,
    drawOffsetY = playerFootOffset,
    footBoxOffsetX = playerFootBoxOffsetX,
    footBoxWidth = playerFootBoxWidth
}

local level1Part1 = {
    startX = 100,
    startY = 630,
    goalX = 834,
    floorY = 726,
    cameraX = 0,
    cameraY = 0,
    velocityX = 0,
    velocityY = 0,
    moveSpeed = 5,
    jumpSpeed = -9,
    gravity = 0.45,
    maxFallSpeed = 10,
    ladderProbeOffsetX = 36,
    ladderProbeWidth = 24,
    ladderClimbSpeed = 3,
    ladderCooldown = 0,
    skylightPaddingX = 24,
    skylightPaddingY = 28,
    completed = false,
    completionPrompt = false,
    onLadder = false,
    onPlatform = false,
    onPlatformType = nil,
    wasOnRoof = false,
    -- Geometry: platforms and interactive objects
    geometry = {
        { type = "ground", y = 726, x1 = 0, x2 = 1600 },
        { type = "ladder", topY = 279, bottomY = 726, x1 = 345, x2 = 413 },
        { type = "platform", y = 270, x1 = 270, x2 = 684, id = "roof1_lower" },
        { type = "platform", y = 231, x1 = 685, x2 = 722, id = "roof1_upper" },
        { type = "platform", y = 196, x1 = 868, x2 = 1095, id = "roof2_upper" },
        { type = "platform", y = 227, x1 = 1096, x2 = 1599, id = "roof2_lower" },
        { type = "skylight", y = 227, x1 = 1234, x2 = 1492, interactive = true }
    }
}

-- Rope Repel mini-game variables
local bgI = ropeRappelBackgroundImage
local rappelPlayerImage = ropeRappelPlayerImage
local playerLose = ropeRappelPlayerLoseImage
local pHeight = 8
local fallen = false
local level1Part4Won = false

-- Escape in the Van mini-game variables
local gameStart = 1
local framesBeforeGameStart = 40
local imageCounter = 1 
local frameCounter = 1
local carWiggle = 1
local pX = 10
local pY = 75
local speed = 12
local cars = {}
local gameOver = false
local level1Part7Won = false
local spawnCars

--#endregion

--#region SCENE RESET FUNCTIONS

local function resetTitleScene() -- Title scene reset
    titleY = 54
    bottomY = 152
    vanX = screenWidth / 2 - 64
    vanFrameCounter = 0
end

local function resetCutsceneReveal() -- Cutscene reveal reset
    cutsceneRevealWidth = 0
end

local function resetLevel1Part1() -- Side scrolling platformer 1 reset
    player.x = level1Part1.startX
    player.y = level1Part1.startY
    level1Part1.cameraX = 0
    level1Part1.cameraY = 0
    level1Part1.velocityX = 0
    level1Part1.velocityY = 0
    level1Part1.completed = false
    level1Part1.completionPrompt = false
    level1Part1.onLadder = false
    level1Part1.onPlatform = false
    level1Part1.onPlatformType = nil
    level1Part1.wasOnRoof = false
    level1Part1.ladderCooldown = 0
    playerAnimState = "idle"
    playerIdleFrameCounter = 0
    playerWalkFrameCounter = 0
end

local function resetLevel1Part4() -- Rope-repel mini-game reset
    pHeight = 8
    fallen = false
end

local function resetLevel1Part7() -- Escape in the Van mini-game reset
    gameStart = 1
    imageCounter = 1
    frameCounter = 1
    carWiggle = 1
    pX = 10
    pY = 75
    cars = {}
    gameOver = false
    level1Part7Won = false
    spawnCars()
end

--#endregion

--#region UTILITY FUNCTIONS

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    elseif value > maxValue then
        return maxValue
    end

    return value
end

-- Draws the text in "bold" and aligned
local function drawTextBoldAligned(text, x, y, alignment)
        gfx.drawTextAligned(text, x - .5, y, alignment);
        gfx.drawTextAligned(text, x + .5, y, alignment);
        gfx.drawTextAligned(text, x, y - .5, alignment);
        gfx.drawTextAligned(text, x, y + .5, alignment);
        gfx.drawTextAligned(text, x, y, alignment);
end

local function drawCutsceneReveal(image)
    local revealWidth = math.min(cutsceneRevealWidth, screenWidth)
    local revealX = math.floor((screenWidth - revealWidth) / 2)

    gfx.pushContext()
    gfx.setClipRect(revealX, 0, revealWidth, screenHeight)
    image:draw(0, 0)
    gfx.popContext()
end

local function drawSceneCard(body)
    drawTextBoldAligned(body, screenWidth / 2, 30, kTextAlignment.center)
    gfx.drawTextAligned("Press A to continue", screenWidth / 2, 190, kTextAlignment.center)
end

--#endregion

--#region SCENE MANAGEMENT

--#region Title Screen

local function drawTitle()
    drawTextBoldAligned("BANK HEIST", screenWidth / 2, titleY, kTextAlignment.center)
    gfx.drawTextAligned("Press A to start", screenWidth / 2, bottomY, kTextAlignment.center)

    -- Draw van animation from spritesheet
    local frameIndex = math.floor(vanFrameCounter / vanFrameDelay) % vanTotalFrames
    local frameX = frameIndex * vanFrameSize
    local frameY = 0
    gfx.pushContext()
    gfx.setClipRect(vanX, 50, vanFrameSize, vanFrameSize)
    vanSheet:draw(vanX - frameX, 50 - frameY)
    gfx.popContext()

end

--#endregion

--#region LEVEL 1 - INTRO

local function drawTextscene1() -- Text transition 1
    drawSceneCard("The crew is planning to pull off \nthe heist of the century...")
end
    
local function drawCutscene1() --Cutscene 1 -- Plotting
    drawCutsceneReveal(backgroundImage1)
end
    
local function drawTextscene2() -- Text transition 2
    drawSceneCard("The following night,\nthe crew park their van down the \nstreet from the bank.")
end

--#endregion

--#region LEVEL 1 - PART 1 - Outside Platformer

local function drawTextscene3() -- Text transition 3
    drawSceneCard("Goal:\nReach the skylight \n\nControls:\nD-Pad to Move  Jump: A\nLadder: A to climb  Interact: A")
end

local function updateLevel1Part1()
    if level1Part1.completed then
        level1Part1.velocityX = 0
        level1Part1.velocityY = 0
        return
    end

    if level1Part1.ladderCooldown > 0 then
        level1Part1.ladderCooldown = level1Part1.ladderCooldown - 1
    end

    local leftPressed = pd.buttonIsPressed(pd.kButtonLeft)
    local rightPressed = pd.buttonIsPressed(pd.kButtonRight)
    local upPressed = pd.buttonIsPressed(pd.kButtonUp)
    local downPressed = pd.buttonIsPressed(pd.kButtonDown)
    local moveDirection = 0

    -- Handle ladder climbing
    if level1Part1.onLadder then
        local function snapToNearbyPlatform()
            local footLeft = player.x + player.footBoxOffsetX
            local footRight = footLeft + player.footBoxWidth
            local playerBottom = player.y + player.collisionHeight
            local bestGeo = nil
            local bestDelta = nil
            local maxSnapDelta = 24

            for _, geo in ipairs(level1Part1.geometry) do
                if geo.type == "ground" or geo.type == "platform" then
                    if footRight > geo.x1 and footLeft < geo.x2 then
                        local delta = geo.y - playerBottom
                        if math.abs(delta) <= maxSnapDelta then
                            if bestDelta == nil or math.abs(delta) < math.abs(bestDelta) then
                                bestDelta = delta
                                bestGeo = geo
                            end
                        end
                    end
                end
            end

            if bestGeo ~= nil then
                player.y = bestGeo.y - player.collisionHeight
                level1Part1.onPlatform = true
                level1Part1.onPlatformType = bestGeo.id or "platform"
                return true
            end

            return false
        end

        local activeLadder = nil
        local ladderXPadding = 2
        for _, geo in ipairs(level1Part1.geometry) do
            if geo.type == "ladder" then
                local ladderLeft = geo.x1 - ladderXPadding
                local ladderRight = geo.x2 + ladderXPadding
                local probeLeft = player.x + level1Part1.ladderProbeOffsetX
                local probeRight = probeLeft + level1Part1.ladderProbeWidth
                if probeRight > ladderLeft and probeLeft < ladderRight then
                    activeLadder = geo
                    break
                end
            end
        end

        if activeLadder == nil then
            level1Part1.onLadder = false
        else
            local ladderCenter = (activeLadder.x1 + activeLadder.x2) / 2
            player.x = ladderCenter - level1Part1.ladderProbeOffsetX - (level1Part1.ladderProbeWidth / 2)
        end

        if pd.buttonJustPressed(pd.kButtonA) then
            level1Part1.onLadder = false
        elseif upPressed then
            level1Part1.velocityY = -level1Part1.ladderClimbSpeed
            playerAnimState = "walk"
        elseif downPressed then
            level1Part1.velocityY = level1Part1.ladderClimbSpeed
            playerAnimState = "walk"
        else
            level1Part1.velocityY = 0
            playerAnimState = "idle"
        end

        if level1Part1.onLadder and activeLadder ~= nil then
            player.y = player.y + level1Part1.velocityY
            local ladderTopPlayerY = activeLadder.topY - player.collisionHeight
            local ladderBottomPlayerY = activeLadder.bottomY - player.collisionHeight

            if player.y <= ladderTopPlayerY then
                player.y = ladderTopPlayerY
                level1Part1.onLadder = false
                level1Part1.velocityY = 0
                level1Part1.ladderCooldown = 6
                snapToNearbyPlatform()
            elseif player.y >= ladderBottomPlayerY then
                player.y = ladderBottomPlayerY
                level1Part1.onLadder = false
                level1Part1.velocityY = 0
                level1Part1.ladderCooldown = 6
                snapToNearbyPlatform()
            end

            -- While climbing, follow player vertically so they stay in view.
            local cameraMaxX = math.max(0, level1Part1BackgroundW - screenWidth)
            local cameraMaxY = math.max(0, level1Part1BackgroundH - screenHeight)
            level1Part1.cameraX = clamp(math.floor(player.x + player.width / 2 - screenWidth / 2), 0, cameraMaxX)
            level1Part1.cameraY = clamp(math.floor(player.y + player.height / 2 - screenHeight / 2), 0, cameraMaxY)
        end

        return
    end

    if leftPressed then
        moveDirection = moveDirection - 1
    end

    if rightPressed then
        moveDirection = moveDirection + 1
    end

    level1Part1.velocityX = moveDirection * level1Part1.moveSpeed

    -- Update player animation state based on movement
    if moveDirection == 0 then
        playerAnimState = "idle"
    else
        playerAnimState = "walk"
    end

    -- Update animation frame counters
    if playerAnimState == "idle" then
        playerIdleFrameCounter = playerIdleFrameCounter + 1
    else
        playerWalkFrameCounter = playerWalkFrameCounter + 1
    end

    -- Jumping and ladder entry - check for ladder collision FIRST
    local playerLeft = player.x
    local playerRight = player.x + player.width
    local playerTop = player.y
    local playerBottom = player.y + player.collisionHeight
    
    if (pd.buttonJustPressed(pd.kButtonA) or upPressed) and level1Part1.ladderCooldown == 0 then
        -- Check for ladder entry first (has priority)
        local onLadder = false
        local ladderXPadding = 2
        for _, geo in ipairs(level1Part1.geometry) do
            if geo.type == "ladder" then
                local ladderLeft = geo.x1 - ladderXPadding
                local ladderRight = geo.x2 + ladderXPadding
                local probeLeft = player.x + level1Part1.ladderProbeOffsetX
                local probeRight = probeLeft + level1Part1.ladderProbeWidth
                if probeRight > ladderLeft and probeLeft < ladderRight and playerBottom > geo.topY and playerTop < geo.bottomY then
                    level1Part1.onLadder = true
                    level1Part1.velocityY = 0
                    local ladderCenter = (geo.x1 + geo.x2) / 2
                    player.x = ladderCenter - level1Part1.ladderProbeOffsetX - (level1Part1.ladderProbeWidth / 2)
                    onLadder = true
                    break
                end
            end
        end
        -- Only jump if not on ladder and A was pressed
        if not onLadder and pd.buttonJustPressed(pd.kButtonA) and (level1Part1.onPlatform or player.y >= level1Part1.floorY - player.collisionHeight - 2) then
            level1Part1.velocityY = level1Part1.jumpSpeed
            level1Part1.onPlatform = false
        end
    end

    level1Part1.velocityY = math.min(level1Part1.velocityY + level1Part1.gravity, level1Part1.maxFallSpeed)

    local prevY = player.y
    local prevBottom = prevY + player.collisionHeight

    player.x = player.x + level1Part1.velocityX
    player.y = player.y + level1Part1.velocityY

    local minX = 0
    local maxX = level1Part1BackgroundW - player.width

    if player.x < minX then
        player.x = minX
    elseif player.x > maxX then
        player.x = maxX
    end

    -- bounds after movement for correct collision checks
    playerLeft = player.x
    playerRight = player.x + player.width
    playerTop = player.y
    playerBottom = player.y + player.collisionHeight
    local footLeft = player.x + player.footBoxOffsetX
    local footRight = footLeft + player.footBoxWidth

    -- Reset platform state before collision checks
    local prevOnPlatform = level1Part1.onPlatform
    local prevOnPlatformType = level1Part1.onPlatformType
    level1Part1.onPlatform = false
    level1Part1.onPlatformType = nil

    -- Check collisions with geometry (reuse playerLeft, playerRight, playerTop, playerBottom from above)
    for _, geo in ipairs(level1Part1.geometry) do
        if geo.type == "ground" or geo.type == "platform" then
            -- One-way platform: only collide when falling onto platform from above
            if level1Part1.velocityY > 0 and prevBottom <= geo.y and playerBottom >= geo.y and playerTop < geo.y + 5 then
                if footRight > geo.x1 and footLeft < geo.x2 then
                    player.y = geo.y - player.collisionHeight
                    level1Part1.velocityY = 0
                    level1Part1.onPlatform = true
                    level1Part1.onPlatformType = geo.id or "platform"
                    -- Track if player is on a roof (platforms with ids)
                    if geo.id and (string.find(geo.id, "roof") or geo.type == "platform") then
                        level1Part1.wasOnRoof = true
                    end
                end
            end
        elseif geo.type == "skylight" then
            -- Skylight interaction
            local skylightLeft = geo.x1 - level1Part1.skylightPaddingX
            local skylightRight = geo.x2 + level1Part1.skylightPaddingX
            local skylightTop = geo.y - level1Part1.skylightPaddingY
            local skylightBottom = geo.y + 20 + level1Part1.skylightPaddingY
            if footRight > skylightLeft and footLeft < skylightRight and playerBottom > skylightTop and playerTop < skylightBottom then
                if pd.buttonJustPressed(pd.kButtonA) then
                    level1Part1.completed = true
                    level1Part1.completionPrompt = true
                end
            end
        end
    end

    -- Death by falling off roof
    if level1Part1.wasOnRoof and not level1Part1.onPlatform then
        -- Check if player is hitting the ground after falling from a roof
        if player.y >= level1Part1.floorY - player.collisionHeight and level1Part1.velocityY > 0 then
            gameOver = true
            state = "level1failure"
            return
        end
    end

    local cameraMaxX = math.max(0, level1Part1BackgroundW - screenWidth)
    local cameraMaxY = math.max(0, level1Part1BackgroundH - screenHeight)
    level1Part1.cameraX = clamp(math.floor(player.x + player.width / 2 - screenWidth / 2), 0, cameraMaxX)
    level1Part1.cameraY = clamp(math.floor(player.y + player.height / 2 - screenHeight / 2), 0, cameraMaxY)
end

local function drawLevel1Part1()
    local backgroundDrawX = -level1Part1.cameraX
    local backgroundDrawY = -level1Part1.cameraY

    level1Part1BackgroundImage:draw(backgroundDrawX, backgroundDrawY)
    
    -- Draw player animation from spritesheet using screencoordinates
    local screenPlayerX = player.x - level1Part1.cameraX
    local screenPlayerY = player.y - level1Part1.cameraY + player.drawOffsetY

    local playerFrameIndex, totalFrames, playerSheet, frameDelay
    if playerAnimState == "idle" then
        totalFrames = playerIdleTotalFrames
        playerSheet = playerIdleImage
        playerFrameIndex = math.floor(playerIdleFrameCounter / playerIdleFrameDelay) % totalFrames
        frameDelay = playerIdleFrameDelay
    else
        totalFrames = playerWalkTotalFrames
        playerSheet = playerWalkImage
        playerFrameIndex = math.floor(playerWalkFrameCounter / playerWalkFrameDelay) % totalFrames
        frameDelay = playerWalkFrameDelay
    end

    local frameX = playerFrameIndex * playerFrameSize
    gfx.pushContext()
    gfx.setClipRect(screenPlayerX, screenPlayerY, playerFrameSize, playerFrameSize)
    playerSheet:draw(screenPlayerX - frameX, screenPlayerY)
    gfx.popContext()

    if level1Part1.completed then
        gfx.drawTextAligned("Press A to continue", screenWidth / 2, 20, kTextAlignment.center)
    end
end

--#endregion

--#region LEVEL 1 - PART 2 - Cut the Glass

local function drawTextscene4() -- Text transition 4
    drawSceneCard("Goal:\nCut a hole in the skylight \n\nControls:\nTurn the crank to cut")
end

local function drawLevel1Part2() -- Cut the Glass mini-game
    glassBackgroundImage:draw(0, 0)
    glassGameGloveImage:draw(200, 120)
end

local function drawTextscene5() -- Text transition 5
    drawSceneCard('\n"Alright, we have a way in.\n Time to deactivate \nthe security systems." ')
end

--#endregion

--#region LEVEL 1 - PART 3 - Tune the Radar

local function drawCutscene2() -- Cutscene 2 -- From within the van, the lookout talks over the walkie talkie
    drawCutsceneReveal(backgroundImage2)
end

local function drawLevel1Part3() -- Tune the Radar mini-game
    drawSceneCard("Tune the Radar mini-game")
end

local function drawTextscene6() -- Text transition 6
    drawSceneCard('"The security systems \nare deactivated,\n begin your descent." ')
end

--#endregion

--#region LEVEL 1 - PART 4 - Rope Rappel

local function drawCutscene3() -- Cutscene 3 -- Lowering the rope through the cut hole in the skylight
    drawCutsceneReveal(backgroundImage3)
end

local function drawTextscene7() -- Text transition 7
    drawSceneCard("Goal:\nRappel down into the bank \n\nControls:\nTurn the crank slow and \ncareful to descend")
end

local function updateLevel1Part4() -- Rope Rappel mini-game
    if fallen or level1Part4Won then
        return
end

local acceleratedChange = pd.getCrankChange()

    if acceleratedChange < 15 and pHeight < 175 and fallen == false then
        pHeight = pHeight + (acceleratedChange / 6)

    -- player wins
    elseif pHeight >= 175 then
        fallen = false
        level1Part4Won = true
        state = "textscene8"

    -- player loses
    else
        fallen = true
        state = "level1failure"
    end
end

local function drawLevel1Part4()
    bgI:draw(0, 0)

    if pHeight >= 175 then
        gfx.drawLine(303, 8, 303, 175)
        rappelPlayerImage:draw(283, 175)

    elseif fallen == true then
        gfx.drawLine(303, 8, 303, pHeight)
        playerLose:draw(260, 205)

    else
        gfx.drawLine(303, 8, 303, pHeight)
        gfx.drawLine(303, 8, 303, pHeight)
        rappelPlayerImage:draw(283, pHeight)
    end
end

--#endregion

--#region LEVEL 1 - PART 5 - Inside Platformer

local function drawTextscene8() -- Text transition 8
    drawSceneCard("Goal:\nGet to the vault in the bank \n\nControls:\nD-Pad to Move \nPress A to Jump")
end

local function drawLevel1Part5() -- Inside the bank, the player walks to the vault
    drawSceneCard("Inside the bank, the \nPlayer walks to the vault.")
end

--#endregion

--#region LEVEL 1 - PART 6 - Crack the Lock

local function drawTextscene9() -- Text transition 9
    drawSceneCard("Goal:\nCrack the lock on the vault \n\nControls:\n ???")
end

local function drawLevel1Part6() -- Crack the Lock mini-game
    drawSceneCard("Crack the Lock mini-game")
end

local function drawCutscene4() -- Cutscene 4 -- Inside the bank vault
    drawCutsceneReveal(backgroundImage4)
end

--#endregion

--#region LEVEL 1 - PART 7 - Escape!

local function drawTextscene10() -- Text transition 10
    drawSceneCard("Goal:\nEscape the heist in the van \n\nControls:\nD-Pad to Move")
end

spawnCars = function()
    local tempLanes = {180, 100, 20}

    local lane1 = table.remove(tempLanes, math.random(#tempLanes))
    local lane2 = table.remove(tempLanes, math.random(#tempLanes))

    cars = {
        {x = 400, y = lane1},
        {x = 400, y = lane2}
    }
end

local function checkCollision(carObj)
    local playerW, playerH = roadPlayerImage:getSize()
    local carW, carH = carImage:getSize()

    if pX < carObj.x + carW and
       pX + (playerW - 175) > carObj.x and
       pY < carObj.y + (carH - 20) and
       pY + (playerH - 40) > carObj.y then
        gameOver = true
        state = "level1failure"
    end
end

local function traffic(carObj)
    carImage:draw(carObj.x, carObj.y)
    carObj.x = carObj.x - speed
    checkCollision(carObj)
end

local function trafficTimer()
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

local function animationPacing()
    if frameCounter == 2 then
        imageCounter = imageCounter + 1

        if imageCounter == 5 then
            imageCounter = 1
            pY = pY + carWiggle
            carWiggle = carWiggle * -1
        end

        frameCounter = 1
    else
        frameCounter = frameCounter + 1
    end
end

local function updateLevel1Part7()
    if gameOver then
        return
    end

    local acceleratedChange = pd.getCrankChange()
    pY = pY + (acceleratedChange / 4)
    pY = math.max(-14, math.min(pY, 176))

    animationPacing()

    if gameStart == framesBeforeGameStart then
        trafficTimer()
    else
        gameStart = gameStart + 1
    end
end

local function drawLevel1Part7()
    roadBackgroundImage[imageCounter]:draw(0, 0)
    roadPlayerImage:draw(pX, pY)
end

local function drawCutscene5() -- Cutscene 5 -- Escaping in the van down the highway
    drawCutsceneReveal(backgroundImage5)
end

--#endregion

--#region LEVEL 1 - END 

local function drawLevel1Success() -- End of level 1 completed
    drawTextBoldAligned("Level 1 Complete!", screenWidth / 2, 54, kTextAlignment.center)
    gfx.drawTextAligned("Score: " .. score, screenWidth / 2, 92, kTextAlignment.center)
    gfx.drawTextAligned("Best: " .. highScore, screenWidth / 2, 112, kTextAlignment.center)
    gfx.drawTextAligned("Press A to play again", screenWidth / 2, 152, kTextAlignment.center)
end

local function drawLevel1Failure() -- End of level 1 failed
    drawTextBoldAligned("Level 1 Failed", screenWidth / 2, 54, kTextAlignment.center)
    gfx.drawTextAligned("Score: " .. score, screenWidth / 2, 92, kTextAlignment.center)
    gfx.drawTextAligned("Best: " .. highScore, screenWidth / 2, 112, kTextAlignment.center)
    gfx.drawTextAligned("Press A to try again", screenWidth / 2, 152, kTextAlignment.center)
end

--#endregion

--#endregion



function playdate.update()
    
    gfx.clear()

    -- Render Scenes and Levels based on current scene state

    ---- Title Screen ----
    if state == "title" then
        -- Van animation
    vanFrameCounter = vanFrameCounter + 1
        drawTitle()
    elseif state == "titleTransition" then
        -- Begin Animations 
        titleY = titleY - titleAnimSpeed
        bottomY = bottomY + titleAnimSpeed
        vanX = vanX + vanSpeed
        drawTitle()

        -- When Animation is complete, transition to cutscene 1
        if titleY < -60 and bottomY > screenHeight + 60 and vanX > screenWidth then
            resetTitleScene()
            resetCutsceneReveal()
            state = "textscene1"
        end

    ---- TEXT SCENES ----
    elseif state == "textscene1" then
        drawTextscene1() 
    elseif state == "textscene2" then
        drawTextscene2()
    elseif state == "textscene3" then
        drawTextscene3()
    elseif state == "textscene4" then
        drawTextscene4()
    elseif state == "textscene5" then
        drawTextscene5()
    elseif state == "textscene6" then
        drawTextscene6()
    elseif state == "textscene7" then
        drawTextscene7()
    elseif state == "textscene8" then
        drawTextscene8()
    elseif state == "textscene9" then
        drawTextscene9()
    elseif state == "textscene10" then
        drawTextscene10()

    ---- CUTSCENES ----
    elseif state == "cutscene1" then
        if cutsceneRevealWidth < screenWidth then
            cutsceneRevealWidth = math.min(screenWidth, cutsceneRevealWidth + cutsceneRevealSpeed)
        end
        drawCutscene1()
    elseif state == "cutscene2" then
        if cutsceneRevealWidth < screenWidth then
            cutsceneRevealWidth = math.min(screenWidth, cutsceneRevealWidth + cutsceneRevealSpeed)
        end
        drawCutscene2()
    elseif state == "cutscene3" then
        if cutsceneRevealWidth < screenWidth then
            cutsceneRevealWidth = math.min(screenWidth, cutsceneRevealWidth + cutsceneRevealSpeed)
        end
        drawCutscene3()
    elseif state == "cutscene4" then
        if cutsceneRevealWidth < screenWidth then
            cutsceneRevealWidth = math.min(screenWidth, cutsceneRevealWidth + cutsceneRevealSpeed)
        end
        drawCutscene4()
    elseif state == "cutscene5" then
        if cutsceneRevealWidth < screenWidth then
            cutsceneRevealWidth = math.min(screenWidth, cutsceneRevealWidth + cutsceneRevealSpeed)
        end
        drawCutscene5()

    ---- GAMEPLAY SCENES ----
    -- Outside Platformer
    elseif state == "level1part1" then
        updateLevel1Part1()
        drawLevel1Part1()

    -- Cut the Glass mini-game
    elseif state == "level1part2" then
        drawLevel1Part2()
     
    -- Tune the Radar mini-game
    elseif state == "level1part3" then
        drawLevel1Part3()

    -- Rope Rappel mini-game
    elseif state == "level1part4" then
        updateLevel1Part4()
        drawLevel1Part4()

    -- Inside Platformer
    elseif state == "level1part5" then
        drawLevel1Part5()

    -- Crack the Lock mini-game
    elseif state == "level1part6" then
        drawLevel1Part6()

    -- Drive the Van mini-game
    elseif state == "level1part7" then
        updateLevel1Part7()
        drawLevel1Part7()

    ---- Level 1 - Success ----
    elseif state == "level1success" then
        drawLevel1Success()

    ---- Level 1 - Failure ----
    elseif state == "level1failure" then
        drawLevel1Failure()

    end
end

function playdate.AButtonDown()
    
    ---- Title Screen ----
    if state == "title" then
        state = "titleTransition"
        resetTitleScene()

-- INTRO
    ---- Text Scene 1 ----
    elseif state == "textscene1" then
        state = "cutscene1"
        resetCutsceneReveal()

    ---- Cutscene 1 ----
    elseif state == "cutscene1" then
        state = "textscene2"

    ---- Text Scene 2 ----
    elseif state == "textscene2" then
        state = "textscene3"

-- PART 1
    ---- Text Scene 3 ----
    elseif state == "textscene3" then
        state = "level1part1"
        resetLevel1Part1()

    ---- Level 1 - Outside Platformer ----
    elseif state == "level1part1" then
        if level1Part1.completed then
            state = "textscene4"
        end

-- PART 2
    ---- Text Scene 4 ----
    elseif state == "textscene4" then
        state = "level1part2"

    ---- Level 1 - Cut the glass mini-game ----
    elseif state == "level1part2" then
        state = "textscene5"

    ---- Text Scene 5 ----
    elseif state == "textscene5" then
        state = "cutscene2"
        resetCutsceneReveal()

-- PART 3
    ---- Cutscene 2 ----
    elseif state == "cutscene2" then
        state = "level1part3"

    ---- Level 1 - Tune the Radar mini-game ----
    elseif state == "level1part3" then
        state = "textscene6"

    ---- Text Scene 6 ----
    elseif state == "textscene6" then
        state = "cutscene3"
        resetCutsceneReveal()

-- PART 4
    ---- Cutscene 3 ----
    elseif state == "cutscene3" then
        state = "textscene7"

    ---- Text Scene 7 ----
    elseif state == "textscene7" then
        state = "level1part4"
        resetLevel1Part4()

    ---- Level 1 - Rope Rappel mini-game ----
    elseif state == "level1part4" then
        if level1Part4Won then
            state = "textscene8"
        end

-- PART 5
    ---- Text Scene 8 ----
    elseif state == "textscene8" then
        state = "level1part5"

    ---- Level 1 - Inside Platformer ----
    elseif state == "level1part5" then
        state = "textscene9"

-- PART 6
    ---- Text Scene 9 ----
    elseif state == "textscene9" then
        state = "level1part6"

    ---- Level 1 - Crack the Lock mini-game ----
    elseif state == "level1part6" then
        state = "cutscene4"
        resetCutsceneReveal()

    ---- Cutscene 4 ----
    elseif state == "cutscene4" then
        state = "textscene10"

-- PART 7
    ---- Text Scene 10 ----
    elseif state == "textscene10" then
        state = "level1part7"
        resetLevel1Part7()

    ---- Level 1 - Part 7 ----
    elseif state == "level1part7" then
        state = "cutscene5"
        resetCutsceneReveal()

    ---- Cutscene 5 ----
    elseif state == "cutscene5" then
        state = "level1success"

    ---- Level 1 - Success / Failure ----
    elseif state == "level1success" or state == "level1failure" then
        if score > highScore then
            highScore = score
        end

        score = 0
        player.x = 256
        player.y = 544

        resetTitleScene()
        resetLevel1Part1()
        resetLevel1Part4()
        resetLevel1Part7()
        state = "title"
    end
end