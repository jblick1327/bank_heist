-- Authors: Darryn, James, and Robert
-- Game: Bank Heist

import "CoreLibs/graphics"


local GlassGameModule = import "minigames/glass_game"
local glassGameInstance = nil

local RadarGameModule = import "minigames/radar_game"
local radarGameInstance = nil

local RappelGameModule = import "minigames/rappel_game"
local rappelGameInstance = nil

local safeGame = import "minigames/safe_game"
local safeGameInstance = nil

local escapeGame = import "minigames/escape_game"
local escapeGameInstance = nil


--#region CONSTANTS AND VARIABLES

local pd <const> = playdate
local gfx <const> = playdate.graphics
local screenWidth <const> = 400
local screenHeight <const> = 240
local rand = math.random

local state = "credits"
local score = 0
local levels = {
    {
        title = "BANK HEIST",
        subtitle = "LEVEL 1",
        description = "Infiltrate the bank vault.",
        locked = false,
        highScore = 0
    },
    {
        title = "LEVEL 2",
        subtitle = "LOCKED",
        description = "More jobs coming soon.",
        locked = true,
        highScore = 0
    },
    {
        title = "LEVEL 3",
        subtitle = "LOCKED",
        description = "More jobs coming soon.",
        locked = true,
        highScore = 0
    },
    {
        title = "LEVEL 4",
        subtitle = "LOCKED",
        description = "More jobs coming soon.",
        locked = true,
        highScore = 0
    },
    {
        title = "LEVEL 5",
        subtitle = "LOCKED",
        description = "More jobs coming soon.",
        locked = true,
        highScore = 0
    }
}
local levelSelectIndex = 1
local levelSelectNextIndex = 1
local levelSelectSlideOffset = 0
local levelSelectSlideDirection = 0
local levelSelectSlideSpeed = 20
local levelLockedMessageTimer = 0
local levelLockedMessageDuration = 45

local creditsTimer = 0
local creditsBounceDuration = 90
local creditsFadeDuration = 60
local creditsBounceAmplitude = 6
local creditsBounceSpeed = 0.2

local menuPulse = 0
local menuPulseSpeed = creditsBounceSpeed
local menuBounceAmplitude = creditsBounceAmplitude

--#endregion

--#region LOADING IMAGES

-- Loading Font
local font = gfx.font.new("Nontendo/Nontendo-Bold-2x")
    assert(font, "Could not load Nontendo font")
gfx.setFont(font)

-- Loading Player images
local playerIdleImage = gfx.image.new("images/playerIdle_spr")
    assert(playerIdleImage, "Could not load player idle image")
local playerWalkImage = gfx.image.new("images/playerWalking_spr")
    assert(playerWalkImage, "Could not load player walk image")
 local playerIdleLImage = gfx.image.new("images/playerIdleL_spr")
    assert(playerIdleLImage, "Could not load player idle L image")
local playerWalkLImage = gfx.image.new("images/playerWalkingL_spr")
    assert(playerWalkLImage, "Could not load player walk L image")
local playerClimbImage = gfx.image.new("images/playerClimb_spr")
    assert(playerClimbImage, "Could not load player climb image")
local playerJumpImage = gfx.image.new("images/playerJump_spr")
    assert(playerJumpImage, "Could not load player jump image")
local playerJumpLImage = gfx.image.new("images/playerJumpL_spr")
    assert(playerJumpLImage, "Could not load player jump L image")
local playerFallImage = gfx.image.new("images/playerFall_spr")
    assert(playerFallImage, "Could not load player fall image")

-- Loading Title Screen Van
local vanSheet = gfx.image.new("images/titleVan_spr")
    assert(vanSheet, "Could not load van spritesheet")

-- Loading Menu and Level Select card images
local textCardBackgroundImage = gfx.image.new("images/textCardBackground_spr")
    assert(textCardBackgroundImage, "Could not load text card background image")
local lockedLevelCardImage = gfx.image.new("images/lockedLevelCard_spr")
    assert(lockedLevelCardImage, "Could not load locked level card image")

-- Loading Cutscene images
local backgroundImage1 = gfx.image.new("images/cutScene1_spr")
    assert(backgroundImage1, "Could not load background image for cutscene 1")
local backgroundImage2 = gfx.image.new("images/cutScene2_spr")
    assert(backgroundImage2, "Could not load background image for cutscene 2")
local backgroundImage3 = gfx.image.new("images/cutScene3_spr")
    assert(backgroundImage3, "Could not load background image for cutscene 3")
local backgroundImage4 = gfx.image.new("images/cutScene4_spr")
    assert(backgroundImage4, "Could not load background image for cutscene 4")
local backgroundImage5 = gfx.image.new("images/cutScene5_spr")
    assert(backgroundImage5, "Could not load background image for cutscene 5")

