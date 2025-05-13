extends Node
"""Purpose of this script is to pass c# signals to gdscripts for scenario_give_selective. For some reason, it's not possible to connect c# signals to gdscript"""

signal transit_signal(signal_name:String, args: Array)


func _on_transit(signal_name:String, args: Array) -> void:
	"""pass c# signal to gdscript"""
	print("passing item added signal to gdscript")
	transit_signal.emit(signal_name, args)
