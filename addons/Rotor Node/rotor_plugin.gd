@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Rotor", "Node2D", preload("res://addons/Rotor Node/Rotor.gd"), preload("res://addons/Rotor Node/icon.png"))
	pass


func _exit_tree():
	remove_custom_type("Rotor")
	pass
