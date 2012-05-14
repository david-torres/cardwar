require 'stack'
require 'game'
require 'game_debug'
value = require('json')

display.setStatusBar(display.HiddenStatusBar)

-- global variables
INIT_DECK_SHUFFLES = 5
CARD_HEIGHT = 150
CARD_WIDTH = 104

P1_START_X = 0
P1_START_Y = display.contentHeight - CARD_HEIGHT / 2
P2_START_X = 0
P2_START_Y = CARD_HEIGHT / 2

_W = display.contentWidth / 2
_H = display.contentHeight / 2

-- init game
Game:new_game()