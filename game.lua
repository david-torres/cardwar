GameZone = {}
function GameZone:new()
    local self = {
        stack = nil
    }

    return {
        stack = self.stack
    }
end

WarZone = GameZone:new()
function WarZone:add_card(player, x, y)

    -- if player1 has not yet played a card, try to add one to the zone
    if player == 'player1' and self.p1_active_card == nil then

        self.p1_active_card = Game.stacks.p1_stack.deal()

        -- no more cards, you lose
        if self.p1_active_card == nil then
            print('Player 1 lost')
        end

        -- cleanup existing sprite from previous war
        if Game.sprites.p1_active_card ~= nil then
            Game.sprites.p1_active_card:removeSelf()
            Game.sprites.p1_active_card = nil
        end

        -- add card sprite
        local card_flip_channel = audio.play(Game.sfx.card_flip)
        Game.sprites.p1_active_card = Game:card(player, self.p1_active_card, x, y)

    -- if player2 has not yet played a card, add it to the zone
    elseif player == 'player2' and self.p2_active_card == nil then

        self.p2_active_card = Game.stacks.p2_stack.deal()

        -- no more cards, you lose
        if self.p2_active_card == nil then
            print('Player 2 lost')
        end

        -- cleanup existing sprite from previous war
        if Game.sprites.p2_active_card ~= nil then
            Game.sprites.p2_active_card:removeSelf()
            Game.sprites.p2_active_card = nil
        end

        -- add card sprite
        local card_flip_channel = audio.play(Game.sfx.card_flip)
        Game.sprites.p2_active_card = Game:card(player, self.p2_active_card, x, y)
    end

    -- if both players have played a card, check conditions
    if self.p1_active_card ~= nil and self.p2_active_card ~= nil then

        -- compare values
        local compare_result = WarZone:compare_values(self.p1_active_card.attr('value'), self.p2_active_card.attr('value'))

        -- player 1 wins the battle
        if  compare_result == 'val1' then
            -- move cards to p1s stack
            transition.to(Game.sprites.p1_active_card, {
                time = 225,
                x = P1_START_X,
                y = P1_START_Y,
                onComplete = function()
                    Game.sprites.p1_active_card:removeSelf()
                    Game.sprites.p1_active_card = nil
                end
            })
            transition.to(Game.sprites.p2_active_card, {
                time = 225,
                x = P1_START_X,
                y = P1_START_Y,
                onComplete = function()
                    Game.sprites.p2_active_card:removeSelf()
                    Game.sprites.p2_active_card = nil
                end
            })

            Game.stacks.p1_stack.add(self.p1_active_card)
            Game.stacks.p1_stack.add(self.p2_active_card)

            if Game.stacks.p1_war_stack.count() > 0 and Game.stacks.p2_war_stack.count() > 0 then
                -- claim all war stacks
                local shuffle_channel = audio.play(Game.sfx.shuffle)
                Game.stacks.p1_stack.combine(Game.stacks.p1_war_stack.cards())
                Game.stacks.p1_stack.combine(Game.stacks.p2_war_stack.cards())

                -- cleanup war stacks
                Game.stacks.p1_war_stack = Stack:new()
                Game.stacks.p2_war_stack = Stack:new()

                Game.sprites.p1_war_stack:removeSelf()
                Game.sprites.p1_war_stack = nil

                Game.sprites.p2_war_stack:removeSelf()
                Game.sprites.p2_war_stack = nil
            end

            self.p1_active_card = nil
            self.p2_active_card = nil

        -- player 2 wins the battle
        elseif compare_result == 'val2' then

            -- move cards to p2s stack
            transition.to(Game.sprites.p1_active_card, {
                time = 225,
                x = P2_START_X,
                y = P2_START_Y,
                onComplete = function()
                    Game.sprites.p1_active_card:removeSelf()
                    Game.sprites.p1_active_card = nil
                end
            })
            transition.to(Game.sprites.p2_active_card, {
                time = 225,
                x = P2_START_X,
                y = P2_START_Y,
                onComplete = function()
                    Game.sprites.p2_active_card:removeSelf()
                    Game.sprites.p2_active_card = nil
                end
            })

            Game.stacks.p2_stack.add(self.p1_active_card)
            Game.stacks.p2_stack.add(self.p2_active_card)

            if Game.stacks.p1_war_stack.count() > 0 and Game.stacks.p2_war_stack.count() > 0 then
                -- claim all war stacks
                local shuffle_channel = audio.play(Game.sfx.shuffle)
                Game.stacks.p2_stack.combine(Game.stacks.p1_war_stack.cards())
                Game.stacks.p2_stack.combine(Game.stacks.p2_war_stack.cards())

                -- cleanup war stacks
                Game.stacks.p1_war_stack = Stack:new()
                Game.stacks.p2_war_stack = Stack:new()

                Game.sprites.p1_war_stack:removeSelf()
                Game.sprites.p1_war_stack = nil

                Game.sprites.p2_war_stack:removeSelf()
                Game.sprites.p2_war_stack = nil
            end

            self.p1_active_card = nil
            self.p2_active_card = nil

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
            Game.stacks.p2_war_stack.combine(Game.stacks.p2_stack.draw(3))
            Game.stacks.p2_war_stack.add(self.p2_active_card)

            -- play card flip x3
            local card_flip_channel = audio.play(Game.sfx.card_flip)
            local card_flip_channel = audio.play(Game.sfx.card_flip)
            local card_flip_channel = audio.play(Game.sfx.card_flip)

            self.p1_active_card = nil
            self.p2_active_card = nil
        end
    end

    -- update scores
    Game.sprites.p1_score.text = Game.stacks.p1_stack.count()
    Game.sprites.p2_score.text = Game.stacks.p2_stack.count()
