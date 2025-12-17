extends FishAlmanac

@onready var sound: Node = get_node("../Sound")

# Called when the node enters the scene tree for the first time.
func _ready():
	inputs = false

func launch():
	play_once = true
	sound.stop_voice_array_and_queue()
	current_menu = Menu.FISHING_SPOTS
	places_array = Saves.data["fish_almanac"].keys()
	set_text_menu()
	scene_intro()


func main_menu():
	inputs = false
	sound.play_se(sound.effects["paper_reverse"])
	if sound.all_voices_finished.is_connected(main_menu):
		sound.all_voices_finished.disconnect(main_menu)
	get_parent().set_text_menu()
	get_parent().inputs = true



func _unhandled_input(event):
	if not inputs:
		return
	else:
		if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
			sound.stop_voice_array_and_queue()
		#TODO Fix the menu_text
		if event.is_action_pressed("left"):
			var change_menu := false
			if current_sub_menu == SubMenu.CLOSE:
				inputs = false
				Signals.menu_selected.emit()
				await Signals.menu_closed
				print("pause_almanac: menu closed awaited, main menu requested")
			# for all items, 
			else:
				inputs = false
				Signals.menu_selected.emit()
				await Signals.menu_closed
				inputs = true
				change_menu = true
				print("pause_almanac: menu closed awaited, new menu requested")
			select_menu_item()
			if change_menu:
				set_text_menu()
		if event.is_action_pressed("right"):
			iterate_through_menu()
			Signals.menu_index_changed.emit(text_menu_index)
			describe_menu_item()
		if event.is_action_pressed("top"):
			Signals.menu_index_changed.emit(text_menu_index)
			describe_menu_item()
		get_viewport().set_input_as_handled()

func scene_intro():
	if play_once:
		inputs = false
		sound.play_se(sound.effects["paper"])
		sound.play_voice(sound.voices["pause_1_s"])
		if not places_array.is_empty():
			sound.play_voice(voice_intro)
			sound.play_voice(sound.voices["pause_0_5_s"])
			sound.play_voice(voice_help_places)
			sound.play_voice(sound.voices["pause_1_s"])
			sound.play_voice(voice_look_at_place)
			get_first_item()
			describe_menu_item()
			inputs = true
		else:
			sound.play_voice(voice_empty)
			await sound.all_voices_finished
			Signals.menu_selected.emit()
			await Signals.menu_closed
			main_menu()
		play_once = false
	else:
		inputs = true


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
	sound.play_voice(audio)


func select_menu_item():
	if current_menu == Menu.FISHING_SPOTS:
		if current_sub_menu == SubMenu.CLOSE:
			main_menu()
		else: #current_sub_menu == SubMenu.ITEM
			current_menu = Menu.FISH
			sound.play_voice(voice_look_at_fish)
			get_first_item()
			describe_menu_item()
	else:#current_menu == Menu.FISH
		if current_sub_menu == SubMenu.CLOSE:
			main_menu()
		elif current_sub_menu == SubMenu.RETURN:
			current_menu = Menu.FISHING_SPOTS
			get_first_item()
			sound.play_voice(voice_look_at_place)
			describe_menu_item()
		else:#current_sub_menu == SubMenu.ITEM
			var fish_res = get_fish_resource(current_place, current_fish)
			sound.play_voice(fish_res.voice_description)