-- Loading Level 1 - Outside Platformer images
local level1Part1BackgroundImage = gfx.image.new("images/level1part1_spr")
    assert(level1Part1BackgroundImage, "Could not load background image for Level 1 - Part 1")

-- Loading Level 1 - Inside Platformer images
local level1Part5BackgroundImage = gfx.image.new("images/level1part5_spr")
    assert(level1Part5BackgroundImage, "Could not load background image for Level 1 - Part 5")

--#endregion

--#region INITIALIZE IMAGE VARIABLES

-- Getting Image Sizes
local playerW, playerH = playerIdleImage:getSize()
local level1Part1BackgroundW, level1Part1BackgroundH = level1Part1BackgroundImage:getSize()
local level1Part5BackgroundW, level1Part5BackgroundH = level1Part5BackgroundImage:getSize()
local level1Part5WorldW = 1200
local level1Part5WorldH = 600

-- Title animation variables
local titleCardVanX = screenWidth / 2 - 64
local titleCardVanY = 50
local levelCardTitleY = 54
local levelCardBottomY = 152
local titleY = levelCardTitleY
local bottomY = levelCardBottomY
local titleAnimSpeed = 4
local vanX = titleCardVanX
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
local playerClimbImageW = playerClimbImage:getSize()
local playerJumpImageW = playerJumpImage:getSize()
local playerFallImageW = playerFallImage:getSize()
local playerClimbTotalFrames = math.max(1, math.floor(playerClimbImageW / playerFrameSize))
local playerJumpTotalFrames = math.max(1, math.floor(playerJumpImageW / playerFrameSize))
local playerFallTotalFrames = math.max(1, math.floor(playerFallImageW / playerFrameSize))
local playerClimbFrameCounter = 0
local playerJumpFrameCounter = 0
local playerFallFrameCounter = 0
local playerClimbFrameDelay = 6
local playerJumpFrameDelay = 4
local playerFallFrameDelay = 6
local playerAnimState = "idle"
local playerFacing = "right"

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
    width = playerFrameSize,
    height = playerFrameSize,
    speed = 3,
    footOffset = playerFootOffset,
    collisionHeight = playerFrameSize,
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
    deathTimer = 0,
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

local level1Part5 = {
    startX = 100,
    startY = 500 - player.collisionHeight,
    floorY = 500,
    cameraX = 0,
    cameraY = 0,
    velocityX = 0,
    velocityY = 0,
    moveSpeed = 5,
    jumpSpeed = -9,
    gravity = 0.45,
    maxFallSpeed = 10,
    vaultX = 1150,
    vaultHalfWidth = 40,
    vaultHeight = 160,
    vaultPaddingX = 12,
    vaultPaddingY = 12,
    completed = false,
    completionPrompt = false,
    onPlatform = false,
    geometry = {
        { type = "ground", y = 500, x1 = 0, x2 = level1Part5WorldW }
    }
}

--#endregion

--#region SCENE RESET FUNCTIONS

local function resetTitleScene() -- Title scene reset
    titleY = levelCardTitleY
    bottomY = levelCardBottomY
    vanX = titleCardVanX
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
    level1Part1.deathTimer = 0
    level1Part1.ladderCooldown = 0
    playerAnimState = "idle"
    playerIdleFrameCounter = 0
    playerWalkFrameCounter = 0
    playerClimbFrameCounter = 0
    playerJumpFrameCounter = 0
    playerFallFrameCounter = 0
    playerFacing = "right"
end


local function resetLevel1Part5() -- Side scrolling platformer 2 reset
    player.x = level1Part5.startX
    player.y = level1Part5.startY
    level1Part5.cameraX = 0
    level1Part5.cameraY = 0
    level1Part5.velocityX = 0
    level1Part5.velocityY = 0
    level1Part5.completed = false
    level1Part5.completionPrompt = false
    level1Part5.onPlatform = false
    playerAnimState = "idle"
    playerIdleFrameCounter = 0
    playerWalkFrameCounter = 0
    playerClimbFrameCounter = 0
    playerJumpFrameCounter = 0
    playerFallFrameCounter = 0
    playerFacing = "right"
end

local function resetLevel1Part7() -- Escape in the Van mini-game reset
    escapeGame.reset()
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
    textCardBackgroundImage:draw(0, 0)
    drawTextBoldAligned(body, screenWidth / 2, 30, kTextAlignment.center)
    gfx.drawTextAligned("Press A to continue", screenWidth / 2, 210, kTextAlignment.center)
end

--#endregion

--#region SCENE MANAGEMENT

--#region FRONT END SCENES

local function updateVanAnimation()
    vanFrameCounter = vanFrameCounter + 1
end

