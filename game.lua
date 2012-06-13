--
-- Generic container for game zone data
--
GameZone = {}
function GameZone:new()
    local self = {
        stack = nil
    }

    return {
        stack = self.stack
    }
end

--
-- The primary playing area
--
WarZone = GameZone:new()

--
-- Draw a button prompting the player to claim their cards
--
function WarZone:claim_button(player)
    local button_width = 500
    local button_height = 50
    if player == 'player1' then
        Game.sprites.p1_claim_button = widget.newButton{
            id = "p1_claim_button",
            left = _W,
            top = _H,
            label = "CLAIM YOUR CARDS PLAYER 1!",
            fontSize = 32,
            width = button_width,
            height = button_height,
            onEvent = WarZone:claim_action()
        }
    elseif player == 'player2' then
        Game.sprites.p2_claim_button = widget.newButton{
            id = "p2_claim_button",
            left = _W,
            top = _H,
            label = "CLAIM YOUR CARDS PLAYER 2!",
            fontSize = 32,
            width = button_width,
            height = button_height,
            onEvent = WarZone:claim_action()
        }
    end

end

--
-- Event handler for claiming cards in play
--
function WarZone:claim_action(event)
    return function(event)
        local start_x
        local start_y
        local player_stack
        local button

        -- set values for the appropriate player
        if event.target.id == 'p1_claim_button' then
            start_x = P1_START_X
            start_y = P1_START_Y
            player_stack = Game.stacks.p1_stack
            button = Game.sprites.p1_claim_button
        elseif event.target.id == 'p2_claim_button' then
            start_x = P2_START_X
            start_y = P2_START_Y
            player_stack = Game.stacks.p2_stack
            button = Game.sprites.p2_claim_button
        end

        -- move cards to player's stack
        transition.to(Game.sprites.p1_active_card, {
            time = 225,
            x = start_x,
            y = start_y,
            onComplete = function()
                Game.sprites.p1_active_card:removeSelf()
                Game.sprites.p1_active_card = nil
            end
        })
        transition.to(Game.sprites.p2_active_card, {
            time = 225,
            x = start_x,
            y = start_y,
            onComplete = function()
                Game.sprites.p2_active_card:removeSelf()
                Game.sprites.p2_active_card = nil
            end
        })

        -- add cards to the stack
        player_stack.add(self.p1_active_card)
        player_stack.add(self.p2_active_card)

        Game:sfx('card_flip')
        Game:sfx('card_flip')

        if Game.stacks.p1_war_stack.count() > 0 and Game.stacks.p2_war_stack.count() > 0 then
            -- claim all war stacks
            Game:sfx('shuffle')
            player_stack.combine(Game.stacks.p1_war_stack.cards())
            player_stack.combine(Game.stacks.p2_war_stack.cards())

            -- cleanup war stacks and sprites
            Game.stacks.p1_war_stack = Stack:new()
            Game.stacks.p2_war_stack = Stack:new()

            Game.sprites.p1_war_stack:removeSelf()
            Game.sprites.p1_war_stack = nil

            Game.sprites.p2_war_stack:removeSelf()
            Game.sprites.p2_war_stack = nil
        end

        -- clean slate
        self.p1_active_card = nil
        self.p2_active_card = nil

        display.remove(button)
    end
end

