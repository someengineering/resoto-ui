extends Button

var tag_keys:Array = []
var node_id:String = ""
var is_phantom:bool = false setget set_is_phantom
var is_cleaned:bool = false setget set_is_cleaned
var is_desired_cleaned:bool = false setget set_is_desired_cleaned
var is_protected:bool = false setget set_is_protected


func set_is_phantom(_is_phantom:bool):
	is_phantom = _is_phantom
	$VBox/Top/Icons/NodeIconPhantom.visible = is_phantom


func set_is_cleaned(_is_cleaned:bool):
	is_cleaned = _is_cleaned
	$VBox/Top/Icons/NodeIconCleaned.visible = is_cleaned


func set_is_desired_cleaned(_is_desired_cleaned:bool):
	is_desired_cleaned = _is_desired_cleaned
	$VBox/Top/Icons/NodeIconDesiredClean.visible = is_desired_cleaned


func set_is_protected(_is_protected:bool):
	is_protected = _is_protected
	$VBox/Top/Icons/NodeIconProtected.visible = is_protected
