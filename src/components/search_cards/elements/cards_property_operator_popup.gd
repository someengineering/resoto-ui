extends PopupPanel

signal update_operator

onready var button_operators = {
	SearchCards.PropertyOperators.equal : [$Grid/EqualBtn, "="],
	SearchCards.PropertyOperators.not_equal : [$Grid/NotEqualBtn, "!="],
	SearchCards.PropertyOperators.less_equal : [$Grid/LessEqualBtn, "<="],
	SearchCards.PropertyOperators.greater_equal : [$Grid/EqualBtn, ">="],
	SearchCards.PropertyOperators.less : [$Grid/LessBtn, "<"],
	SearchCards.PropertyOperators.greater : [$Grid/GreaterBtn, ">"],
	SearchCards.PropertyOperators.regex : [$Grid/RegexBtn, "~="],
	SearchCards.PropertyOperators.regex_not : [$Grid/RegexNotBtn, "!~"],
	SearchCards.PropertyOperators.in_o : [$Grid/InBtn, "in"],
	SearchCards.PropertyOperators.not_in_o : [$Grid/NotInBtn, "not in"],
}

var property_operators:= {
	"s_string" : [],
	"s_int" : [SearchCards.PropertyOperators.regex,
		SearchCards.PropertyOperators.regex_not,
		],
	"s_duration" : []
}

var property_type:String = ""
var selected_operator:int = SearchCards.PropertyOperators.equal

func _on_Popup_about_to_show():
	for c in $Grid.get_children():
		c.show()
	
	if not property_operators.has(property_type):
		return
		
	for b in property_operators[property_type]:
		button_operators[b][0].hide()

func selected_new_operator():
	emit_signal("update_operator", button_operators[selected_operator][1])
	hide()


func _on_NotInBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.not_in_o
	selected_new_operator()


func _on_InBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.in_o
	selected_new_operator()


func _on_RegexNotBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.regex_not
	selected_new_operator()


func _on_RegexBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.regex
	selected_new_operator()


func _on_GreaterBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.greater
	selected_new_operator()


func _on_LessBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.less
	selected_new_operator()


func _on_GreaterEqualBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.greater_equal
	selected_new_operator()


func _on_LessEqualBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.less_equal
	selected_new_operator()


func _on_NotEqualBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.not_equal
	selected_new_operator()


func _on_EqualBtn_pressed():
	selected_operator = SearchCards.PropertyOperators.equal
	selected_new_operator()