local function drawVanAt(drawX, drawY)
    local frameIndex = math.floor(vanFrameCounter / vanFrameDelay) % vanTotalFrames
    local frameX = frameIndex * vanFrameSize
    gfx.pushContext()
    gfx.setClipRect(drawX, drawY, vanFrameSize, vanFrameSize)
    vanSheet:draw(drawX - frameX, drawY)
    gfx.popContext()
end

local function drawTitleCard(xOffset, titleTextY, promptTextY, showPrompt, useAnimatedVan)
    drawTextBoldAligned("BANK HEIST", screenWidth / 2 + xOffset, titleTextY, kTextAlignment.center)
    if showPrompt then
        gfx.drawTextAligned("Press A to start", screenWidth / 2 + xOffset, promptTextY, kTextAlignment.center)
    end

    local vanDrawX = useAnimatedVan and vanX or titleCardVanX
    drawVanAt(vanDrawX + xOffset, titleCardVanY)
end

local function resetCredits()
    creditsTimer = 0
end

local function resetMenu()
    menuPulse = 0
end

local function resetLevelSelect()
    levelSelectIndex = 1
    levelSelectNextIndex = 1
    levelSelectSlideOffset = 0
    levelSelectSlideDirection = 0
    levelLockedMessageTimer = 0
end

local function updateCredits()
    creditsTimer = creditsTimer + 1
    if creditsTimer >= creditsBounceDuration + creditsFadeDuration then
        resetMenu()
        state = "menu"
    end
end

local function drawCredits()
    local bounceOffset = 0
    if creditsTimer <= creditsBounceDuration then
        bounceOffset = math.sin(creditsTimer * creditsBounceSpeed) * creditsBounceAmplitude
    end

    local fadeAlpha = 1
    if creditsTimer > creditsBounceDuration then
        local fadeProgress = (creditsTimer - creditsBounceDuration) / creditsFadeDuration
        fadeAlpha = math.max(0, 1 - fadeProgress)
    end

    gfx.setDitherPattern(fadeAlpha, gfx.image.kDitherTypeBayer8x8)
    drawTextBoldAligned("A Playdate game by\nDarryn, James, and Robert", screenWidth / 2, 90 + bounceOffset, kTextAlignment.center)
    gfx.setDitherPattern(1, gfx.image.kDitherTypeBayer8x8)
end

local function updateMenu()
    menuPulse = menuPulse + menuPulseSpeed
end

local function drawMenu()
    drawTextBoldAligned("SMASH N' GRAB", screenWidth / 2, 70, kTextAlignment.center)
    local bounceOffset = math.sin(menuPulse) * menuBounceAmplitude
    gfx.drawTextAligned("Press A to start", screenWidth / 2, 150 + bounceOffset, kTextAlignment.center)
end

local function drawLevelCard(levelIndex, offsetX)
    local level = levels[levelIndex]

    if level.locked then
        lockedLevelCardImage:draw(offsetX, 0)
        drawTextBoldAligned(level.title, screenWidth / 2 + offsetX, 60, kTextAlignment.center)
        gfx.drawTextAligned(level.subtitle, screenWidth / 2 + offsetX, 190, kTextAlignment.center)
    else
        drawTitleCard(offsetX, levelCardTitleY, levelCardBottomY, false, false)
        gfx.drawTextAligned(level.subtitle, screenWidth / 2 + offsetX, 190, kTextAlignment.center)
    end
end

local function drawOverlayBox(text, y)
    local boxX = 20
    local boxW = screenWidth - 40
    local boxH = 50
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(boxX, y, boxW, boxH)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(boxX, y, boxW, boxH)
    gfx.drawTextAligned(text, screenWidth / 2, y + 16, kTextAlignment.center)
end

local function drawLevelSelectHints()
    gfx.drawTextAligned("< Levels >", 20, 210, kTextAlignment.left)
    gfx.drawTextAligned("^ Info ^", screenWidth - 20, 210, kTextAlignment.right)
end

local function drawLevelSelectOverlays(levelIndex)
    local level = levels[levelIndex]
    local upPressed = pd.buttonIsPressed(pd.kButtonUp)
    local downPressed = pd.buttonIsPressed(pd.kButtonDown)

    if levelLockedMessageTimer > 0 then
        drawOverlayBox("Locked", 170)
    elseif upPressed then
        drawOverlayBox(level.description, 20)
    elseif downPressed then
        local bestText = "High Score: " .. tostring(level.highScore)
        if level.locked then
            bestText = "High Score: --"
        end
        drawOverlayBox(bestText, 170)
    end
end



