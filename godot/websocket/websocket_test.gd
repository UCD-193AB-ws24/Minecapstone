extends Node

# The URL we will connect to.
@export var websocket_url = "ws://localhost:5000"

var socket = WebSocketPeer.new()

func _ready():
	# Initiate connection to the given URL.
	var err = socket.connect_to_url(websocket_url)
	print("Peer attempting to connect to port 5000")
	
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout
		
		var message = "Go to position (5,3)."
		
		print("Sent message: ", message)

		# Send data.
		socket.send_text(message)

func _physics_process(_delta):
	# Data transfer and state updates will only happen when calling this function.
	# May want to call instead in _process
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the socket is connected and ready to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			print("Response: ", socket.get_packet().get_string_from_utf8())

	# WebSocketPeer.STATE_CLOSING means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		print("Closing...")
		pass

	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
