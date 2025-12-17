extends Node2D

#### constant variables ####

## dict with Place.PlaceName corresponding to Place resource 
var places := {
	Place.PlaceName.FLOWING_WATERS_TUTO : load("res://places_and_fishes/flowing_waters_tuto.tres"),
	Place.PlaceName.LONELY_WATERS : load("res://places_and_fishes/lonely_waters.tres"),
	Place.PlaceName.EVERWATCHING_COVE : load("res://places_and_fishes/everwatching_cove.tres"),
	Place.PlaceName.SWALLOWING_VORTEX : load("res://places_and_fishes/swallowing_vortex.tres"),
	Place.PlaceName.BREACH : load("res://places_and_fishes/breach.tres")
}

#### variables determined when the game launches, in scene_handler ####

var touchscreen: bool = DisplayServer.is_touchscreen_available()
var debug: bool = OS.is_debug_build()

#### variables changes through the game ####

var last_menu_item: int = 0
## Setted in casting.gd at _unhandled_input(). Reinitialised at the end of a run. 
var current_fish: Fish:
	get:
		if current_fish == null:
			print("Global.gd, current_fish.get, error: is null, returning Flowfish")
			current_fish = load("res://places_and_fishes/flowing_waters_tuto/1_flowfish.tres")
		return current_fish
## Reinitialised at the end of a run.
var current_fishing_rod: FishingRod = FishingRod.new()
## Setted in casting.gd at cast_end(). Reinitialised at the end of a run.
var current_place: Place:
	get:
		if current_place == null:
			print("Global.gd, current_place.get, error: is null, returning Flowing Waters")
			current_place = load("res://places_and_fishes/flowing_waters_tuto.tres")
		return current_place
## almanac used when doing a run if Saves.game_finished = true
var temporary_almanac := {}

#### functions ####


## add the fish the the almanac
func add_to_fish_almanac(place_name: Place.PlaceName, fish_name: String):
	var fish_almanac: Dictionary = Saves.data["fish_almanac"]
	if Saves.data["game_finished"] == true:
		fish_almanac = temporary_almanac
	if place_name not in fish_almanac.keys():
		fish_almanac[place_name] = [fish_name]
	else:
		if fish_name not in fish_almanac[place_name]:
			fish_almanac[place_name].append(fish_name)
	Saves.save_game()


## return the Place resource corresponding to given Place.PlaceName
func get_place_resource(place_name: Place.PlaceName) -> Place:
	if place_name in places:
		return places[place_name]
	else:
		assert(false, "Global.gd, get_place_resource(): PlaceName " + str(place_name) + " not in places")
		return null


## return null if the place_name is completed.
## please check is_place_name_completed first and change place_name if needed.
func get_next_fish(place_name: Place.PlaceName) -> Fish:
	var place := get_place_resource(place_name)
	var fish_almanac: Dictionary = Saves.data["fish_almanac"]
	#temporary almanac used for run after the demo is finished.
	if Saves.data["game_finished"] == true:
		fish_almanac = temporary_almanac
	# if the place_name is not yet registered, return the first fish (sorted by rarity)
	if place_name not in fish_almanac.keys():
		if place.fishes_by_rarity[0] != null:
			return place.fishes_by_rarity[0]
		else:
			assert(false, "Global.gd, get_next_fish: not Fish resource associated to place.fishes_by_rarity[0]")
			return null
	else:
		var next_fish_rarity: int = fish_almanac[place_name].size()
		if next_fish_rarity == 4:
			print("Global.gd, get_next_fish: null returned, place num "+ str(place_name) + " completed")
			return null
		elif place.fishes_by_rarity[next_fish_rarity] != null:
			return place.fishes_by_rarity[next_fish_rarity]
		else:
			assert(false, "Global.gd, get_next_fish: not Fish resource associated to place.fishes_by_rarity[" + str(next_fish_rarity) + "]")
			return null


## return the centered side or the center of the viewport according to given direction.
func get_viewport_directed_position(direction: Vector2i) -> Vector2:
	direction = direction.clamp(-Vector2i.ONE, Vector2i.ONE)
	var viewport_r: Rect2 = Rect2(0,0, 1280, 720)
	var viewport_origin := viewport_r.position
	var viewport_center := viewport_r.get_center()
	var x_position: float = 0.0
	var y_position: float = 0.0
	if direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
		y_position = viewport_origin.y + (viewport_r.size.y / 2)
		x_position = ((viewport_r.size.x / 2) * direction.x) + viewport_center.x
	elif direction == Vector2i.UP or direction == Vector2i.DOWN:
		x_position = viewport_origin.x + (viewport_r.size.x / 2)
		y_position = ((viewport_r.size.y / 2) * direction.y) + viewport_center.y
	else:# Vector2i.ZEROor Vector2i.ONE
		x_position = viewport_center.x
		y_position = viewport_center.y
	return Vector2(x_position,y_position)


## return true if the place_name is completed
func is_place_name_completed(place_name: Place.PlaceName) -> bool:
	var fish_almanac: Dictionary = Saves.data["fish_almanac"]
	if Saves.data["game_finished"] == true:
		fish_almanac = temporary_almanac
	if place_name in fish_almanac.keys():
		if fish_almanac[place_name].size() == 4:
			return true
		else:
			return false
	else:
		return false


## set current Fish resource associated with current PlaceName
func set_current_fish():
	current_fish = get_next_fish(current_place.name)
	if current_fish == null:
		print("Global.gd, set_current_fish() error: fish is null. Flowfisg setted")
		current_fish = load("res://places_and_fishes/flowing_waters/1_flowfish.tres")


## set places_not_completed array with place_name not completed
func get_places_not_completed() -> Array[Place.PlaceName]:
	var array_to_return: Array[Place.PlaceName] = []
	for place_name in Place.PlaceName:
		if not Global.is_place_name_completed(Place.PlaceName[place_name]): 
			array_to_return.append(Place.PlaceName[place_name])
	return array_to_return
