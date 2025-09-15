class_name Card

extends Node2D

@onready var area := $Area2D

var rank: int
var suit: String
var is_face_up: bool = false
var original_pile: Node
var drag_stack: Array[Card]
var drag_stack_offsets: Array[Vector2]
var is_dragging = false
var drag_offset := Vector2.ZERO
var original_parent
var original_position
var current_pile: Node2D = null

var is_first_card: bool = false
func _ready():
	if is_face_up && !Global.first_card_taken:
		is_first_card = true
		Global.first_card_taken = true
	
	area.input_event.connect(_on_input_event)
	add_to_group("cards")

var time_passed: float = 0.0
func _process(delta):
	time_passed += delta
	if is_first_card:
		#print(position.y)
		pass
	
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset





func set_face_up(value: bool) -> void:
	is_face_up = value

	if is_face_up:
		var name = "%s_of_%s.png" % [rank_to_name(), suit]
		var path = "res://Assets/Cards/%s" % name
		if ResourceLoader.exists(path):
			$Sprite2D.texture = load(path)
	else:
		$Sprite2D.texture = load("res://Assets/Cards/card_back.png")
		
func rank_to_name() -> String:
	match rank:
		1: return "ace"
		11: return "jack"
		12: return "queen"
		13: return "king"
		_: return str(rank)



func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Don't drag face-down cards
			if not is_face_up:
				return
			
			# Prepare dragging
			original_position = global_position
			original_pile = get_parent()
			drag_stack = get_drag_stack(self)

			if drag_stack.size() == 0:
				return  # Nothing to drag
			
			is_dragging = true
			
			# Calculate offset between mouse and top card's position
			drag_offset = drag_stack[0].global_position - event.global_position
			
			# Store each card’s offset relative to the top card
			drag_stack_offsets.clear()
			for card in drag_stack:
				drag_stack_offsets.append(card.global_position - drag_stack[0].global_position)

			# Bring dragged cards to front (high z_index)
			for i in range(drag_stack.size()):
				drag_stack[i].z_index = 100 + i

		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Mouse button released - stop dragging and try to drop
			if is_dragging:
				is_dragging = false
				try_drop()
				drag_stack.clear()
				drag_stack_offsets.clear()

	elif event is InputEventMouseMotion:
		# Move the entire drag stack following the mouse, maintaining relative offsets
		if is_dragging:
			var global_pos = event.global_position
			for i in range(drag_stack.size()):
				var offset = drag_stack_offsets[i]
				drag_stack[i].global_position = global_pos + drag_offset + offset



func start_drag():
	is_dragging = true
	drag_stack.clear() # <- This is the crucial line.
	
	# Clear the drag_stack before populating it
	drag_stack.clear()
	
	# Get all cards in the pile from this card onward
	var my_index = get_index()
	var parent_children = get_parent().get_children()
	for i in range(my_index, parent_children.size()):
		var child = parent_children[i]
		if child.has_method("rank"): # Make sure it's a card
			drag_stack.append(child)
			
	# Reparent the entire stack to the main game node
	var game_node = get_tree().get_root().get_node("Game")
	var first_card_pos = get_global_mouse_position()
	var offset_from_first_card = Vector2.ZERO
	
	for i in range(drag_stack.size()):
		var card = drag_stack[i]
		
		# Reparent to the Game node to allow for free movement
		card.reparent(game_node)
		
		# Store the original position
		card.original_position = card.global_position
		
		# Set the z_index to a high value to ensure the entire stack is on top
		card.z_index = 1000 + i
		
		# Calculate the position relative to the mouse
		if i == 0:
			# The first card follows the mouse directly
			offset_from_first_card = first_card_pos - card.original_position
			card.global_position = first_card_pos
		else:
			# Subsequent cards maintain their relative position to the first card
			card.global_position = card.original_position + offset_from_first_card
			
	# The first card is the one being controlled by the mouse
	var first_card = drag_stack[0]
	drag_offset = first_card_pos - first_card.global_position
	

func stop_drag():
	is_dragging = false

	var tableau = get_tree().root.get_node("Game/Tableau")  # Adjust path if needed
	var dropped = false

	for pile in tableau.get_children():
		if pile.get_child_count() == 0:
			# 🟨 Allow dropping a King onto an empty pile
			if drag_stack[0].rank == 13:  # King
				move_stack_to_pile(pile)
				dropped = true
				drag_stack.clear()
				drag_stack_offsets.clear()
				break
			else:
				continue
				
		var top = pile.get_child(pile.get_child_count() - 1)
		if top is Card and top.is_face_up and top.get_global_rect().has_point(global_position):
			if is_valid_stack_drop(top, drag_stack[0]):
				move_stack_to_pile(pile)
				dropped = true
				drag_stack.clear()
				drag_stack_offsets.clear()
				break

	if not dropped:
		move_stack_to_pile(original_pile)
		drag_stack.clear()
		drag_stack_offsets.clear()

	
	# ✅ After the stack is moved away, check the original pile
	if original_pile and original_pile.get_child_count() > 0:
		var top_card = get_top_card(original_pile)
		if top_card and not top_card.is_face_up:
			top_card.set_face_up(true)
	drag_stack.clear()
	drag_stack_offsets.clear()