end

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
    },
    sfx = {
        card_flip = audio.loadSound('card_flip.wav'),
        shuffle = audio.loadSound('shuffle.wav'),
    }
}

function Game:new_game()
    -- load deck
    local path = system.pathForFile('deck.json', system.DocumentsDirectory)
    Game.stacks.deck = Stack:load(path)

    Game:init_background()
    Game:init_deal()
    Game:init_stacks()
    Game:init_scores()
    Game:listeners('add')
end

function Game:init_background()
    -- add background texture
    Game.sprites.bg = display.newImage('wood_table.png', 0, 0)
    Game.sprites.bg.x = _H
    Game.sprites.bg.y = _W
end

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

function Game:init_stacks()
    Game.sprites.p1_stack = Game:blank()
    Game.sprites.p1_stack.name = 'player1'
    Game.sprites.p1_stack.y = P1_START_Y

    Game.sprites.p2_stack = Game:blank()
    Game.sprites.p2_stack.name = 'player2'
    Game.sprites.p2_stack.y = P2_START_Y
end


function Game:init_scores()
    -- add score text
    Game.sprites.p1_score = display.newText('26', P1_START_X + 8, P1_START_Y - 40, 'Arial', 54)
    Game.sprites.p1_score:setTextColor(255, 255, 255, 255)

    Game.sprites.p2_score = display.newText('26', P2_START_X + 8, P2_START_Y - 40, 'Arial', 54)
    Game.sprites.p2_score:setTextColor(255, 255, 255, 255)
end

function Game:blank()
    return display.newImage('card_back.png', 0, 0)
end

function Game:card(stack_owner, card, x, y)
    local suit = card.attr('suit')
    local value = card.attr('value')
    local value_text = display.newText(value, 0, 0, 'Arial', 32)
    value_text:setTextColor(0, 0, 0, 255)

    local card_sprite = display.newGroup()
    if suit == 'Heart' then
        card_sprite:insert(display.newImage('heart.png'))
        card_sprite:insert(value_text)
    elseif suit == 'Diamond' then
        card_sprite:insert(display.newImage('diamond.png'))
        card_sprite:insert(value_text)
    elseif suit == 'Club' then
        card_sprite:insert(display.newImage('club.png'))
        card_sprite:insert(value_text)
    elseif suit == 'Spade' then
        card_sprite:insert(display.newImage('spade.png'))
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

function Game:play_card(e)
    return function(e)
        WarZone:add_card(e.target.name, e.target.x, e.target.y)
    end
end

function Game:listeners(event)
    if event == 'add' then
        Game.sprites.p1_stack:addEventListener('tap', Game:play_card(event))
        Game.sprites.p2_stack:addEventListener('tap', Game:play_card(event))
    elseif event == 'remove' then
        Game.sprites.p1_stack:removeEventListener('tap', Game:play_card(event))
        Game.sprites.p2_stack:removeEventListener('tap', Game:play_card(event))
    end
end