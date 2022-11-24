extends Node
class_name JWTGenerator

const TOKEN_EXPIRATION_TIME:int = 3600 # one hour expiration
const EXPIRE_THRESHOLD:int = TOKEN_EXPIRATION_TIME - 300 # refresh the token every 5 minutes

signal jwt_generated

var psk: String = "changeme"
var token: String = ""
var token_expire: int = 0
var print_token: bool = false


func token_expired() ->bool:
	var token_expired = (token_expire - OS.get_unix_time()) < EXPIRE_THRESHOLD
	return token_expired


func create_jwt(data: String, _psk: String = psk) -> void:
	if _psk == "":
		return
	token = jwt(data, _psk)
	emit_signal("jwt_generated")


func jwt(data: String, _psk: String) -> String:
	var expire = OS.get_unix_time() + TOKEN_EXPIRATION_TIME
	token_expire = expire
	var crypto = Crypto.new()

	var new_crypto = Crypto.new()
	var salt: PoolByteArray = new_crypto.generate_random_bytes(16)

	var salted_key = key_from_psk(_psk, salt)

	var header = {"alg": "HS256", "typ": "JWT", "salt": Marshalls.raw_to_base64(salt)}
	var payload = {"exp": expire, "data": data}

	var header_base64 = base64urlencode(Marshalls.utf8_to_base64(JSON.print(header)))
	var payload_base64 = base64urlencode(Marshalls.utf8_to_base64(JSON.print(payload)))
	var signing_content = header_base64 + "." + payload_base64

	var signature = crypto.hmac_digest(
		HashingContext.HASH_SHA256, salted_key["key"], signing_content.to_utf8()
	)
	signature = base64urlencode(Marshalls.raw_to_base64(signature))

	var jwt = signing_content + "." + signature

	if print_token:
		print("JWT:\n" + jwt)

	return jwt


static func pbkdf2(hash_type: int, password: PoolByteArray, salt: PoolByteArray, iterations:int = 100000, length:int = 0) -> PoolByteArray:	
	var crypto: Crypto = Crypto.new()
	var hash_length: int = len(crypto.hmac_digest(hash_type, salt, password))
	
	if length == 0:
		length = hash_length

	var output: PoolByteArray = PoolByteArray()
	# warning-ignore:integer_division
	var block_count: int = int(ceil(length / hash_length))

	var buffer: PoolByteArray = PoolByteArray()
	buffer.resize(4)

	var block: int = 1
	while block <= block_count:
		buffer[0] = (block >> 24) & 0xFF
		buffer[1] = (block >> 16) & 0xFF
		buffer[2] = (block >> 8) & 0xFF
		buffer[3] = block & 0xFF

		var key_1: PoolByteArray = crypto.hmac_digest(hash_type, password, salt + buffer)
		var key_2: PoolByteArray = key_1

		for _index in iterations - 1:
			key_1 = crypto.hmac_digest(hash_type, password, key_1)

			for index in key_1.size():
				key_2[index] ^= key_1[index]

		output += key_2

		block += 1

	return output.subarray(0, hash_length - 1)


static func base64urlencode(base64_input) -> String:
	return str(base64_input).replace("+", "-").replace("/", "_").trim_suffix("=").trim_suffix("=")


static func key_from_psk(_psk: String, salt: PoolByteArray = []) -> Dictionary:
	if salt.empty():
		var new_crypto = Crypto.new()
		salt = new_crypto.generate_random_bytes(16)
	var key = pbkdf2(HashingContext.HASH_SHA256, _psk.to_utf8(), salt, 100000)
	return {"key": key, "salt": salt}


func _notification(what):
	if what == NOTIFICATION_WM_FOCUS_IN:
		token_expire = 0