local function updateLevelSelect()
    levelLockedMessageTimer = math.max(0, levelLockedMessageTimer - 1)

    if pd.buttonJustPressed(pd.kButtonLeft) and levelSelectIndex > 1 then
        levelLockedMessageTimer = 0
        levelSelectNextIndex = levelSelectIndex - 1
        levelSelectSlideDirection = 1
        levelSelectSlideOffset = 0
        state = "levelselectTransition"
    elseif pd.buttonJustPressed(pd.kButtonRight) and levelSelectIndex < #levels then
        levelLockedMessageTimer = 0
        levelSelectNextIndex = levelSelectIndex + 1
        levelSelectSlideDirection = -1
        levelSelectSlideOffset = 0
        state = "levelselectTransition"
    end

    updateVanAnimation()
end

local function drawLevelSelect()
    drawLevelCard(levelSelectIndex, 0)
    drawLevelSelectHints()
    drawLevelSelectOverlays(levelSelectIndex)
end

local function updateLevelSelectTransition()
    levelSelectSlideOffset = levelSelectSlideOffset + levelSelectSlideSpeed * levelSelectSlideDirection

    if math.abs(levelSelectSlideOffset) >= screenWidth then
        levelSelectIndex = levelSelectNextIndex
        levelSelectSlideOffset = 0
        levelSelectSlideDirection = 0
        state = "levelselect"
    end

    updateVanAnimation()
end

local function drawLevelSelectTransition()
    drawLevelCard(levelSelectIndex, levelSelectSlideOffset)
    drawLevelCard(levelSelectNextIndex, levelSelectSlideOffset - (levelSelectSlideDirection * screenWidth))
    drawLevelSelectHints()
    drawLevelSelectOverlays(levelSelectIndex)
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
    drawSceneCard("Goal:\nReach the skylight \n\nControls:\nD-Pad to Move  Jump: A\nLadder: UP to climb  Interact: A")
end

local function setPlayerAnimState(nextState)
    if playerAnimState == nextState then
        return
    end

    playerAnimState = nextState

    if nextState == "idle" then
        playerIdleFrameCounter = 0
    elseif nextState == "walk" then
        playerWalkFrameCounter = 0
    elseif nextState == "climb" then
        playerClimbFrameCounter = 0
    elseif nextState == "jump" then
        playerJumpFrameCounter = 0
    elseif nextState == "fall" then
        playerFallFrameCounter = 0
    end
end

