extends HBoxContainer


onready var zoom_label = $LabelSpacer/Control/Attach/ZoomScaleLabel
onready var zoom_spacer = $LabelSpacer
onready var zoom_scaler = $LabelSpacer/Control/Attach


func _ready():
	get_tree().root.connect("size_changed", self, "on_ui_scale_changed")
	_g.connect("ui_scale_changed", self, "on_ui_scale_changed")


func _on_ButtonUIScaleMinus_pressed():
	_g.emit_signal("ui_scale_decrease")


func _on_ButtonUIScalePlus_pressed():
	_g.emit_signal("ui_scale_increase")


func on_ui_scale_changed():
	zoom_label.text = str(_g.ui_scale*100) + "%"
	zoom_spacer.rect_min_size.x = 45 / _g.ui_scale
	zoom_scaler.scale = Vector2.ONE / _g.ui_scale
	$ButtonUIScaleMinus.rect_min_size.x = 24 / _g.ui_scale
	$ButtonUIScalePlus.rect_min_size.x = 24 / _g.ui_scale
