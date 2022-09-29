extends PopupPanel

signal update_operator

enum PropertyOperators {equal, not_equal, less, less_equal, 
	greater, greater_equal, regex, regex_not, in_o, not_in_o}

onready var button_operators = {
	PropertyOperators.equal : [$Grid/EqualBtn, "=", "is equal to"],
	PropertyOperators.not_equal : [$Grid/NotEqualBtn, "!=", "is not equal to"],
	PropertyOperators.less_equal : [$Grid/LessEqualBtn, "<=", "less or equal to"],
	PropertyOperators.greater_equal : [$Grid/EqualBtn, ">=", "greater or equal to"],
	PropertyOperators.less : [$Grid/LessBtn, "<", "less than"],
	PropertyOperators.greater : [$Grid/GreaterBtn, ">", "greater than"],
	PropertyOperators.regex : [$Grid/RegexBtn, "~=", "conform to regex"],
	PropertyOperators.regex_not : [$Grid/RegexNotBtn, "!~", "not conform to regex"],
	PropertyOperators.in_o : [$Grid/InBtn, "in", "value in array [x, y, ...]"],
	PropertyOperators.not_in_o : [$Grid/NotInBtn, "not in", "value not in array [x, y, ...]"],
}

var property_operators:= {
	"s_string" : [],
	"s_int" : [PropertyOperators.regex,
		PropertyOperators.regex_not,
		],
	"s_duration" : []
}

var property_type:String = ""
var selected_operator:int = PropertyOperators.equal

func _ready():
	for c in button_operators.values():
		c[0].hint_tooltip = c[2]
	selected_new_operator()


func _on_Popup_about_to_show():
	for c in $Grid.get_children():
		c.show()
	
	if not property_operators.has(property_type):
		return
		
	for b in property_operators[property_type]:
		button_operators[b][0].hide()

func selected_new_operator():
	emit_signal("update_operator", button_operators[selected_operator][1], button_operators[selected_operator][2])
	hide()


func _on_NotInBtn_pressed():
	selected_operator = PropertyOperators.not_in_o
	selected_new_operator()


func _on_InBtn_pressed():
	selected_operator = PropertyOperators.in_o
	selected_new_operator()


func _on_RegexNotBtn_pressed():
	selected_operator = PropertyOperators.regex_not
	selected_new_operator()


func _on_RegexBtn_pressed():
	selected_operator = PropertyOperators.regex
	selected_new_operator()


func _on_GreaterBtn_pressed():
	selected_operator = PropertyOperators.greater
	selected_new_operator()


func _on_LessBtn_pressed():
	selected_operator = PropertyOperators.less
	selected_new_operator()


func _on_GreaterEqualBtn_pressed():
	selected_operator = PropertyOperators.greater_equal
	selected_new_operator()


func _on_LessEqualBtn_pressed():
	selected_operator = PropertyOperators.less_equal
	selected_new_operator()


func _on_NotEqualBtn_pressed():
	selected_operator = PropertyOperators.not_equal
	selected_new_operator()


func _on_EqualBtn_pressed():
	selected_operator = PropertyOperators.equal
	selected_new_operator()
