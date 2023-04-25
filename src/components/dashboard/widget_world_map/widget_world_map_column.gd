extends Spatial

signal start_hovering
signal end_hovering
signal clicked(coordinates, cloud, region)

var value : float = 0.2
var coordinates : Vector2 = Vector2.ZERO
var cloud : String = ""
var region : String = ""
var hovering : bool = false

var height_scale := 0.7
var radius := 0.02

var min_color : Color = Color.purple
var max_color : Color = Color.orangered

func _input(event):
	if hovering and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		emit_signal("clicked", coordinates, cloud, region)

func _ready():
	$MeshInstance.mesh.height = value * height_scale
	$MeshInstance.mesh.top_radius = radius
	$MeshInstance.mesh.bottom_radius = radius
	max_color.a = value
	$MeshInstance.material_override.set_shader_param("albedo_color", min_color.blend(max_color))
	$MeshInstance.translation -= $MeshInstance.transform.basis.y * (value * height_scale / 2.0)
	$CollisionShape.translation -= $MeshInstance.transform.basis.y * (value * height_scale / 2.0)
	$CollisionShape.shape.height = value

func _on_WorldMapColumn_mouse_entered():
	$MeshInstance.material_override.next_pass.set_shader_param("enabled", true)
	hovering = true
	emit_signal("start_hovering")


func _on_WorldMapColumn_mouse_exited():
	$MeshInstance.material_override.next_pass.set_shader_param("enabled", false)
	hovering = false
	emit_signal("end_hovering")
