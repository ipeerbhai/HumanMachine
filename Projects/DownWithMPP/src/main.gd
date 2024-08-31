extends Control

var drawing = false
var erasing = false
var current_line: Line2D = null
var lines = []

var min_pressure = 0.1
var max_pressure = 1.0
var min_width = 1.0
var max_width = 10.0

var pressure_sensitivity = 0.5
var tilt_sensitivity = 0.5
var erase_mode = false

func _ready():
	print("Script initialized")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drawing(event.position)
			else:
				stop_drawing()
	elif event is InputEventMouseMotion:
		if drawing:
			continue_drawing(event)
	
	update_event_log(event)

func start_drawing(position):
	drawing = true
	current_line = Line2D.new()
	current_line.default_color = Color.BLACK
	current_line.width = calculate_line_width(0.5)  # Start with mid pressure
	add_child(current_line)
	lines.append(current_line)
	add_point_to_line(position, 0.5, Vector2.ZERO)  # Start with mid pressure and no tilt

func stop_drawing():
	drawing = false
	current_line = null

func continue_drawing(event):
	if current_line:
		add_point_to_line(event.position, event.pressure, event.tilt)

func add_point_to_line(position, pressure, tilt):
	var width = calculate_line_width(pressure)
	current_line.add_point(position)
	current_line.width = width
	apply_tilt_effect(current_line, tilt)

func calculate_line_width(pressure):
	var adjusted_pressure = lerp(min_pressure, max_pressure, pressure * pressure_sensitivity)
	return lerp(min_width, max_width, adjusted_pressure)

func apply_tilt_effect(line, tilt):
	line.default_color = Color(1.0 - abs(tilt.x) * tilt_sensitivity, 
							   1.0 - abs(tilt.y) * tilt_sensitivity, 
							   1.0, 1.0)

func get_tilt(event):
	if event is InputEventMouseMotion:
		return event.tilt
	return Vector2.ZERO  # Default tilt

func update_event_log(event):
	var log = $"../../RightPanel/VBoxContainer/EventLog"
	log.text += str(event) + "\n"
	log.scroll_vertical = log.get_line_count()

func _on_clear_button_pressed():
	print("Clear button pressed")
	for line in lines:
		line.queue_free()
	lines.clear()

func _on_save_button_pressed():
	print("Save button pressed")
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "drawing_%04d%02d%02d_%02d%02d%02d.png" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	image.save_png("user://"+filename)
	print("Drawing saved as: ", filename)

func _on_pressure_sensitivity_changed(value):
	pressure_sensitivity = value
	$"../../RightPanel/VBoxContainer/ControlsContainer/PressureLabel".text = "Pressure: %.1f" % value
	print("Pressure sensitivity changed to: ", value)

func _on_tilt_sensitivity_changed(value):
	tilt_sensitivity = value
	$"../../RightPanel/VBoxContainer/ControlsContainer/TiltLabel".text = "Tilt: %.1f" % value
	print("Tilt sensitivity changed to: ", value)

func _on_eraser_toggle_changed(button_pressed):
	erase_mode = button_pressed
	print("Eraser mode: ", "On" if erase_mode else "Off")

func _on_clear_log_button_pressed():
	$"../../RightPanel/VBoxContainer/EventLog".text = ""

func _on_save_log_button_pressed():
	var save_dialog = $"../../SaveFileDialog"
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.filters = ["*.txt ; Text Files"]
	
	var datetime = Time.get_datetime_dict_from_system()
	var default_filename = "log_%04d%02d%02d_%02d%02d%02d.txt" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	save_dialog.current_file = default_filename
	
	save_dialog.popup_centered()
	save_dialog.connect("file_selected", Callable(self, "_on_SaveFileDialog_file_selected"))

func _on_SaveFileDialog_file_selected(path):
	var log_text = $"../../RightPanel/VBoxContainer/EventLog".text
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(log_text)
	file.close()
	print("Log saved as: ", path)
