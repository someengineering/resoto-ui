extends Control

onready var tween = $Tween
onready var anim_player_head = $AnimationPlayerHead
onready var anim_player_cloud = $AnimationPlayerCloud

var loading: bool = false
var console: RichTextLabel = null

func start() -> void:
	show()
	loading = true
	tween.remove_all()
	tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.2)
	tween.interpolate_property(console, "self_modulate", console.self_modulate, Color(0.3, 0.3, 0.3, 0.5), 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.1)
	tween.start()
	anim_player_cloud.play("loading")
	anim_player_head.play("loading")


func stop() -> void:
	loading = false
	tween.remove_all()
	tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(console, "self_modulate", console.self_modulate, Color.white, 0.8, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()


func _on_Tween_tween_all_completed() -> void:
	if loading:
		return
	hide()
	console.self_modulate = Color.white
	modulate.a = 0
	anim_player_cloud.stop(true)
	anim_player_head.stop(true)
