class_name Fish

extends Resource

@export_group("Name")
@export var name: String
@export var voice_name: AudioStream
@export var voice_name_caught: AudioStream

@export_group("Description")
@export var description: String
@export var voice_description: AudioStream

@export_group("Properties")
@export var rarity: int

@export_group("luring")
@export var luring_scene: PackedScene

@export_group("catching")
@export var catching_sequence: Animation


func _init(p_name = "", p_voice_name = null,
		p_voice_name_caught = null, p_description = "", p_voice_description = null,
		p_rarity = 0,p_luring_scene = null, p_catching_sequence = null):
	name = p_name
	voice_name = p_voice_name
	voice_name_caught = p_voice_name_caught
	description = p_description
	voice_description = p_voice_description
	rarity = p_rarity
	luring_scene = p_luring_scene
	catching_sequence = p_catching_sequence
