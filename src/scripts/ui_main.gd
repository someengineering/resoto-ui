extends Control


func _ready() -> void:
	SaveLoadSettings.connect("settings_loaded", self, "show_connect_popup", [], 4)
	SaveLoadSettings.load_settings()
	
	
func show_connect_popup() -> void:
	_g.popup_manager.open_popup("ConnectPopup")
	
	# If we ever need Godot to receive URL parameters:
#	var custom_parameter = JavaScript.eval("getParameter('custom_parameter')")