local function updateLevel1Part1()
    level1Part1.completionPrompt = false
    if level1Part1.completed then
        level1Part1.velocityX = 0
        level1Part1.velocityY = 0
        return
    end

    if level1Part1.deathTimer > 0 then
        level1Part1.deathTimer = level1Part1.deathTimer - 1
        level1Part1.velocityX = 0
        level1Part1.velocityY = 0
        setPlayerAnimState("fall")
        playerFallFrameCounter = playerFallFrameCounter + 1
        if level1Part1.deathTimer == 0 then
            state = "level1failure"
        end
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
                if bestGeo.id and string.find(bestGeo.id, "roof") then
                    level1Part1.wasOnRoof = true
                else
                    level1Part1.wasOnRoof = false
                end
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
        elseif downPressed then
            level1Part1.velocityY = level1Part1.ladderClimbSpeed
        else
            level1Part1.velocityY = 0
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

        if level1Part1.onLadder then
            setPlayerAnimState("climb")
            if level1Part1.velocityY ~= 0 then
                playerClimbFrameCounter = playerClimbFrameCounter + 1
            end
        end

        return
    end

    if leftPressed then
        moveDirection = moveDirection - 1
    end

    if rightPressed then
        moveDirection = moveDirection + 1
    end

    if moveDirection < 0 then
        playerFacing = "left"
    elseif moveDirection > 0 then
        playerFacing = "right"
    end

    level1Part1.velocityX = moveDirection * level1Part1.moveSpeed

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
    local prevWasOnRoof = level1Part1.wasOnRoof
    local landedOnGround = false

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
                    if geo.type == "ground" then
                        landedOnGround = true
                        level1Part1.wasOnRoof = false
                    elseif geo.id and string.find(geo.id, "roof") then
                        level1Part1.wasOnRoof = true
                    else
                        level1Part1.wasOnRoof = false
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
                level1Part1.completionPrompt = true
                if pd.buttonJustPressed(pd.kButtonA) then
                    level1Part1.completed = true
                    state = "textscene4"
                    return
                end
            end
        end
    end

    -- Death by falling off roof
    if prevWasOnRoof and landedOnGround then
        gameOver = true
        level1Part1.deathTimer = 20
        level1Part1.velocityX = 0
        level1Part1.velocityY = 0
        setPlayerAnimState("fall")
        playerFallFrameCounter = 0
        return
    end

    if not level1Part1.onPlatform then
        setPlayerAnimState("jump")
        playerJumpFrameCounter = playerJumpFrameCounter + 1
    else
        if moveDirection == 0 then
            setPlayerAnimState("idle")
            playerIdleFrameCounter = playerIdleFrameCounter + 1
        else
            setPlayerAnimState("walk")
            playerWalkFrameCounter = playerWalkFrameCounter + 1
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

    local playerFrameIndex = 0
    local totalFrames = 1
    local playerSheet = playerIdleImage
    local frameDelay = 1
    local frameCounter = 0
    local loopFrames = true
    if playerAnimState == "idle" then
        totalFrames = playerIdleTotalFrames
        frameDelay = playerIdleFrameDelay
        frameCounter = playerIdleFrameCounter
        if playerFacing == "left" then
            playerSheet = playerIdleLImage
        else
            playerSheet = playerIdleImage
        end
    elseif playerAnimState == "walk" then
        totalFrames = playerWalkTotalFrames
        frameDelay = playerWalkFrameDelay
        frameCounter = playerWalkFrameCounter
        if playerFacing == "left" then
            playerSheet = playerWalkLImage
        else
            playerSheet = playerWalkImage
        end
    elseif playerAnimState == "climb" then
        totalFrames = playerClimbTotalFrames
        frameDelay = playerClimbFrameDelay
        frameCounter = playerClimbFrameCounter
        playerSheet = playerClimbImage
    elseif playerAnimState == "jump" then
        totalFrames = playerJumpTotalFrames
        frameDelay = playerJumpFrameDelay
        frameCounter = playerJumpFrameCounter
        loopFrames = false
        if playerFacing == "left" then
            playerSheet = playerJumpLImage
        else
            playerSheet = playerJumpImage
        end
    elseif playerAnimState == "fall" then
        totalFrames = playerFallTotalFrames
        frameDelay = playerFallFrameDelay
        frameCounter = playerFallFrameCounter
        loopFrames = false
        playerSheet = playerFallImage
    end

    if loopFrames then
        playerFrameIndex = math.floor(frameCounter / frameDelay) % totalFrames
    else
        playerFrameIndex = math.min(math.floor(frameCounter / frameDelay), totalFrames - 1)
    end

    local frameX = playerFrameIndex * playerFrameSize
    gfx.pushContext()
    gfx.setClipRect(screenPlayerX, screenPlayerY, playerFrameSize, playerFrameSize)
    playerSheet:draw(screenPlayerX - frameX, screenPlayerY)
    gfx.popContext()

    if level1Part1.completionPrompt then
        drawOverlayBox("Press A", 170)
    end

end

--#endregion

--#region LEVEL 1 - PART 2 - Cut the Glass

local function drawTextscene4() -- Text transition 4
    drawSceneCard("Goal:\nCut a hole in the skylight \n\nControls:\nCrank \nCut percisely in fulid motion")
end

-- Cut the Glass mini-game

local function drawTextscene5() -- Text transition 5
    drawSceneCard('\n"Alright, we have a way in.\n Time to deactivate \nthe security systems."')
end

--#endregion

--#region LEVEL 1 - PART 3 - Tune the Radar

local function drawCutscene2() -- Cutscene 2 -- From within the van, the lookout talks over the walkie talkie
    drawCutsceneReveal(backgroundImage2)
end

local function drawTextscene51() -- Text transition 4
    drawSceneCard("Goal:\nTune the radar \n\nControls:\nCrank and D-pad UP and Down \nLine up the signals")
end


-- Tune the Radar mini-game

local function drawTextscene6() -- Text transition 6
    drawSceneCard('"The security systems \nare deactivated,\n begin your descent." ')
end

--#endregion

--#region LEVEL 1 - PART 4 - Rope Rappel

local function drawCutscene3() -- Cutscene 3 -- Lowering the rope through the cut hole in the skylight
    drawCutsceneReveal(backgroundImage3)
end

local function drawTextscene7() -- Text transition 7
    drawSceneCard("Goal:\nRappel down into the bank \n\nControls:\nCrank \nSlow and carefully descend")
end

-- Rope Rappel mini-game

--#endregion

--#region LEVEL 1 - PART 5 - Inside Platformer

local function drawTextscene8() -- Text transition 8
    drawSceneCard("Goal:\nGet to the vault in the bank \n\nControls:\nD-Pad to Move \nPress A to Jump")
end

