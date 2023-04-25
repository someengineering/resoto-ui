extends Node

export var test := false

var remote_configs : Dictionary = {
	"config_key" : {"sub_key" : {
		"array" : ["a", "b", "c"],
		"variable_string" : "hello_world",
		"variable_bool" : false,
		"variable_int" : 42,
	}}
}

func _ready():
	if not test:
		queue_free()
		return
	var p = get_parent()
	p.wizard = self
	p.connect("next", self, "test_result")
	
	print("elem count test: 3 <= 2")
	var data_test_element_count_1 : Dictionary = {
		"config":"config_key",
		"kind":"element_count",
		"operation":"<=",
		"variable_name":"sub_key.array",
		"variable_value":"2"
	}
	p.start(data_test_element_count_1)
	
	print("elem count test: null == 4")
	var data_test_element_count_2 : Dictionary = {
		"config":"config_key",
		"kind":"element_count",
		"operation":"==",
		"variable_name":"not_existing",
		"variable_value":"4"
	}
	p.start(data_test_element_count_2)
	
	print("elem count test: null <= 4")
	var data_test_element_count_3 : Dictionary = {
		"config":"not_existing",
		"kind":"element_count",
		"operation":"<=",
		"variable_name":"not_existing",
		"variable_value":"4"
	}
	p.start(data_test_element_count_3)
	
	print("elem count test: 3 == 3")
	var data_test_element_count_4 : Dictionary = {
		"config":"config_key",
		"kind":"element_count",
		"operation":"==",
		"variable_name":"sub_key.array",
		"variable_value":"3"
	}
	p.start(data_test_element_count_4)
	
	print("string test: hello_world == hello_world")
	var data_test_string_1 : Dictionary = {
		"config":"config_key",
		"kind":"compare_values",
		"operation":"==",
		"variable_name":"sub_key.variable_string",
		"variable_value":"hello_world"
	}
	p.start(data_test_string_1)
	
	print("string test: hello_world != hello_world")
	var data_test_string_2 : Dictionary = {
		"config":"config_key",
		"kind":"compare_values",
		"operation":"!=",
		"variable_name":"sub_key.variable_string",
		"variable_value":"hello_world"
	}
	p.start(data_test_string_2)
	
	print("bool test: false == true")
	var data_test_bool_1 : Dictionary = {
		"config":"config_key",
		"kind":"compare_values",
		"operation":"==",
		"variable_name":"sub_key.variable_bool",
		"variable_value":"true"
	}
	p.start(data_test_bool_1)
	
	print("bool test: false != false")
	var data_test_bool_2 : Dictionary = {
		"config":"config_key",
		"kind":"compare_values",
		"operation":"!=",
		"variable_name":"sub_key.variable_bool",
		"variable_value":"false"
	}
	p.start(data_test_bool_2)
	
	print("bool test: false == false")
	var data_test_bool_3 : Dictionary = {
		"config":"config_key",
		"kind":"compare_values",
		"operation":"==",
		"variable_name":"sub_key.variable_bool",
		"variable_value":"false"
	}
	p.start(data_test_bool_3)
	
	print("int test: 42 == 42")
	var data_test_int_1 : Dictionary = {
		"config":"config_key",
		"kind":"compare_values",
		"operation":"==",
		"variable_name":"sub_key.variable_int",
		"variable_value":"42"
	}
	p.start(data_test_int_1)
	
	print("int test: 42 != 42")
	var data_test_int_2 : Dictionary = {
		"config":"config_key",
		"kind":"compare_values",
		"operation":"!=",
		"variable_name":"sub_key.variable_int",
		"variable_value":"42"
	}
	p.start(data_test_int_2)


func test_result(_r:int):
	if _r == 1:
		print("Result: False")
	elif _r == 0:
		print("Result: True")
	print()
