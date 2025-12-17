class_name FishAlmanac

extends Node2D

# intro : paper-> "you look at your almanac"
# help : "left to select a fishing_spot, right to navigate, top to quit".
# if empty -> paper -> "Your almanac is empty".
# if "top" pressed or at the end of almanac -> "close your almanac -> paper -> return to main menu

enum Menu {
	FISHING_SPOTS,
	FISH,
}

enum SubMenu {
	ITEM,
	RETURN,
	CLOSE,
}

var text_menu_index: int = 0

var voice_intro = load("res://sounds/voice_resources/fish_almanac/fish_almanac_open.tres")
var voice_empty = load("res://sounds/voice_resources/fish_almanac/fish_almanac_empty.tres")
var voice_help_places = load("res://sounds/voice_resources/fish_almanac/help_places.tres")
var voice_look_at_place = load("res://sounds/voice_resources/fish_almanac/look_at_place.tres")
var voice_help_fish = load("res://sounds/voice_resources/fish_almanac/help_fish.tres")
var voice_look_at_fish = load("res://sounds/voice_resources/fish_almanac/look_at_fish.tres")
var voice_close = load("res://sounds/voice_resources/fish_almanac/fish_almanac_select_close.tres")
var voice_return = load("res://sounds/voice_resources/fish_almanac/return_to_fishing_spots.tres")
var pause: VoiceArray = load("res://sounds/voice_resources/pause_1_s.tres")

var places_array := []
var fish_array := []
var place_menu_size: int
var fish_menu_size: int

var current_menu : Menu = Menu.FISHING_SPOTS
var current_sub_menu : SubMenu = SubMenu.ITEM
var current_place: Place.PlaceName
var current_fish = ""

var play_once := true
var descripting_fish := false

var inputs := true:
	set(value):
		inputs = value
		if value == true:
			print("almanac inputs true")
		else:
			print("alamanac inputs false")

# Called when the node enters the scene tree for the first time.
func _ready():
	Sound.stop_voice_array_and_queue()
	current_menu = Menu.FISHING_SPOTS
	places_array = Saves.data["fish_almanac"].keys()
	set_text_menu()
	scene_intro()


func _unhandled_input(event):
	if not inputs:
		return
	else:
		if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
			get_viewport().set_input_as_handled()
			Sound.stop_voice_array_and_queue()
			inputs = false
		#TODO Fix the menu_text
		if event.is_action_pressed("left"):
			get_viewport().set_input_as_handled()
			var change_menu := false
			if current_sub_menu == SubMenu.CLOSE:
				Signals.menu_selected.emit()
				await Signals.menu_closed
			#for all items, 
			else:
				Signals.menu_selected.emit()
				await Signals.menu_closed
				change_menu = true
			select_menu_item()
			if descripting_fish:
				await Sound.all_voices_finished
				Signals.fish_hide.emit()
				descripting_fish = false
			if change_menu:
				set_text_menu()
				inputs = true
		if event.is_action_pressed("right"):
			get_viewport().set_input_as_handled()
			iterate_through_menu()
			Signals.menu_index_changed.emit(text_menu_index)
			describe_menu_item()
			inputs = true
		if event.is_action_pressed("top"):
			get_viewport().set_input_as_handled()
			Signals.menu_index_changed.emit(text_menu_index)
			describe_menu_item()
			inputs = true



func scene_intro():
	if play_once:
		inputs = false
		Sound.play_se(Sound.effects["paper"])
		Sound.play_voice(Sound.voices["pause_1_s"])
		if not places_array.is_empty():
			Sound.play_voice(voice_intro)
			Sound.play_voice(Sound.voices["pause_0_5_s"])
			Sound.play_voice(voice_help_places)
			Sound.play_voice(Sound.voices["pause_1_s"])
			Sound.play_voice(voice_look_at_place)
			get_first_item()
			describe_menu_item()
			inputs = true
		else:
			Sound.play_voice(voice_empty)
			await Sound.all_voices_finished
			Signals.menu_selected.emit()
			await Signals.menu_closed
			main_menu()
		play_once = false




func main_menu():
	inputs = false
	Sound.play_se(Sound.effects["paper_reverse"])
	await Sound.all_se_finished
	Signals.scene_requested.emit("main_menu")
	if Sound.all_voices_finished.is_connected(main_menu):
		Sound.all_voices_finished.disconnect(main_menu)


