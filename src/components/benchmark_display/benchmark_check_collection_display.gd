extends HBoxContainer
class_name BenchmarkCollectionDisplay

enum TYPES {BENCHMARK, COLLECTION}

const Icons := {
	TYPES.BENCHMARK : preload("res://assets/icons/icon_128_benchmark.svg"),
	TYPES.COLLECTION: preload("res://assets/icons/icon_128_folder.svg"),
}

var title : String = "" setget set_title
var passed : bool = false setget set_passed
var passing_n : int = 0 setget set_passing_n
var failing_n : int = 0 setget set_failing_n
var description : String
var id : String

func _ready():
	connect("resized", self, "_on_BenchmarkCheckCollectionDisplay_resized")

func _draw():
	var start : Vector2 = $Label.get_font("font").get_string_size($Label.text) + $Label.rect_position - Vector2(-5, $Label.rect_size.y / 2.0)
	var end : Vector2 =  Vector2($FailingVsPassingWidget.rect_position.x, start.y)
	if start.x < end.x:
		draw_line(start, end, Color("#0f3356"))

func set_title(_title : String):
	title = _title
	$Label.text = title
	
func set_passed(_passed : bool):
	passed = _passed
	$CollectionIcon.modulate = Color("#44f470") if passed else Color("#f44444")
#	$Passed.visible = passed
#	$Failed.visible = !passed
	
func set_passing_n(n : int):
	passing_n = n
	$FailingVsPassingWidget.passing_n = n
	
	self.passed = failing_n == 0
	
func set_failing_n(n : int):
	failing_n = n
	self.passed = n == 0
	$FailingVsPassingWidget.failing_n = n

func set_label_variation(variation: String):
	$Label.theme_type_variation = variation

func set_collection_icon(type : int):
	$CollectionIcon.texture = Icons[type]


func _on_BenchmarkCheckCollectionDisplay_resized():
	yield(VisualServer, "frame_post_draw")
	update()
