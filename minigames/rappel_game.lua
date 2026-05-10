-- rappel_game.lua
local pd <const> = playdate
local gfx <const> = playdate.graphics

local RappelGame = {}

-- ─────────────────────────────────────────────────────────────
-- Constructor
-- ─────────────────────────────────────────────────────────────

function RappelGame.new()
    local self = {}
    setmetatable(self, { __index = RappelGame })

    -- Images
    self.bgImage = gfx.image.new("images/rappel_game/rappel_game")
    self.playerImage = gfx.image.new("images/rappel_game/rappel_game_player")
    self.playerLoseImage = gfx.image.new("images/rappel_game/rappel_game_player_lose")

    -- Variables
    self.pHeight = 8
    self.fallen = false
    self.won = false
    self.fail = false
    self.gameOver = false

    self.deathTimer = 0
    self.deathDuration = 30

    return self
end

-- ─────────────────────────────────────────────────────────────
-- Methods
-- ─────────────────────────────────────────────────────────────

function RappelGame:update()
    if self.gameOver then
        return
    end

    if self.fallen then
        if self.deathTimer > 0 then
            self.deathTimer -= 1
            if self.deathTimer <= 0 then
                self.fail = true
                self.gameOver = true
            end
        end
        return
    end

    local acceleratedChange = pd.getCrankChange()

    -- Safe descent
    if acceleratedChange < 15 and self.pHeight < 175 then
        self.pHeight += acceleratedChange / 6
    -- Win Condition
    elseif self.pHeight >= 175 then
        self.won = true
        self.gameOver = true
    -- Lose Condition (Cranked too fast)
    elseif acceleratedChange >= 15 then
        self.fallen = true
        self.deathTimer = self.deathDuration
    end
end

function RappelGame:draw()
    if self.bgImage then self.bgImage:draw(0, 0) end

    local ropeX = 303
    local ropeStartY = 8
    local playerX = 283

    if self.pHeight >= 175 then
        gfx.drawLine(ropeX, ropeStartY, ropeX, 175)
        if self.playerImage then self.playerImage:draw(playerX, 175) end
    elseif self.fallen then
        gfx.drawLine(ropeX, ropeStartY, ropeX, self.pHeight)
        if self.playerLoseImage then self.playerLoseImage:draw(260, 205) end
    else
        gfx.drawLine(ropeX, ropeStartY, ropeX, self.pHeight)
        if self.playerImage then self.playerImage:draw(playerX, self.pHeight) end
    end
end

-- ─────────────────────────────────────────────────────────────
-- Status Checkers for main.lua
-- ─────────────────────────────────────────────────────────────

function RappelGame:isComplete()
    return self.won and self.gameOver
end

function RappelGame:didFail()
    return self.fail and self.gameOver
end

function RappelGame:cleanup()
    self.pHeight = 8
    self.fallen = false
    self.won = false
    self.fail = false
    self.gameOver = false
    self.deathTimer = 0
end

return RappelGame