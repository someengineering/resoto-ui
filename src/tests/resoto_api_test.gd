extends Node2D

var resoto_api_: ResotoAPI

var req_res: ResotoAPI.Request

func _ready() -> void:
	resoto_api_ = ResotoAPI.new()
	
	resoto_api_.accept_json_headers.Accept_Encoding = "gzip" if OS.has_feature("web") else ""
	resoto_api_.accept_text_headers.Accept_Encoding = "gzip" if OS.has_feature("web") else ""
	resoto_api_.accept_json_headers.Resotoui_via = "Web" if OS.has_feature("web") else "Desktop"
	resoto_api_.accept_text_headers.Resotoui_via = "Web" if OS.has_feature("web") else "Desktop"
	
	req_res = resoto_api_.post_cli_execute("help")
	req_res.connect("done", self, "_on_post_cli_execute_done")


func _process(_delta:float) -> void:
	resoto_api_.poll()


func _on_post_cli_execute_done(error:int, response:UserAgent.Response) -> void:
	if error:
		print(error)
	else:
		print(response.transformed["result"])
