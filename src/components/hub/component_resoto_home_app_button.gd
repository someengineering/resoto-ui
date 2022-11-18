extends ToolButton
tool

export (String) var app_name := "Resoto App" setget set_app_name
export (Texture) var app_icon : Texture setget set_app_icon


func _ready():
	$VBox/Label.text = app_name
	$VBox/IconCenter/Icon.texture = app_icon
	modulate = Color(0.8, 0.85, 0.85, 1.0)
	connect("mouse_entered", self, "_on_mouse_entered") 
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("pressed", self, "_on_pressed")


func _on_mouse_entered() -> void:
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate", modulate, Color.white, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.interpolate_property($VBox/IconCenter/Icon, "rect_scale", $VBox/IconCenter/Icon.rect_scale, Vector2(1.08, 1.08), 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()


func _on_mouse_exited() -> void:
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate", modulate, Color(0.8, 0.85, 0.85, 1.0), 1.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.interpolate_property($VBox/IconCenter/Icon, "rect_scale", $VBox/IconCenter/Icon.rect_scale, Vector2(1.00, 1.00), 1.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()


func _on_pressed() -> void:
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate", modulate, Color(0.8, 0.85, 0.85, 1.0), 1.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.interpolate_property($VBox/IconCenter/Icon, "rect_scale", $VBox/IconCenter/Icon.rect_scale, Vector2(1.00, 1.00), 1.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()


func set_app_name(_app_name:String) -> void:
	app_name = _app_name
	$VBox/Label.text = app_name


func set_app_icon(_app_icon:Texture) -> void:
	app_icon = _app_icon
	$VBox/IconCenter/Icon.texture = app_icon
