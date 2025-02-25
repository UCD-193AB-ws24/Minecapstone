# Global Singleton Class_Name: API
extends Node


# The URL we will connect to.
@export var websocket_url = "ws://localhost:5000"
@export var enabled = true
var connection_open = false


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
		print("Websocket peer connected to port 5000")
		connected.emit()


func prompt_llm(prompt: String, key: int):
	# Wait until the socket is open before sending the prompt.
	socket.send_text(prompt)
	await response_received
	var response_string = socket.get_packet().get_string_from_utf8()
	response.emit(key, response_string)


func _physics_process(_delta):
	# Data transfer and state updates will only happen when calling this function.
	# May want to call instead in _process
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the socket is connected and ready to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		if connection_open == false:
			connection_open = true
		while socket.get_available_packet_count():
			response_received.emit()

	# WebSocketPeer.STATE_CLOSING means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		print("Connection lost. Is the Python server running?")
		pass

	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
		set_physics_process(false) # Stop physics processing.
