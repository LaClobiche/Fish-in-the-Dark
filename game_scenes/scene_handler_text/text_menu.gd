extends Node2D

## to create a menu : emit "Signals.menu_requested(menu_array_of_strings, current_index_if_not_0)"
## before further usage, await "Signals.menu_opened"
## to navigate: emit "Signals.menu_index_changed(new_index)"
## to select a menu: emit "Signals.menu_selected()"
## to change scene after selection  : await "Signals.menu_closed"

enum ModulationMode {
	CONSTANT,
	DEGRESSIVE,
}

signal all_labels_freed

var _pending_frees := 0
var menu_items: Array = []
var menu_size: int
var menu_index: int = 0:
	set(value):
		menu_size = menu_items.size()
		menu_index = posmod(value, menu_size)
var labels_modulation: Dictionary
var labels_node: Array[Node]
var menu_open: bool = false

# tween time in sec
@export var tween_time := 0.25
# number of visible items in the menu
@export var label_number := 4
# index of the selected item in the menu
@export var selected_label_index := 0
# separation between labels
@export var label_separation:= 20.0
# y translation applied when a menu item is selected
@export var label_selection_offset := 20.0
# modulation mode for the non-selected items. CONSTANT or DEGRESSIVE
@export var labels_modulation_mode := ModulationMode.DEGRESSIVE
# modulation applied to the selected item
@export var labels_modulation_on := Color.WHITE
# modulation applied to the non-selected items in the CONSTANT mode
@export var labels_modulation_off := Color(1.0, 1.0, 1.0, 0.5)


@onready var menu_label := preload("res://game_scenes/scene_handler_text/text_menu/menu_label.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.menu_requested.connect(set_menu)
	Signals.menu_index_changed.connect(get_menu)
	Signals.menu_selected.connect(select_menu)
	create_modulation_dict()
#	set_menu(["commencer", "continuer", "options", "aide", "quitter"], 0) #debug
#
#
## debug func
#func _unhandled_input(event):
#	if event.is_action_pressed("left"):
#		print("resquested: menu index " + str(menu_index - 1) + " corresponding to " +str(menu_items[menu_index - 1]))
#		get_menu(menu_index - 1)
#	if event.is_action_pressed("right"):
#		print("resquested: menu index " + str(posmod(menu_index + 1, menu_size)) + " corresponding to " +str(menu_items[posmod(menu_index + 1, menu_size)]))
#		get_menu(menu_index + 1)
#	if event.is_action_pressed("top"):
#		select_menu()

func set_menu(menu_items_array: Array[String], menu_index_int:int = 0):
	if menu_open:
		reset_menu()
	else:
		menu_items = menu_items_array
		menu_index = menu_index_int
		var next_label_position := Vector2.ZERO
		for label_index in range(label_number):
			var item_index: int = posmod(menu_index + label_index - selected_label_index, menu_size)
			var new_label := menu_label.instantiate()
			labels_node.append(new_label)
			add_child(new_label)
			new_label.text = " " + menu_items[item_index] + " "
			new_label.position = next_label_position
			next_label_position = new_label.position + Vector2(new_label.size.x, 0.0) + Vector2(label_separation, 0)
		modulate_labels()
		menu_open = true
		Signals.menu_opened.emit()
		print("text_menu opened")


func select_menu():
	if not menu_open:
		return

	# Connecter AVANT de lancer les tweens pour éviter la course.
	_pending_frees = 0
	for l in labels_node:
		if is_instance_valid(l):
			_pending_frees += 1
			l.tree_exited.connect(_on_label_exited, CONNECT_ONE_SHOT)

	# Lance les animations + queue_free
	select_label()

	# Si rien à libérer (cas limite), ferme tout de suite.
	if _pending_frees == 0:
		reset_menu()
		return

	await all_labels_freed
	reset_menu()


func _on_label_exited() -> void:
	_pending_frees -= 1
	if _pending_frees <= 0:
		all_labels_freed.emit()


func get_menu(new_index: int):
	if not menu_open:
		return
	else:
		var previous_index := menu_index
		if new_index == previous_index:
			print("menu_text.gd, get_menu: return. new_index == menu_index")
			return
		var index_jump: int = get_index_closest_to_zero(new_index, previous_index, menu_size)
		var single_index_jump: int = -1 if index_jump < 0 else 1
		# for each single index jump
		for i in abs(index_jump):
			
			# set the new menu index
			menu_index += single_index_jump
			
			# set the new label values
			var new_label := menu_label.instantiate()
			var new_label_index := 0 if index_jump < 0 else label_number - 1
			print("new label index: " + str(new_label_index))
			var item_index: int = posmod(menu_index - selected_label_index + new_label_index, menu_size)
			print("new label has item index: " + str(menu_index - selected_label_index + new_label_index) + " corresponding to: " + menu_items[item_index])
			add_child(new_label)
			new_label.text = " " + menu_items[item_index] + " "
			new_label.position = Vector2(get_x_distance_to_label(label_number), 0.0) if index_jump > 0 else Vector2.ZERO - Vector2(new_label.size.x, 0)
			
			# move labels, erase the removed label from the labels_node array, add 
			if index_jump > 0:
				clear_label(labels_node.pop_front())
				labels_node.append(new_label)
				move_labels_left()
			else:
				clear_label(labels_node.pop_back())
				labels_node.insert(0, new_label)
				move_labels_right()
			modulate_labels()


func reset_menu():
	for child in get_children():
		child.queue_free()
	menu_index = 0
	menu_size = 0
	menu_items.clear()
	labels_node.clear()
	menu_open = false
	Signals.menu_closed.emit()
	print("text_menu closed")


func create_modulation_dict():
	if labels_modulation_mode == ModulationMode.CONSTANT:
		for i in range (label_number):
			labels_modulation[i] = labels_modulation_off
		labels_modulation[selected_label_index] = labels_modulation_on
	if labels_modulation_mode == ModulationMode.DEGRESSIVE:
		# dict for the value located to the right of the slected_label_index
		var degressive := 1.0
		for i in range(selected_label_index, label_number, 1):
			labels_modulation[i] = Color(1.0, 1.0, 1.0, degressive)
			degressive = degressive / 2
		# dict for the value located to the left of the slected_label_index
		degressive = 1.0
		for i in range(selected_label_index, -1, -1):
			labels_modulation[i] = Color(1.0, 1.0, 1.0, degressive)
			degressive = degressive / 2
		labels_modulation[selected_label_index] = labels_modulation_on


func clear_label(label: Label):
	var tween := create_tween()
	tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), tween_time).from_current()
	tween.tween_callback(label.queue_free)


