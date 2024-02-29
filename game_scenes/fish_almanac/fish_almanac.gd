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

var voice_intro = load("res://sounds/voice_resources/fish_almanac/fish_almanac_open.mp3")
var voice_empty = load("res://sounds/voice_resources/fish_almanac/fish_almanac_empty.tres")
var voice_help_places = load("res://sounds/voice_resources/fish_almanac/help_places.mp3")
var voice_look_at_place = load("res://sounds/voice_resources/fish_almanac/look_at_place.mp3")
var voice_help_fish = load("res://sounds/voice_resources/fish_almanac/help_fish.mp3")
var voice_look_at_fish = load("res://sounds/voice_resources/fish_almanac/look_at_fish.mp3")
var voice_close = load("res://sounds/voice_resources/fish_almanac/fish_almanac_select_close.tres")
var voice_return = load("res://sounds/voice_resources/fish_almanac/return_to_fishing_spots.mp3")
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

# Called when the node enters the scene tree for the first time.
func _ready():
	Sound.stop_voice_array_and_queue()
	current_menu = Menu.FISHING_SPOTS
	places_array = Saves.data["fish_almanac"].keys()
	scene_intro()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _unhandled_input(event):
	if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
		Sound.stop_voice_array_and_queue()
	if event.is_action_pressed("left"):
		select_menu_item()
	if event.is_action_pressed("right"):
		iterate_through_menu()
		describe_menu_item()
	if event.is_action_pressed("top"):
		describe_menu_item()


func scene_intro():
	if play_once:
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
		else:
			Sound.play_voice(voice_empty)
			Sound.all_voices_finished.connect(main_menu)
		play_once = false



func main_menu():
	Sound.play_se(Sound.effects["paper_reverse"])
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
			Sound.all_voices_finished.connect(main_menu)
		elif current_sub_menu == SubMenu.RETURN:
			current_menu = Menu.FISHING_SPOTS
			get_first_item()
			Sound.play_voice(voice_look_at_place)
			describe_menu_item()
		else:#current_sub_menu == SubMenu.ITEM
			var fish_res = get_fish_resource(current_place, current_fish)
			Sound.play_voice(fish_res.voice_description)


func get_fish_resource(place: Place.PlaceName, fish_name : String) -> Fish:
	var fish_to_return : Fish = null
	var fishes_by_rar: Dictionary = Global.get_place_resource(place).fishes_by_rarity
	for rar in fishes_by_rar.keys():
		if fishes_by_rar[rar].name == fish_name:
			fish_to_return = fishes_by_rar[rar]
	return fish_to_return


func iterate_through_menu():
	if current_menu == Menu.FISHING_SPOTS:
		if current_sub_menu == SubMenu.ITEM:
			var index := places_array.find(current_place)
			if index == -1:
				assert(false, "fish_almanac.gd, iterate_through_menu error, current place not in places_array")
			index += 1
			if index >= places_array.size():
				current_sub_menu = SubMenu.CLOSE
			else:
				current_place = places_array[index]
		elif current_sub_menu == SubMenu.CLOSE:
			get_first_item()
	
	if current_menu == Menu.FISH:
		if current_sub_menu == SubMenu.ITEM:
			var index := fish_array.find(current_fish)
			if index == -1:
				assert(false, "fish_almanac.gd, iterate_through_menu error, current fish not in fish_array")
			index += 1
			if index >= fish_array.size():
				current_sub_menu = SubMenu.RETURN
			else:
				current_fish = fish_array[index]
		elif current_sub_menu == SubMenu.RETURN:
			current_sub_menu = SubMenu.CLOSE
		else: #current_sub_menu == SubMenu.CLOSE
			get_first_item()



func get_first_item():
	if current_menu == Menu.FISHING_SPOTS:
		current_place = Saves.data["fish_almanac"].keys()[0]
		current_sub_menu = SubMenu.ITEM
	if current_menu == Menu.FISH:
		current_fish = Saves.data["fish_almanac"][current_place][0]
		fish_array = Saves.data["fish_almanac"][current_place]
		current_sub_menu = SubMenu.ITEM
