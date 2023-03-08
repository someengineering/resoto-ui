extends PopupPanel


func _ready():
	_g.connect("connect_to_core", self, "hide")


func _on_ConnectionSettingsButton_pressed():
	_g.popup_manager.open_popup("ConnectPopup")
