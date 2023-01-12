extends Spatial

signal start_hovering
signal end_hovering

var value := 0.2

func _ready():
	$MeshInstance.mesh.height = value
	$MeshInstance.mesh.material.albedo_color = Color.red.blend(Color(0,0,1,value))
	$MeshInstance.translation -= $MeshInstance.transform.basis.y * (value / 2)
	$CollisionShape.translation -= $MeshInstance.transform.basis.y * (value / 2)
	$CollisionShape.shape.height = value

func _on_WorldMapColumn_mouse_entered():
	$MeshInstance.mesh.material.next_pass.set_shader_param("enabled", true)
	emit_signal("start_hovering")


func _on_WorldMapColumn_mouse_exited():
	$MeshInstance.mesh.material.next_pass.set_shader_param("enabled", false)
	emit_signal("end_hovering")
