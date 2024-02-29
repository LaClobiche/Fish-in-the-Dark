extends Node

## this AUTOLOAD script contains the variables to save and the save/load fucntions

#### variables to save ####

var data := {
	"options" : {
		"helper" : true,
		},
	"game_finished" : false,
	## dict with PlaceName associated with array of fish_name that have been fished.
	"fish_almanac" : {}
}
var audio: AudioBusLayout

#### save_file ####


const SAVE_FILE1 := "user://savegame.save"
const SAVE_FILE2 := "user://savegame.tres"

#### functions ####


# Called when the node enters the scene tree for the first time.
func _ready():
	load_game()
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables.
func save_game():
	var savegame = FileAccess.open(SAVE_FILE1, FileAccess.WRITE)
	if savegame == null:
		print("Error when writing save: " + str(FileAccess.get_open_error()))
	# Call the node's save function.
	var node_data = data
	# JSON provides a static method to serialized JSON string.
	var json_string = JSON.stringify(node_data)
	# Store the save dictionary as a new line in the save file.
	savegame.store_line(json_string)
	print("saving successful at " + SAVE_FILE1)
	# save the audio resource
	if audio != null:
		if not ResourceSaver.save(audio, SAVE_FILE2):
			print("loading successful at " + SAVE_FILE2)
	savegame.close()
	



# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game():
	if not FileAccess.file_exists(SAVE_FILE1):
		print("save not found in" + SAVE_FILE1 +". Creating a new save")
		save_game()
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var savegame = FileAccess.open(SAVE_FILE1, FileAccess.READ)
	if savegame == null:
		print("Error when reading save: " + str(FileAccess.get_open_error()))
	while savegame.get_position() < savegame.get_length():
		var json_string = savegame.get_line()
		# Creates the helper class to interact with JSON
		var json = JSON.new()
		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		# Get the data from the JSON object
		var node_data = json.get_data()
		# re-assign dict keys that aren't strings. Beacause they are saved as strings with json.
		if node_data.has_all(data.keys()):
			copy_values(node_data)
		else:
			print("save data in " + SAVE_FILE1 + " don't match the target dictionnary. Recreate a proper save")
			save_game()
	print("loading successful at " + SAVE_FILE1)
	# load the audio resource:
	if ResourceLoader.exists(SAVE_FILE2):
		audio = load(SAVE_FILE2)
		if audio != null:
			AudioServer.set_bus_layout(audio)
		print("loading successful at " + SAVE_FILE2)
	return true


func copy_values(from):
	data["options"] = from["options"]
	data["game_finished"] = from["game_finished"]
	for key in from["fish_almanac"].keys():
		var place : Place.PlaceName = key.to_int()
		data["fish_almanac"][place] = from["fish_almanac"][key]
