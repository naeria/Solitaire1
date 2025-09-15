extends Node2D

var CARD_OFFSET: float = Global.card_offset

var CardScene := preload("res://Scenes/Card.tscn")
var suits := ["spades", "hearts", "diamonds", "clubs"]
var deck := []

@onready var pile_1: Node2D = $Tableau/Pile1
@onready var pile_2: Node2D = $Tableau/Pile2
@onready var pile_3: Node2D = $Tableau/Pile3
@onready var pile_4: Node2D = $Tableau/Pile4
@onready var pile_5: Node2D = $Tableau/Pile5
@onready var pile_6: Node2D = $Tableau/Pile6
@onready var pile_7: Node2D = $Tableau/Pile7

@onready var pile_array := [pile_1,pile_2,pile_3,pile_4,pile_5,pile_6,pile_7]

func _ready():
	seed(11111)
	
	generate_deck()
	shuffle_deck()
	deal_to_tableau()

func generate_deck():
	deck.clear()
	for suit in suits:
		for rank in range(1, 14):  # 1 (Ace) to 13 (King)
			var card = CardScene.instantiate()
			card.suit = suit
			card.rank = rank
			deck.append(card)

func shuffle_deck():
	deck.shuffle()

func deal_to_tableau():
	for i in range(7):
		var pile_name = "Pile" + str(i + 1)
		var pile = $Tableau.get_node(pile_name)
		var total_cards = i + 1
		var y_offset = 0  # start offset for vertical stacking

		for j in range(total_cards):
			if deck.size() == 0:
				return  # or break

			var card = deck.pop_front()
			pile.add_child(card)

			var is_top = (j == total_cards - 1)
			card.set_face_up(is_top)

			# If it's a single-card pile, place at y = 0
			if total_cards == 1:
				card.position = Vector2(0, 0)
			else:
				card.position = Vector2(0, y_offset)

			card.z_index = j

			# Only increase offset if this is not a single-card pile
			if total_cards != 1:
				y_offset += CARD_OFFSET
	
	var i: int = 0
	for pile in pile_array:
		i += 1
		pile.pile_index = i
		pile.update_outline()


func _on_drop_area_mouse_entered() -> void:
	pass # Replace with function body.


func _on_drop_area_mouse_exited() -> void:
	pass # Replace with function body.
