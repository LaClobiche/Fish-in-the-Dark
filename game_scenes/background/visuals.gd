extends CanvasLayer

const CYCLE_TIME := 360.0

@onready var particle := $BackgroungViewport/CPUParticles2D
@onready var animation_player := $AnimationPlayer
@onready var background_color := $BackgroungViewport/BackgroundColor
@onready var glitch := $Glitch
@onready var flash := $Flash
@onready var vortex_particle := $BackgroungViewport/VortexParticle
@onready var fish := $BackgroungViewport/Fish
@onready var breach := $BackgroungViewport/Breach

@onready var rod_tip = $FishingRodTip
@onready var lure = $Lure
@onready var line = $BackgroungViewport/FishingRod/Line

var background_hue := randf_range(0.0,1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	fish.position = Vector2(0,720)
	line.hide()
	breach.hide()
	vortex_particle.hide()
	glitch.hide()
	Signals.fade_out_black.connect(animation_player.play.bind("eye_opening"))
	Signals.fade_in_black.connect(animation_player.play_backwards.bind("eye_opening"))
	Signals.glitch_hide.connect(glitch.hide)
	Signals.glitch_show.connect(glitch.show)
	Signals.fish_hide.connect(fish_hide)
	Signals.fish_show.connect(fish_show)
	Signals.breach_panel_hide.connect(breach.hide)
	Signals.breach_panel_show.connect(breach.show)
	Signals.vortex_particle_hide.connect(vortex_particle.hide)
	Signals.vortex_particle_show.connect(vortex_particle.show)
	Signals.flash.connect(show_flash)
	Signals.lure_position.connect(set_lure_position)
	Signals.casting_lure.connect(casting_lure)
	get_viewport().size_changed.connect(set_particle_global_transform)
	RenderingServer.frame_post_draw.connect(set_particle_global_transform)


func _process(delta):
	background_hue = fposmod(background_hue + delta / CYCLE_TIME, 1.0)
	background_color.color = Color.from_hsv(background_hue, 0.5, 0.75)
	line.clear_points()
	line.add_point(rod_tip.global_position)
	line.add_point(lure.global_position)


func set_particle_global_transform():
	if RenderingServer.frame_post_draw.is_connected(set_particle_global_transform):
		RenderingServer.frame_post_draw.disconnect(set_particle_global_transform)
	var rect: Rect2 = get_viewport().get_visible_rect()
	particle.position = rect.size / 2
	particle.emission_rect_extents = rect.size / 2

func show_flash():
	var tween := create_tween()
	tween.tween_property(flash, "modulate", Color.WHITE, 0.2).from_current()
	tween.tween_interval(0.1)
	tween.tween_property(flash, "modulate", Color.TRANSPARENT, 0.2).from_current()

func fish_show(fish_resource: Fish):
	if fish_resource == null:
		print("visuals.gd: fish_show() error: fish_resource == null")
		return
	else:
		fish.texture = fish_resource.picture
		
		var tween = create_tween().set_ease(Tween.EASE_OUT)
		tween.tween_property(fish, "position", Vector2.ZERO, 0.5).from_current()

func fish_hide():
		var tween = create_tween().set_ease(Tween.EASE_IN)
		tween.tween_property(fish, "position", Vector2(0,720), 0.5).from_current()

func set_lure_position(global_position: Vector2):
	lure.global_position = global_position

func casting_lure():
	lure.global_position = Vector2(600, -100)
	line.show()
	var tween := create_tween()
	tween.tween_property(lure, "global_position", Vector2(640, 570), 0.2).from_current()
