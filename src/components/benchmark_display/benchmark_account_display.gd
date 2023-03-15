class_name BenchmarkAccountDisplay
extends BenchmarkCollectionDisplay

signal expand_all

var account_id : String = ""


func _on_Expand_pressed():
	emit_signal("expand_all")
