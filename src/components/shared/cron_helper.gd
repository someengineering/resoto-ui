extends PanelContainer

const AllowedValues : Dictionary = {
	"all" : [
		["*", "any value"],
		[",", "value list separator"],
		["-", "range of values"],
		["/", "step values"]
	],
	"minute" : [
		["0-59", "allowed values"],
	],
	"hour" : [
		["0-23", "allowed values"],
	],
	"day-month" : [
		["1-31", "allowed values"],
	],
	"month" : [
		["1-12", "allowed values"],
		["JAN-DEC", "alternative single values"],
	],
	"day-week" : [
		["0-6", "allowed values"],
		["SUN-SAT", "alternative single values"],
	]
}

const CronTooltipText : String = "[b]Some examples for cron expressions:[/b]\n\n" \
	+ "Every fifteen minutes\n[code]*/15 * * * *[/code]\n\n" \
	+ "Once a day at 12:00\n[code]0 12 * * *[/code]\n\n" \
	+ "Every Monday at 00:00\n[code]0 0 * * MON[/code]\n\n" \
	+ "Every first day of the month\n[code]0 0 1 * *[/code]\n\n" \
	+ "Every Friday at 10:00 and 20:00\n[code]0 10,20 * * FRI[/code]\n\n" \
	+ "At minute 30 from hour 6 to 18 on Mo-Fr\n[code]*/30 6-18 * * 1-5[/code]\n\n" \
	+ "If you need more help on cron expressions, you can visit [b]https://crontab.guru[/b], a great learning resource, by clicking here."

signal finished

onready var help_grid = $"%HelpGrid"
var target_node : Node = null


func _ready():
	$"%MinLineEdit".connect("focus_entered", self, "refresh_help", ["minute", $"%MinLineEdit"])
	$"%HourLineEdit".connect("focus_entered", self, "refresh_help", ["hour", $"%HourLineEdit"])
	$"%DayMLineEdit".connect("focus_entered", self, "refresh_help", ["day-month", $"%DayMLineEdit"])
	$"%MonthLineEdit".connect("focus_entered", self, "refresh_help", ["month", $"%MonthLineEdit"])
	$"%DayWLineEdit".connect("focus_entered", self, "refresh_help", ["day-week", $"%DayWLineEdit"])
	
	$"%MinLineEdit".connect("text_entered", self, "pressed_enter")
	$"%HourLineEdit".connect("text_entered", self, "pressed_enter")
	$"%DayMLineEdit".connect("text_entered", self, "pressed_enter")
	$"%MonthLineEdit".connect("text_entered", self, "pressed_enter")
	$"%DayWLineEdit".connect("text_entered", self, "pressed_enter")
	refresh_help("")


func refresh_help(selected:String, node:Node = null):
	for c in help_grid.get_children():
		c.queue_free()
	
	for row in AllowedValues.all:
		create_help_element(row)
	
	if AllowedValues.has(selected):
		for row in AllowedValues[selected]:
			create_help_element(row)
	
	yield(VisualServer, "frame_post_draw")
	if node != null and node.has_method("select_all"):
		node.select_all()


func create_help_element(info:Array):
	var left_side := Label.new()
	left_side.align = Label.ALIGN_RIGHT
	left_side.size_flags_horizontal = SIZE_EXPAND_FILL
	left_side.theme_type_variation = "LabelCodeBold"
	left_side.text = info[0]
	help_grid.add_child(left_side)
	
	var right_side := Label.new()
	right_side.text = info[1]
	right_side.size_flags_horizontal = SIZE_EXPAND_FILL
	help_grid.add_child(right_side)


func popup(_expression:String, _position:=Vector2.ZERO, _target_node:Node=null):
	rect_global_position = _position
	target_node = _target_node
	var split_expr : Array = _expression.split(" ")
	if split_expr.size() < 5:
		$"%MinLineEdit".text = "*"
		$"%HourLineEdit".text = "*"
		$"%DayMLineEdit".text = "*"
		$"%MonthLineEdit".text = "*"
		$"%DayWLineEdit".text = "*"
	else:
		$"%MinLineEdit".text = split_expr[0]
		$"%HourLineEdit".text = split_expr[1]
		$"%DayMLineEdit".text = split_expr[2]
		$"%MonthLineEdit".text = split_expr[3]
		$"%DayWLineEdit".text = split_expr[4]
	show()


func create_cron_expression() -> String:
	var cron_expression : String = "%s %s %s %s %s" % [$"%MinLineEdit".text, $"%HourLineEdit".text, $"%DayMLineEdit".text, $"%MonthLineEdit".text, $"%DayWLineEdit".text]
	return cron_expression


func _on_AllDataCopyButton_pressed():
	_g.emit_signal("text_to_clipboard", create_cron_expression())


func pressed_enter(_t:String):
	_on_AcceptButton_pressed()


func _on_AcceptButton_pressed():
	emit_signal("finished", create_cron_expression(), target_node)
	hide()


func _on_IconButton_mouse_entered():
	_g.emit_signal("tooltip", CronTooltipText)


func _on_IconButton_mouse_exited():
	_g.emit_signal("tooltip_hide")


func _on_IconButton_pressed():
	OS.shell_open("https://crontab.guru/#" + create_cron_expression().replace(" ", "_"))
	_g.emit_signal("tooltip_hide")


func _on_CloseButton_pressed():
	target_node = null
	hide()
