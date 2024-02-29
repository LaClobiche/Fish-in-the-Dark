extends CanvasLayer


@onready var particle := $CPUParticles2D

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().size_changed.connect(set_particle_global_transform)
	RenderingServer.frame_post_draw.connect(set_particle_global_transform)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_particle_global_transform():
	if RenderingServer.frame_post_draw.is_connected(set_particle_global_transform):
		RenderingServer.frame_post_draw.disconnect(set_particle_global_transform)
	var rect: Rect2 = get_viewport().get_visible_rect()
	particle.position = rect.size / 2
	particle.emission_rect_extents = rect.size / 2