--
-- Adds a card to the playing field
--
function WarZone:add_card(player, x, y)

    -- if player1 has not yet played a card, try to add one to the zone
    if player == 'player1' and self.p1_active_card == nil then

        self.p1_active_card = Game.stacks.p1_stack.deal()

        -- no more cards, you lose
        -- TODO: this could potentially be a war
        if self.p1_active_card == nil then
            print('Player 1 lost')
        end

        -- cleanup existing sprite from previous war
        if Game.sprites.p1_active_card ~= nil then
            Game.sprites.p1_active_card:removeSelf()
            Game.sprites.p1_active_card = nil
        end

        -- add card sprite
        Game:sfx('card_flip')
        Game.sprites.p1_active_card = Game:card(player, self.p1_active_card, x, y)

    -- if player2 has not yet played a card, add it to the zone
    elseif player == 'player2' and self.p2_active_card == nil then

        self.p2_active_card = Game.stacks.p2_stack.deal()

        -- no more cards, you lose
        -- TODO: this could potentially be a war
        if self.p2_active_card == nil then
            print('Player 2 lost')
        end

        -- cleanup existing sprite from previous war
        if Game.sprites.p2_active_card ~= nil then
            Game.sprites.p2_active_card:removeSelf()
            Game.sprites.p2_active_card = nil
        end

        -- add card sprite
        Game:sfx('card_flip')
        Game.sprites.p2_active_card = Game:card(player, self.p2_active_card, x, y)
    end

    -- if both players have played a card, check conditions
    if self.p1_active_card ~= nil and self.p2_active_card ~= nil then

        -- compare values
        local compare_result = WarZone:compare_values(self.p1_active_card.attr('value'), self.p2_active_card.attr('value'))

        -- player 1 wins the battle
        if  compare_result == 'val1' then
            WarZone:claim_button('player1')

        -- player 2 wins the battle
        elseif compare_result == 'val2' then
            WarZone:claim_button('player2')

        -- WAR!
        elseif compare_result == 'equal' then

            -- render a blank to represent p1s war stack
            if Game.sprites.p1_war_stack == nil then
                Game.sprites.p1_war_stack = Game:blank()
                transition.to(Game.sprites.p1_war_stack, {
                    time = 225,
                    x = P1_START_X + 400,
                    y = P1_START_Y
                })
            end
            
            -- draw 3 cards for p1 and add them to their war stack
            -- TODO: player may have less than 3 cards in their stack
            Game.stacks.p1_war_stack.combine(Game.stacks.p1_stack.draw(3))
            Game.stacks.p1_war_stack.add(self.p1_active_card)

            -- render a blank to represent p2s war stack
            if Game.sprites.p2_war_stack == nil then
                Game.sprites.p2_war_stack = Game:blank()
                transition.to(Game.sprites.p2_war_stack, {
                    time = 225,
                    x = P2_START_X + 400,
                    y = P2_START_Y
                })
            end

            -- draw 3 cards for p2 and add them to their war stack
            -- TODO: player may have less than 3 cards in their stack
            Game.stacks.p2_war_stack.combine(Game.stacks.p2_stack.draw(3))
            Game.stacks.p2_war_stack.add(self.p2_active_card)

            -- play card flip x3
            -- TODO: figure out how to space these out so they sound distinct
            Game:sfx('card_flip')
            Game:sfx('card_flip')
            Game:sfx('card_flip')

            -- these cards have been added to their respective war stacks
            -- clear the way for the next battle
            self.p1_active_card = nil
            self.p2_active_card = nil
        end
    end

    -- update scores
    Game.sprites.p1_score.text = Game.stacks.p1_stack.count()
    Game.sprites.p2_score.text = Game.stacks.p2_stack.count()
end

--
-- Compares the values of the cards in play
--
function WarZone:compare_values(val1, val2)
    local comparison_result = nil
    local computed_val1 = nil
    local computed_val2 = nil

    if val1 == 'A' then
        computed_val1 = 14
    elseif val1 == 'K' then
        computed_val1 = 13
    elseif val1 == 'Q' then
        computed_val1 = 12
    elseif val1 == 'J' then
        computed_val1 = 11
    else
        computed_val1 = tonumber(val1)
    end

    if val2 == 'A' then
        computed_val2 = 14
    elseif val2 == 'K' then
        computed_val2 = 13
    elseif val2 == 'Q' then
        computed_val2 = 12
    elseif val2 == 'J' then
        computed_val2 = 11
    else
        computed_val2 = tonumber(val2)
    end

    if computed_val1 > computed_val2 then
        comparison_result = 'val1'
    elseif computed_val2 > computed_val1 then
        comparison_result = 'val2'
    elseif computed_val1 == computed_val2 then
        comparison_result = 'equal'
    end

    computed_val1 = nil
    computed_val2 = nil
    return comparison_result
end

--
-- Primary game
--
Game = {
    stacks = {
        deck = nil,
        p1_stack = Stack:new(),
        p2_stack = Stack:new(),
        p1_war_stack = Stack:new(),
        p2_war_stack = Stack:new(),
    },
    sprites = {
        bg = nil,
        p1_stack = nil,
        p2_stack = nil,
        p1_active_card = nil,
        p2_active_card = nil,
        p1_war_stack = nil,
        p2_war_stack = nil,
        p1_score = nil,
        p2_score = nil,
        p1_claim_button = nil,
        p2_claim_button = nil,
    },
    sounds = {
        card_flip = audio.loadSound('Assets/card_flip.wav'),
        shuffle = audio.loadSound('Assets/shuffle.wav'),
    }
}