local function updateLevel1Part5() -- Inside the bank platformer
    level1Part5.completionPrompt = false
    if level1Part5.completed then
        level1Part5.velocityX = 0
        level1Part5.velocityY = 0
        return
    end

    local leftPressed = pd.buttonIsPressed(pd.kButtonLeft)
    local rightPressed = pd.buttonIsPressed(pd.kButtonRight)
    local moveDirection = 0

    if leftPressed then
        moveDirection = moveDirection - 1
    end

    if rightPressed then
        moveDirection = moveDirection + 1
    end

    if moveDirection < 0 then
        playerFacing = "left"
    elseif moveDirection > 0 then
        playerFacing = "right"
    end

    level1Part5.velocityX = moveDirection * level1Part5.moveSpeed

    if pd.buttonJustPressed(pd.kButtonA) and level1Part5.onPlatform then
        level1Part5.velocityY = level1Part5.jumpSpeed
        level1Part5.onPlatform = false
    end

    level1Part5.velocityY = math.min(level1Part5.velocityY + level1Part5.gravity, level1Part5.maxFallSpeed)

    local prevY = player.y
    local prevBottom = prevY + player.collisionHeight

    player.x = player.x + level1Part5.velocityX
    player.y = player.y + level1Part5.velocityY

    local minX = 0
    local playerClampW = playerFrameSize
    local maxX = level1Part5WorldW - playerClampW

    if player.x < minX then
        player.x = minX
    elseif player.x > maxX then
        player.x = maxX
    end

    local playerTop = player.y
    local playerBottom = player.y + player.collisionHeight
    local footLeft = player.x + player.footBoxOffsetX
    local footRight = footLeft + player.footBoxWidth

    level1Part5.onPlatform = false

    for _, geo in ipairs(level1Part5.geometry) do
        if geo.type == "ground" then
            if level1Part5.velocityY >= 0 and prevBottom <= geo.y and playerBottom >= geo.y then
                if footRight > geo.x1 and footLeft < geo.x2 then
                    player.y = geo.y - player.collisionHeight
                    level1Part5.velocityY = 0
                    level1Part5.onPlatform = true
                end
            end
        end
    end

    local vaultLeft = level1Part5.vaultX - level1Part5.vaultHalfWidth - level1Part5.vaultPaddingX
    local vaultRight = level1Part5.vaultX + level1Part5.vaultHalfWidth + level1Part5.vaultPaddingX
    local vaultTop = level1Part5.floorY - level1Part5.vaultHeight - level1Part5.vaultPaddingY
    local vaultBottom = level1Part5.floorY + level1Part5.vaultPaddingY

    if footRight > vaultLeft and footLeft < vaultRight and playerBottom > vaultTop and playerTop < vaultBottom then
        level1Part5.completionPrompt = true
        if pd.buttonJustPressed(pd.kButtonA) then
            level1Part5.completed = true
            state = "textscene9"
            return
        end
    end

    if not level1Part5.onPlatform then
        setPlayerAnimState("jump")
        playerJumpFrameCounter = playerJumpFrameCounter + 1
    else
        if moveDirection == 0 then
            setPlayerAnimState("idle")
            playerIdleFrameCounter = playerIdleFrameCounter + 1
        else
            setPlayerAnimState("walk")
            playerWalkFrameCounter = playerWalkFrameCounter + 1
        end
    end

    local cameraMaxX = math.max(0, level1Part5WorldW - screenWidth)
    local cameraMaxY = math.max(0, level1Part5WorldH - screenHeight)
    level1Part5.cameraX = clamp(math.floor(player.x + playerClampW / 2 - screenWidth / 2), 0, cameraMaxX)
    level1Part5.cameraY = clamp(math.floor(player.y + player.height / 2 - screenHeight / 2), 0, cameraMaxY)
end

local function drawLevel1Part5() -- Inside the bank, the player walks to the vault
    local backgroundDrawX = -level1Part5.cameraX
    local backgroundDrawY = -level1Part5.cameraY

    level1Part5BackgroundImage:draw(backgroundDrawX, backgroundDrawY)

    local screenPlayerX = player.x - level1Part5.cameraX
    local screenPlayerY = player.y - level1Part5.cameraY + player.drawOffsetY

    local playerFrameIndex = 0
    local totalFrames = 1
    local playerSheet = playerIdleImage
    local frameDelay = 1
    local frameCounter = 0
    local loopFrames = true
    if playerAnimState == "idle" then
        totalFrames = playerIdleTotalFrames
        frameDelay = playerIdleFrameDelay
        frameCounter = playerIdleFrameCounter
        if playerFacing == "left" then
            playerSheet = playerIdleLImage
        else
            playerSheet = playerIdleImage
        end
    elseif playerAnimState == "walk" then
        totalFrames = playerWalkTotalFrames
        frameDelay = playerWalkFrameDelay
        frameCounter = playerWalkFrameCounter
        if playerFacing == "left" then
            playerSheet = playerWalkLImage
        else
            playerSheet = playerWalkImage
        end
    elseif playerAnimState == "climb" then
        totalFrames = playerClimbTotalFrames
        frameDelay = playerClimbFrameDelay
        frameCounter = playerClimbFrameCounter
        playerSheet = playerClimbImage
    elseif playerAnimState == "jump" then
        totalFrames = playerJumpTotalFrames
        frameDelay = playerJumpFrameDelay
        frameCounter = playerJumpFrameCounter
        loopFrames = false
        if playerFacing == "left" then
            playerSheet = playerJumpLImage
        else
            playerSheet = playerJumpImage
        end
    elseif playerAnimState == "fall" then
        totalFrames = playerFallTotalFrames
        frameDelay = playerFallFrameDelay
        frameCounter = playerFallFrameCounter
        loopFrames = false
        playerSheet = playerFallImage
    end

    if loopFrames then
        playerFrameIndex = math.floor(frameCounter / frameDelay) % totalFrames
    else
        playerFrameIndex = math.min(math.floor(frameCounter / frameDelay), totalFrames - 1)
    end

    local frameX = playerFrameIndex * playerFrameSize
    gfx.pushContext()
    gfx.setClipRect(screenPlayerX, screenPlayerY, playerFrameSize, playerFrameSize)
    playerSheet:draw(screenPlayerX - frameX, screenPlayerY)
    gfx.popContext()

    if level1Part5.completionPrompt then
        drawOverlayBox("Press A", 170)
    end

