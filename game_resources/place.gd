class_name Place

extends Resource

## places from nearest to farthest
enum PlaceName {
	FLOWING_WATERS_TUTO,
	LONELY_WATERS,
	EVERWATCHING_COVE,
}


@export var name: PlaceName
@export var voice_name: AudioStream
@export var fishes_by_rarity: Dictionary = {
	0 : null, 
	1 : null,
	2 : null,
	3 : null,
}


func _init(p_name = PlaceName.FLOWING_WATERS_TUTO, p_voice_name = null, p_fishes_by_rarity = {}):
	name = p_name
	voice_name = p_voice_name
	fishes_by_rarity = p_fishes_by_rarity
