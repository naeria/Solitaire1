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



func set_face_up(value: bool) -> void:
	is_face_up = value
	print("Flipping card:", rank, "of", suit, " → face_up:", is_face_up)

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

func _ready():
	area.input_event.connect(_on_input_event)
	add_to_group("cards")
	
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
				print("Card in drag_stack:", card.name)

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


func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func start_drag():
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	original_parent = get_parent()
	original_position = global_position
	original_pile = get_parent()
	# raise()  # brings to front
	# Bring to front
	z_index = 1000  # Large value to ensure it's on top
	get_parent().move_child(self, get_parent().get_child_count() - 1)

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
		print("Checking pile:", pile.name)

		var drop_area := pile.get_node_or_null("DropArea")
		if not drop_area:
			print("No DropArea found for pile:", pile.name)
		if drop_area:
			var shape = drop_area.get_node_or_null("CollisionShape2D")
			if not shape or not shape.shape:
				print("Missing CollisionShape2D in DropArea of", pile.name)
	
			if shape and shape.shape is RectangleShape2D:
				var rect_size = shape.shape.extents * 2
				var rect_pos = drop_area.global_position - shape.shape.extents
				var drop_rect = Rect2(rect_pos - Vector2(10, 10), rect_size + Vector2(20, 20))
				print("Drop rect:", drop_rect, "Card global pos:", global_position)

				print("Checking pile:", pile.name)
				print("Drop rect:", drop_rect)
				print("Card global position:", global_position)
			
				var mouse_pos = get_viewport().get_mouse_position()
				if drop_rect.has_point(mouse_pos):

					print("Drop point is within pile:", pile.name)
					var is_foundation := pile.get_parent().name == "Foundations"
					var top_card := get_top_faceup_card(pile)
					print("Top card in pile:", top_card)
					
					if is_foundation:
						print("Pile is a foundation")
						print("Top card:", top_card)
						if top_card == null:
							print("Top card is null")
							if rank == 1 and drag_stack.size() == 1:
								print("Dropping Ace onto empty foundation")
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()

						elif top_card:
							print("Top card suit:", top_card.suit, "Top card rank:", top_card.rank)
							if top_card.suit == suit and top_card.rank == rank - 1 and drag_stack.size() == 1:
								print("Dropping card onto matching foundation")
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()
								break
					else:
						print("Pile is a tableau")
						print("Top card:", top_card)
						if top_card == null:
							print("Top card is null (empty pile)")
							if rank == 13:
								print("Dropping King onto empty tableau")
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()
								break
						elif top_card:
							print("Top card is face up:", top_card.is_face_up)
							print("Card rank:", rank, "Top card rank:", top_card.rank)
							print("Card suit:", suit, "Top card suit:", top_card.suit)
							print("Opposite color?", is_opposite_color(suit, top_card.suit))
							if top_card.is_face_up and is_opposite_color(suit, top_card.suit) and rank == top_card.rank - 1:
								print("Dropping card onto valid tableau stack")
								move_stack_to_pile(pile)
								dropped = true
								drag_stack.clear()
								break

	if not dropped:
		# Invalid drop, return to original pile
		move_stack_to_pile(original_pile)
		print("Invalid drop — returned to original pile")

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
	# Determine the base stack height (i.e., how many cards are already in the pile)
	var base_offset = 0
	for child in new_pile.get_children():
		if child.has_method("rank"):  # Identify actual card nodes
			base_offset += 1

	# Track the original pile before moving
	var original_pile = null
	if drag_stack.size() > 0:
		original_pile = drag_stack[0].current_pile

	# Reparent and position each card in drag_stack
	for i in drag_stack.size():
		var card = drag_stack[i]

		# Remove from old parent, add to new pile
		if card.get_parent():
			card.get_parent().remove_child(card)
		new_pile.add_child(card)

		# Position in pile (30 px down per card, starting from base_offset)
		card.position = Vector2(0, (base_offset + i) * 30)
		card.z_index = base_offset + i

		# Update card's metadata
		card.current_pile = new_pile
		card.is_dragging = false

		print("Moved card to pile:", new_pile.name, "at local pos:", card.position)

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
