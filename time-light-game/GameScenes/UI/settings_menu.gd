extends Control

signal closed

const BUSES: Array[String] = ["Master", "SFX", "Music"]
const MIN_DB := -60.0

@onready var _bus_list: VBoxContainer = $CenterContainer/VBoxContainer/BusList
@onready var _back_button: Button = $CenterContainer/VBoxContainer/BackButton

@onready var sensitivity_slider: HSlider = $CenterContainer/VBoxContainer/HBoxContainer/HSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_back_button.pressed.connect(func() -> void: closed.emit())
	for bus_name in BUSES:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			_add_slider(bus_name, idx)
	sensitivity_slider.value = Global.camera_sensitivity
	sensitivity_slider.value_changed.connect(Global.set_sensitivity)


func _add_slider(bus_name: String, idx: int) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = bus_name
	label.custom_minimum_size = Vector2(150, 0)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(280, 0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(idx))
	slider.value_changed.connect(_on_slider_changed.bind(idx))

	row.add_child(label)
	row.add_child(slider)
	_bus_list.add_child(row)


func _on_slider_changed(value: float, idx: int) -> void:
	var db := MIN_DB if value <= 0.0 else linear_to_db(value)
	AudioServer.set_bus_volume_db(idx, db)