end

--#endregion

--#region LEVEL 1 - PART 6 - Crack the Lock

local function drawTextscene9() -- Text transition 9
    drawSceneCard("Goal:\nCrack the lock on the vault \n\nControls:\n Crank, D-pad, Buttons\nFollow the clues")
end

-- Crack the Lock mini-game


local function drawCutscene4() -- Cutscene 4 -- Inside the bank vault
    drawCutsceneReveal(backgroundImage4)
end

--#endregion

--#region LEVEL 1 - PART 7 - Escape!

local function drawTextscene10() -- Text transition 10
    drawSceneCard("Goal:\nEscape the heist in the van \n\nControls:\nD-Pad to Move")
end

local function updateLevel1Part7()
     escapeGame.update()

    if escapeGame.isComplete() then
        state = "cutscene5"
    end

    if escapeGame.didFail() then
        state = "level1failure"
    end
end


local function drawCutscene5() -- Cutscene 5 -- Escaping in the van down the highway
    drawCutsceneReveal(backgroundImage5)
end

--#endregion

--#region LEVEL 1 - END 

local function drawLevel1Success() -- End of level 1 completed
    drawTextBoldAligned("Level 1 Complete!", screenWidth / 2, 54, kTextAlignment.center)
    gfx.drawTextAligned("Score: " .. score, screenWidth / 2, 92, kTextAlignment.center)
    gfx.drawTextAligned("Best: " .. levels[1].highScore, screenWidth / 2, 112, kTextAlignment.center)
    gfx.drawTextAligned("Press A to play again", screenWidth / 2, 152, kTextAlignment.center)
end

local function drawLevel1Failure() -- End of level 1 failed
    drawTextBoldAligned("Level 1 Failed", screenWidth / 2, 54, kTextAlignment.center)
    gfx.drawTextAligned("Score: " .. score, screenWidth / 2, 92, kTextAlignment.center)
    gfx.drawTextAligned("Best: " .. levels[1].highScore, screenWidth / 2, 112, kTextAlignment.center)
    gfx.drawTextAligned("Press A to try again", screenWidth / 2, 152, kTextAlignment.center)
end

--#endregion

--#endregion

--                               MAIN                                 --
----------------------------- GAME LOGIC  ------------------------------

