# Global Singleton Class_Name: API
extends Node


# The URL we will connect to.
@export var websocket_url = "ws://localhost:5000"
@export var enabled = true


var socket = WebSocketPeer.new()


signal connected
signal response_received
signal response(key, response: String)


func _ready():
	if not enabled:
		set_process(false)
		set_physics_process(false)
		return
	
	# Initiate connection to the given URL.
	var err = socket.connect_to_url(websocket_url)
	connect("connected", Callable(self, "_on_connected"))
	
	if err != OK:
		print("Websocket peer failed to open a connection to port 5000, is the port being used?")
		set_process(false)
	else:
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout

		socket.set_inbound_buffer_size(1024 * 1024) # 1MB
		socket.set_outbound_buffer_size(1024 * 1024) # 1MB

		print("Websocket peer connected to port 5000")
		connected.emit()


func generate_script(prompt: String, key: int, image_data: String = ""):
	_prompt_LLM(prompt, key, "SCRIPT", image_data)

func generate_goal(prompt: String, key: int, image_data: String = ""):
	_prompt_LLM(prompt, key, "GOAL", image_data)


func _prompt_LLM(prompt: String, key: int, type: String, image_data: String = ""):
	# Wait until the socket is open before sending the prompt.
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		await connected
	
	# Send the prompt to the LLM using a JSON payload.
	var payload
	if image_data != "":
		payload = JSON.stringify({
			"key": key,
			"type": type,
			"prompt": prompt,
			"image_data": image_data
		})
	else:
		payload = JSON.stringify({
			"key": key,
			"type": type,
			"prompt": prompt
		})
	# print("Sending payload of length %d" % payload.length())
	socket.send_text(payload)

	# Wait for a non-empty response.
	var response_string = ""
	var response_type = ""
	var response_key = -1
	while response_string == "":
		await response_received
		response_string = socket.get_packet().get_string_from_utf8()

		if response_string == "":
			continue

		# Parse the JSON response, ensuring that the response matches the expected type.
		var json = JSON.new()
		var parse_result = json.parse(response_string)

		if parse_result != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", response_string, " at line ", json.get_error_line())
			continue
		response_key = json.data["key"]
		response_string = json.data["contents"]
		response_type = json.data["type"]

		# print("Received response of type '%s' with contents: %s" % [response_type, response_string])

		# Emit the response signal with the key and response string.
		if response_string != "" and response_key == key and response_type == type:
			response.emit(key, response_string)
		# TODO: add timeout?


func _physics_process(_delta):
	# Data transfer and state updates will only happen when calling this function.
	# May want to call instead in _process
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the socket is connected and ready to send and receive data.
	match state:
		WebSocketPeer.STATE_OPEN:
			if socket.get_available_packet_count():
				response_received.emit()
		
		WebSocketPeer.STATE_CLOSING:
			print("Connection lost. Is the Python server running?")
		
		WebSocketPeer.STATE_CLOSED:
			# The code will be -1 if the disconnection was not properly notified by the remote peer.
			var code = socket.get_close_code()
			print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
			set_process(false) # Stop processing.
			set_physics_process(false) # Stop physics processing.