func get_index_closest_to_zero(new_index:int, previous_index:int, indexes_size:int):
	var index_posmod =  posmod((new_index - previous_index), indexes_size)
	var index_mod = (new_index - previous_index) % indexes_size
	if index_posmod >= abs(index_mod):
		return index_mod
	else:
		return index_posmod


func get_x_distance_to_label(index:int) -> float:
	var distance := 0.0
	if index > 0:
		for i in range(index):
			distance += labels_node[i-1].size.x + label_separation
	return distance


func move_labels_right():
	var next_label_position_x := 0.0
	for label_index in range(label_number):
		move_label(labels_node[label_index], next_label_position_x)
		next_label_position_x += labels_node[label_index].size.x + label_separation


func move_labels_left():
	var next_label_position_x : float = labels_node[0].size.x
	for label_index in range(label_number):
		move_label(labels_node[label_index], next_label_position_x - labels_node[0].size.x)
		next_label_position_x += labels_node[label_index].size.x + label_separation


func modulate_labels():
	for label_index in range(label_number):
		if label_index == selected_label_index:
			move_child(labels_node[label_index], -1)
			labels_node[label_index].text = labels_node[label_index].text.erase(0, 1)
			labels_node[label_index].text = labels_node[label_index].text.erase(labels_node[label_index].text.length() - 1, 1)
			labels_node[label_index].text = "[" + labels_node[label_index].text + "]"
		else:
			labels_node[label_index].text = labels_node[label_index].text.replace("[", " ")
			labels_node[label_index].text = labels_node[label_index].text.replace("]", " ")
		var tween := create_tween()
		tween.tween_property(labels_node[label_index], "modulate", labels_modulation[label_index], tween_time).from_current()


func move_label(node: Node, new_x_position: float):
	var tween := create_tween()
	tween.tween_property(node, "position", Vector2(new_x_position, 0), tween_time).from_current()



func select_label():
	for i in range(label_number):
		var tween := create_tween()
		if i == selected_label_index:
			tween.tween_property(labels_node[i], "position", 
					labels_node[i].position - Vector2(0, label_selection_offset), tween_time)
			tween.tween_property(labels_node[i], "modulate", Color(1.0, 1.0, 1.0, 0.0), tween_time * 2).from_current()
		else:
			tween.tween_property(labels_node[i], "position", 
					labels_node[i].position + Vector2(0, label_selection_offset), tween_time)
			tween.tween_property(labels_node[i], "modulate", Color(1.0, 1.0, 1.0, 0.0), tween_time / 2).from_current()
		tween.tween_callback(labels_node[i].queue_free)