func try_drop():
	var all_piles = get_node("/root/Game/Tableau").get_children() + get_node("/root/Game/Foundations").get_children()
	var dropped = false

	for pile in all_piles:
		var drop_area := pile.get_node_or_null("DropArea")
		if drop_area:
			var shape = drop_area.get_node_or_null("CollisionShape2D")
	
			if shape and shape.shape is RectangleShape2D:
				var rect_size = shape.shape.extents * 2
				var rect_pos = drop_area.global_position - shape.shape.extents
				var drop_rect = Rect2(rect_pos - Vector2(10, 10), rect_size + Vector2(20, 20))
			
				var mouse_pos = get_viewport().get_mouse_position()
				if drop_rect.has_point(mouse_pos):
					var is_foundation := pile.get_parent().name == "Foundations"
					var top_card := get_top_faceup_card(pile)
					
					if is_foundation:
						if top_card == null:
							if rank == 1 and drag_stack.size() == 1:
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()

						elif top_card:
							if top_card.suit == suit and top_card.rank == rank - 1 and drag_stack.size() == 1:
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()
								break
					else:
						if top_card == null:
							if rank == 13:
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()
								break
						elif top_card:
							if top_card.is_face_up and is_opposite_color(suit, top_card.suit) and rank == top_card.rank - 1:
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()
								break

	if not dropped:
		# Invalid drop, return to original pile
		move_stack_to_pile(original_pile)

func get_global_rect() -> Rect2:
	var sprite = $Sprite2D
	var texture = sprite.texture
	var size = Vector2(100, 145)  # fallback card size (scaled 0.2 from 500x726)

	if texture:
		size = texture.get_size() * sprite.scale

	var top_left = global_position - size / 2
	return Rect2(top_left, size)

func get_top_faceup_card(pile: Node) -> Card:
	var top_card: Card = null

	for child in pile.get_children():
		if child is Card and child.is_face_up:
			top_card = child

	return top_card

func move_stack_to_pile(new_pile: Node):
	# When adding a card to a pile
	var card_index = new_pile.get_child_count()
	# card.z_index = card_index
	
	## Determine the base stack height (i.e., how many cards are already in the pile)
	#var base_offset = 0
	#for child in new_pile.get_children():
		#if child.has_method("rank_to_name"):  # Identify actual card nodes
			#base_offset += 1
	## Track the original pile before moving
	var target_pile_amount: int = new_pile.get_amount()
	
	var original_pile = null
	if drag_stack.size() > 0:
		original_pile = drag_stack[0].current_pile
	for i in range(drag_stack.size()):
		var card = drag_stack[i]
		
		# Reparent the card correctly
		card.reparent(new_pile)
		# Set the position based on its new index
		card.position = Vector2(0, (target_pile_amount - 1) * 12)
		# Set the z_index based on its new index in the pile
		card.z_index = target_pile_amount + i
		# Update card properties
		card.current_pile = new_pile
		card.is_dragging = false
		
		# Check if the card is face-up and adjust its z_index accordingly
		if card.is_face_up:
			card.z_index += 100 # Or whatever your face-up offset is
	# Hide outline from new pile if needed
	if new_pile.has_method("update_outline"):
		new_pile.update_outline()

	# Hide outline from original pile if needed
	if original_pile and original_pile.has_method("update_outline"):
		original_pile.update_outline()

func is_opposite_color(suit_a: String, suit_b: String) -> bool:
	var red_suits = ["hearts", "diamonds"]
	var black_suits = ["clubs", "spades"]
	return (suit_a in red_suits and suit_b in black_suits) or (suit_a in black_suits and suit_b in red_suits)

func is_valid_stack_drop(target_card: Card, moving_card: Card) -> bool:
	# Example rule: Only allow moving a red card onto a black card one rank higher
	if target_card == null or moving_card == null:
		return false

	var red_suits = ["hearts", "diamonds"]
	var black_suits = ["clubs", "spades"]

	var is_opposite_color = (target_card.suit in red_suits and moving_card.suit in black_suits) or \
		(target_card.suit in black_suits and moving_card.suit in red_suits)

	return is_opposite_color and moving_card.rank == target_card.rank - 1

func get_top_card(pile: Node) -> Card:
	for i in range(pile.get_child_count() - 1, -1, -1):
		var c = pile.get_child(i)
		if c is Card:
			return c
	return null

func can_drop_on(other_card: Card) -> bool:
	# Solitaire rule: alternating color, one rank lower
	var red = (suit == "hearts" or suit == "diamonds")
	var other_red = (other_card.suit == "hearts" or other_card.suit == "diamonds")
	return red != other_red and rank == other_card.rank - 1

func is_red(suit: String) -> bool:
	return suit == "hearts" or suit == "diamonds"

func get_drag_stack(start_card: Card) -> Array[Card]:
	var stack: Array[Card] = []

	var found = false
	for child in start_card.get_parent().get_children():
		if child == start_card:
			found = true
		if found and child is Card and child.is_face_up:
			stack.append(child)

	return stack

const BASE_Z_INDEX = 0
const FACEUP_Z_OFFSET = 100 # This should be greater than the max number of cards (52)

func flip_card(card):
	card.is_facedown = not card.is_facedown
	if not card.is_facedown:
		# If it's a face-up card, ensure it's drawn on top
		card.z_index += FACEUP_Z_OFFSET
	else:
		# If it's face-down, revert to its original z_index
		card.z_index -= FACEUP_Z_OFFSET
