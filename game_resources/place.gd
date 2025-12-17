class_name Place

extends Resource

## places from nearest to farthest
enum PlaceName {
	FLOWING_WATERS_TUTO,
	LONELY_WATERS,
	EVERWATCHING_COVE,
	SWALLOWING_VORTEX,
	BREACH,
}

@export var name: PlaceName
@export var text_menu_name: String
@export var voice_name: VoiceResource
@export var fishes_by_rarity: Dictionary = {
	0 : null, 
	1 : null,
	2 : null,
	3 : null,
}


func _init(p_name = PlaceName.FLOWING_WATERS_TUTO, p_text_menu_name = "", p_voice_name = null, p_fishes_by_rarity = {}):
	name = p_name
	text_menu_name = p_text_menu_name
	voice_name = p_voice_name
	fishes_by_rarity = p_fishes_by_rarity