function playdate.update()
    
    gfx.clear()


    -- Render Scenes and Levels based on current scene state

    ---- FRONT END ----
    if state == "credits" then
        updateCredits()
        drawCredits()
    elseif state == "menu" then
        updateMenu()
        drawMenu()
    elseif state == "levelselect" then
        updateLevelSelect()
        drawLevelSelect()
    elseif state == "levelselectTransition" then
        updateLevelSelectTransition()
        drawLevelSelectTransition()
    elseif state == "titleTransition" then
        -- Begin Animations
        titleY = titleY - titleAnimSpeed
        bottomY = bottomY + titleAnimSpeed
        vanX = vanX + vanSpeed
        updateVanAnimation()
        drawTitleCard(0, titleY, bottomY, true, true)

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
    elseif state == "textscene51" then
        drawTextscene51()
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
    if glassGameInstance == nil then
        glassGameInstance = GlassGameModule.new() 
    end

    glassGameInstance:update()

    if glassGameInstance:isComplete() then
        glassGameInstance:cleanup()
        glassGameInstance = nil
        state = "textscene5"
    elseif glassGameInstance:didFail() then
        glassGameInstance:cleanup()
        glassGameInstance = nil
        state = "level1failure"
    end

    -- Tune the Radar mini-game
   elseif state == "level1part3" then
    if radarGameInstance == nil then
        radarGameInstance = RadarGameModule.new()
    end

    radarGameInstance:update()

    if radarGameInstance:isComplete() then
        radarGameInstance:cleanup()
        radarGameInstance = nil
        state = "textscene6" 
    elseif radarGameInstance:didFail() then
        radarGameInstance:cleanup()
        radarGameInstance = nil
        state = "level1failure"
    end

    -- Rope Rappel mini-game
   elseif state == "level1part4" then
    if rappelGameInstance == nil then
               rappelGameInstance = RappelGameModule.new() 
    end

    rappelGameInstance:update()
    rappelGameInstance:draw() 

    if rappelGameInstance:isComplete() then
        rappelGameInstance:cleanup()
        rappelGameInstance = nil
        state = "textscene8" -- Moves to the next scene
    elseif rappelGameInstance:didFail() then
        rappelGameInstance:cleanup()
        rappelGameInstance = nil
        state = "level1failure"
    end

    -- Inside Platformer
    elseif state == "level1part5" then
        updateLevel1Part5()
        drawLevel1Part5()

    -- Crack the Lock mini-game
    elseif state == "level1part6" then
    if safeGameInstance == nil then
        safeGameInstance = safeGame.new()
    end

    safeGameInstance:update()
    safeGameInstance:draw()


    if safeGameInstance:isComplete() then
        safeGameInstance:cleanup()
        safeGameInstance = nil
        state = "cutscene4"
    elseif safeGameInstance:didFail() then
        safeGameInstance:cleanup()
        safeGameInstance = nil
        state = "level1failure"
    end

    -- Drive the Van mini-game
    elseif state == "level1part7" then
    if escapeGameInstance == nil then
        escapeGameInstance = escapeGame.new()
    end

    escapeGameInstance:update()
    escapeGameInstance:draw()

    -- 3. Transitions
    if escapeGameInstance:isComplete() then
        escapeGameInstance:cleanup()
        escapeGameInstance = nil
        state = "cutscene5"
    elseif escapeGameInstance:didFail() then
        escapeGameInstance:cleanup()
        escapeGameInstance = nil
        state = "level1failure"
    end

    ---- Level 1 - Success ----
    elseif state == "level1success" then
        drawLevel1Success()

    ---- Level 1 - Failure ----
    elseif state == "level1failure" then
        drawLevel1Failure()

    end
end

function playdate.AButtonDown()
    
    ---- FRONT END ----
    if state == "menu" then
        resetLevelSelect()
        state = "levelselect"
    elseif state == "levelselect" then
        local level = levels[levelSelectIndex]
        if level.locked then
            levelLockedMessageTimer = levelLockedMessageDuration
        else
            if levelSelectIndex == 1 then
                resetTitleScene()
                state = "titleTransition"
            end
        end

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

-- PART 2
    ---- Text Scene 4 ----
    elseif state == "textscene4" then
        state = "level1part2"

    ---- Level 1 - Cut the glass mini-game ----

    ---- Text Scene 5 ----
    elseif state == "textscene5" then
        state = "cutscene2"
        resetCutsceneReveal()

-- PART 3
    ---- Cutscene 2 ----
    elseif state == "cutscene2" then
        state = "textscene51"

    elseif state == "textscene51" then
        state = "level1part3"

    ---- Level 1 - Tune the Radar mini-game ----

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

    ---- Level 1 - Rope Rappel mini-game ----

-- PART 5
    ---- Text Scene 8 ----
    elseif state == "textscene8" then
        state = "level1part5"
        resetLevel1Part5()

-- PART 6
    ---- Text Scene 9 ----
    elseif state == "textscene9" then
        state = "level1part6"

    ---- Level 1 - Crack the Lock mini-game ----

    ---- Cutscene 4 ----
    elseif state == "cutscene4" then
        state = "textscene10"

-- PART 7
    ---- Text Scene 10 ----
    elseif state == "textscene10" then
        state = "level1part7"
        

    ---- Level 1 - Escape the Van mini-game ----

    ---- Cutscene 5 ----
    elseif state == "cutscene5" then
        state = "level1success"

    ---- Level 1 - Success / Failure ----
    elseif state == "level1success" or state == "level1failure" then
        if score > levels[1].highScore then
            levels[1].highScore = score
        end

        score = 0
        player.x = 256
        player.y = 544

        resetTitleScene()
        resetLevel1Part1()
        resetLevel1Part5()
        resetCredits()
        state = "credits"
    end
end

function playdate.BButtonDown()
    if state == "levelselect" or state == "levelselectTransition" then
        resetCredits()
        state = "credits"
    end
end