--
-- initializes the game state and playable area
--
function Game:new_game()
    -- load deck from json
    local path = system.pathForFile('deck.json', system.DocumentsDirectory)
    Game.stacks.deck = Stack:load(path)

    Game:init_background()
    Game:init_deal()
    Game:init_stacks()
    Game:init_scores()
    Game:listeners('add')
end

--
-- Draws the background texture
--
function Game:init_background()
    Game.sprites.bg = display.newImage('Assets/wood_table.png', 0, 0, true)
    Game.sprites.bg.x = _W
    Game.sprites.bg.y = _H
end

--
-- Shuffles the deck and deals the initial stacks
--
function Game:init_deal()
    Game.stacks.deck.shuffle(INIT_DECK_SHUFFLES)
    for i = 1, Game.stacks.deck.count() do
        if i % 2 == 0 then
            Game.stacks.p1_stack.add(Game.stacks.deck.deal())
        else
            Game.stacks.p2_stack.add(Game.stacks.deck.deal())
        end
    end
end

--
-- Draws the player stacks
--
function Game:init_stacks()
    Game.sprites.p1_stack = Game:blank()
    Game.sprites.p1_stack.name = 'player1'
    Game.sprites.p1_stack.y = P1_START_Y

    Game.sprites.p2_stack = Game:blank()
    Game.sprites.p2_stack.name = 'player2'
    Game.sprites.p2_stack.y = P2_START_Y
end

--
-- Draws the player scores
--
function Game:init_scores()
    Game.sprites.p1_score = display.newText(Game.stacks.p1_stack.count(), P1_START_X + 2, P1_START_Y - 75, 'Arial', 32)
    Game.sprites.p1_score:setTextColor(255, 255, 255, 255)

    Game.sprites.p2_score = display.newText(Game.stacks.p2_stack.count(), P2_START_X + 2, P2_START_Y - 75, 'Arial', 32)
    Game.sprites.p2_score:setTextColor(255, 255, 255, 255)
end

--
-- Plays sound effects
--
function Game:sfx(name)
    local channel = audio.play(Game.sounds[name])
end

--
-- Draws a blank card back
--
function Game:blank()
    return display.newImage('Assets/card_back.png', 0, 0)
end

--
-- Draws a card
--
function Game:card(stack_owner, card, x, y)
    local suit = card.attr('suit')
    local value = card.attr('value')
    local value_text = display.newText(value, 0, 0, 'Arial', 32)
    value_text:setTextColor(0, 0, 0, 255)

    local card_sprite = display.newGroup()
    if suit == 'Heart' then
        card_sprite:insert(display.newImage('Assets/heart.png'))
        card_sprite:insert(value_text)
    elseif suit == 'Diamond' then
        card_sprite:insert(display.newImage('Assets/diamond.png'))
        card_sprite:insert(value_text)
    elseif suit == 'Club' then
        card_sprite:insert(display.newImage('Assets/club.png'))
        card_sprite:insert(value_text)
    elseif suit == 'Spade' then
        card_sprite:insert(display.newImage('Assets/spade.png'))
        card_sprite:insert(value_text)
    end

    card_sprite.x = x
    card_sprite.y = y

    if stack_owner == 'player1' then
        transition.to(card_sprite, {
            time = 225,
            x = _W,
            y = _H + CARD_WIDTH * 0.5
        })
    else
        transition.to(card_sprite, {
            time = 225,
            x = _W,
            y = _H - CARD_WIDTH - 50
        })
    end

    return card_sprite
end

--
-- Event handler for adding a card to the playing field
--
function Game:play_card(e)
    return function(e)
        WarZone:add_card(e.target.name, e.target.x, e.target.y)
    end
end

--
-- Event listeners
--
function Game:listeners(event)
    if event == 'add' then
        Game.sprites.p1_stack:addEventListener('tap', Game:play_card(event))
        Game.sprites.p2_stack:addEventListener('tap', Game:play_card(event))
    elseif event == 'remove' then
        Game.sprites.p1_stack:removeEventListener('tap', Game:play_card(event))
        Game.sprites.p2_stack:removeEventListener('tap', Game:play_card(event))
    end
end
