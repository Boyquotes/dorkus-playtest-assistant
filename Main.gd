extends Node

signal main_ready


const STATUS_WINDOW := preload("res://status_window.tscn")

var status_window : Control
var config = {
		"json_path": "res://dorkus-obs/config/obs-studio/basic/scenes/NG3_Playtest.json",
		"source_mappings": {
			"image_source": {
				"file": "dorkus-white.png"
			},
			"input-overlay": {
				"io.overlay_image": "game-pad.png",
				"io.layout_file": "game-pad.json",
			},
		},
	}

@onready var obs_helper = $OBSHelper


func _ready():
	fix_sources()
	get_tree().set_auto_accept_quit(false)
	get_viewport().set_embedding_subwindows(false)

	status_window = STATUS_WINDOW.instantiate()
	add_child(status_window, true)

	var window = status_window.window

	window = window.get_viewport()
	window.always_on_top = true
	window.transparent = true
	window.transparent_bg = true
	window.borderless = true
	var res := DisplayServer.screen_get_size()
	window.position = res - window.size + Vector2i(0, res.y / 2)
	print(window.position)
	obs_helper.replay_buffer_saved.connect(status_window._on_replay_buffer_saved)


func fix_sources():
	var original_contents : Variant = Utility.read_json(config.json_path)
	Utility.write_json(config.json_path, replace_filepaths_in_json(original_contents))


func replace_filepaths_in_json(json_contents : Dictionary) -> Dictionary:
	for source_id in config.source_mappings.keys():
		var source_map = config.source_mappings[source_id]
		var source_index = _get_source_index(source_id, json_contents)

		for item in source_map.keys():
			var keypath = ["sources", source_index, "settings", item]
			var new_filepath = "dorkus-obs/assets/" + source_map[item]

			assert(FileAccess.file_exists(new_filepath), "Could not find %s at expected path" % source_map[item])

			_set_json_path(json_contents, keypath, Utility.globalize_path(new_filepath))

	return json_contents


func _get_source_index(source_id : String, json_contents : Dictionary) -> int:
	var index := 0

	for source in json_contents.sources:
		if source.id == source_id:
			return index

		index += 1
	
	return -1


func _set_json_path(dict, keypath, value) -> Variant:
	var current = keypath[0]
	if typeof(dict[current]) == TYPE_DICTIONARY:
		keypath.remove_at(0)
		_set_json_path(dict[current], keypath, value) # recursion happens here
		return
	elif typeof(dict[current]) == TYPE_ARRAY:
		keypath.remove_at(0)
		_set_json_path(dict[current], keypath, value) # recursion happens here
		return
	else:
		dict[current] = value
		return


func _on_app_toggle_app_started():
	pass # Replace with function body.
