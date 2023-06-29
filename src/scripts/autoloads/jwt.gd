extends Node
class_name JWTGenerator

const TOKEN_EXPIRATION_TIME:int = 3600 # one hour expiration
const EXPIRE_THRESHOLD:int = TOKEN_EXPIRATION_TIME - 300 # refresh the token every 5 minutes

signal jwt_generated

var token: String = ""
var token_expire: int = 0
var print_token: bool = false

onready var expiration_timer := Timer.new()


func _ready():
	if not OS.has_feature("HTML5"):
		add_child(expiration_timer)
		expiration_timer.one_shot = true
		expiration_timer.connect("timeout", self, "renew_token")


func token_expired() ->bool:
	var token_expired = (token_expire - OS.get_unix_time()) < 300
	return token_expired


func renew_token():
	API.renew_token(self)


func _on_renew_token_done(_error: int, _response: ResotoAPI.Response):
	if _error:
		return
	set_token(_response.headers["Authorization"].split(" ")[1])
	_g.authorized = true
	pass


func set_token(_token : String):
	token = _token
	var payload := token.split(".")[1]
	var decoded_payload : String = Marshalls.base64_to_utf8(_convert_base64(payload))
	token_expire = parse_json(decoded_payload).exp - 300
	_g.authorized = true
	if not OS.has_feature("HTML5"):
		expiration_timer.start((token_expire - Time.get_unix_time_from_system()))


func create_jwt() -> void:
	if OS.has_feature("HTML5"):
#		token = HtmlFiles.load_from_local_storage("jwt")
		token = JavaScript.eval("t")
		if token == "":
			return
		set_token(token)
		emit_signal("jwt_generated")


func _notification(what):
	if what == NOTIFICATION_WM_FOCUS_IN:
		pass


func _convert_base64(base64: String) -> String:
	var mod = base64.length() % 4
	if mod > 0:
		for _i in range(4 - mod):
			base64 += "="
	return base64.replace("-", "+").replace("_", "/")
