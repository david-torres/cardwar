import json

suits = ['Heart', 'Diamond', 'Club', 'Spade']
values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']

deck = []
for suit in suits:
    for val in values:
        card = {
            'suit': suit,
            'value': val
        }
        deck.append(card)

f = open('deck.json', 'wb')
f.write(json.dumps(deck))
