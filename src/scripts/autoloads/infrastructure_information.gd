extends Node

signal infra_info_updated

var infra_info : Array = [] setget set_infra_info
var accounts : Dictionary = {}
var clouds : Array = []
var regions : Dictionary = {}


func set_infra_info(new_info : Array) -> void:
	infra_info = new_info
	for info in infra_info:
		if "reported" in info:
			if info.reported.kind == "cloud":
				clouds.append(info.reported.name)
			else:
				var cloud = info.reported.kind.split("_")[0]
				if "region" in info.reported.kind:
					if cloud in regions:
						regions[cloud].append(info.reported.name)
					else:
						regions[cloud] = [info.reported.name]
				elif "account" in info.reported.kind:
					if cloud in accounts:
						accounts[cloud].append(info.reported.name)
					else:
						accounts[cloud] = [info.reported.name]
				
				
	emit_signal("infra_info_updated")