func describe_menu_item():
	var audio
	if current_sub_menu == SubMenu.ITEM:
		if current_menu == Menu.FISHING_SPOTS:
			var place_res = Global.get_place_resource(current_place)
			audio = place_res.voice_name
		else: #current_menu == Menu.FISH
			var fish_res = get_fish_resource(current_place, current_fish)
			audio = fish_res.voice_name
	elif current_sub_menu == SubMenu.RETURN:
		audio = voice_return
	else: #current_sub_menu == SubMenu.CLOSE
		audio = voice_close
	Sound.play_voice(audio)


func select_menu_item():
	inputs = false
	if current_menu == Menu.FISHING_SPOTS:
		if current_sub_menu == SubMenu.CLOSE:
			main_menu()
		else: #current_sub_menu == SubMenu.ITEM
			current_menu = Menu.FISH
			Sound.play_voice(voice_look_at_fish)
			get_first_item()
			describe_menu_item()
	else:#current_menu == Menu.FISH
		if current_sub_menu == SubMenu.CLOSE:
			main_menu()
		elif current_sub_menu == SubMenu.RETURN:
			current_menu = Menu.FISHING_SPOTS
			get_first_item()
			Sound.play_voice(voice_look_at_place)
			describe_menu_item()
		else:#current_sub_menu == SubMenu.ITEM
			var fish_res = get_fish_resource(current_place, current_fish)
			Signals.fish_show.emit(fish_res)
			Sound.play_voice(fish_res.voice_description)
			descripting_fish = true


func set_text_menu():
	var text_menu_array: Array[String] = []
	if current_menu == Menu.FISHING_SPOTS:
		# create the text_menu_array
		for place in places_array:
			text_menu_array.append(Global.places[place].text_menu_name)
		text_menu_array.append("close almanac")
		# find the current index for the text_menu_array
		if current_sub_menu != SubMenu.ITEM:
			text_menu_index = text_menu_array.rfind("close almanac")
		else:
			text_menu_index = text_menu_array.find(Global.places[current_place].text_menu_name)
	if current_menu == Menu.FISH:
		text_menu_array.append_array(fish_array)
		text_menu_array.append_array(["return to f. spots", "close almanac"])
		# find the current index for the text_menu_array
		if current_sub_menu == SubMenu.CLOSE:
			text_menu_index = text_menu_array.rfind("close almanac")
		elif current_sub_menu == SubMenu.RETURN:
			text_menu_index = text_menu_array.rfind("return to f. spots")
		else:
			text_menu_index = text_menu_array.find(current_fish)
	Signals.menu_requested.emit(text_menu_array, text_menu_index)
	await Signals.menu_opened


func get_fish_resource(place: Place.PlaceName, fish_name : String) -> Fish:
	var fish_to_return : Fish = null
	var fishes_by_rar: Dictionary = Global.get_place_resource(place).fishes_by_rarity
	for rar in fishes_by_rar.keys():
		if fishes_by_rar[rar] == null:
			pass
		elif fishes_by_rar[rar].name == fish_name:
			fish_to_return = fishes_by_rar[rar]
	return fish_to_return


func iterate_through_menu():
	if current_menu == Menu.FISHING_SPOTS:
		if current_sub_menu == SubMenu.ITEM:
			var index := places_array.find(current_place)
			if index == -1:
				assert(false, "fish_almanac.gd, iterate_through_menu error, current place not in places_array")
			index += 1
			text_menu_index = index
			if index >= places_array.size():
				current_sub_menu = SubMenu.CLOSE
			else:
				current_place = places_array[index]
		elif current_sub_menu == SubMenu.CLOSE:
			get_first_item()
			text_menu_index = 0
	
	if current_menu == Menu.FISH:
		if current_sub_menu == SubMenu.ITEM:
			var index := fish_array.find(current_fish)
			if index == -1:
				assert(false, "fish_almanac.gd, iterate_through_menu error, current fish not in fish_array")
			index += 1
			text_menu_index = index
			if index >= fish_array.size():
				current_sub_menu = SubMenu.RETURN
			else:
				current_fish = fish_array[index]
		elif current_sub_menu == SubMenu.RETURN:
			current_sub_menu = SubMenu.CLOSE
			text_menu_index = fish_array.size() + 1
		else: #current_sub_menu == SubMenu.CLOSE
			get_first_item()
			text_menu_index = 0



func get_first_item():
	if current_menu == Menu.FISHING_SPOTS:
		current_place = Saves.data["fish_almanac"].keys()[0]
		current_sub_menu = SubMenu.ITEM
	if current_menu == Menu.FISH:
		current_fish = Saves.data["fish_almanac"][current_place][0]
		fish_array = Saves.data["fish_almanac"][current_place]
		current_sub_menu = SubMenu.ITEM
