extends EditorScript
tool

var dict:= {
	"id": "0001",
	"type": "donut",
	"name": "Cake",
	"ppu": 0.55,
	"batters":{
		"batter":[
			{ "id": "1001", "type": "Regular" },
			{ "id": "1002", "type": "Chocolate" },
			]
		},
	"extras" : [
		["cherries", "chocolate"],
		["cheese", "gouda"]
		],
	"topping":[
		{ "id": "5001", "type": "None" },
		{ "id": "5002", "type": "Glazed" },
		]
	}

var s_dict:= {
	"id": 12,
	"batters":{
		"batter":[
			{ "id": "1001", "type": "Bar" },
			{ "id": "1002", "type": "Foo" },
			]
		},
	"type": "donut",
}

func _run():
	var text = Utils.readable_dict(dict)
	print("#################################################")
	print(text)

