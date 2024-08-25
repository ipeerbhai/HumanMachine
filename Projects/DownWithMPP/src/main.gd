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

var file_dialog: FileDialog

func _ready():
	print("Script initialized")
	var event_log = $"../../RightPanel/VBoxContainer/EventLog"
	event_log.gutters_draw_line_numbers = true
	event_log.minimap_draw = false
	event_log.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	# Create FileDialog
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.txt", "Text Files")
	file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	add_child(file_dialog)

func _gui_input(event):
	var event_text = "Event: " + str(event)
	var event_log = $"../../RightPanel/VBoxContainer/EventLog"
	event_log.text += event_text + "\n"
	event_log.scroll_vertical = event_log.get_line_count()  # Scroll to bottom
	
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			start_interaction(event)
		else:
			stop_interaction()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		continue_interaction(event)

func start_interaction(event):
	var local_position = get_local_mouse_position()
	if erase_mode or (event is InputEventMouseMotion and event.pen_inverted):
		erasing = true
		drawing = false
		erase_at_position(local_position, event)
	else:
		erasing = false
		drawing = true
		start_new_line(local_position, event)

func start_new_line(position, event):
	current_line = Line2D.new()
	current_line.default_color = Color.BLACK
	current_line.width = calculate_line_width(event.pressure if "pressure" in event else 1.0)
	current_line.add_point(position)
	add_child(current_line)
	lines.append(current_line)

func continue_interaction(event):
	var local_position = get_local_mouse_position()
	if erasing:
		erase_at_position(local_position, event)
	elif drawing and current_line:
		var width = calculate_line_width(event.pressure if "pressure" in event else 1.0)
		current_line.width = width
		apply_tilt_effect(current_line, event)
		current_line.add_point(local_position)

func stop_interaction():
	drawing = false
	erasing = false
	current_line = null

func calculate_line_width(pressure):
	var adjusted_pressure = lerp(min_pressure, max_pressure, pressure * pressure_sensitivity)
	return lerp(min_width, max_width, adjusted_pressure)

func apply_tilt_effect(line, event):
	if "tilt" in event:
		var tilt = event.tilt * tilt_sensitivity
		line.default_color = Color(1.0 - tilt.x, 1.0 - tilt.y, 1.0, 1.0)

func erase_at_position(position, event):
	var erase_radius = calculate_line_width(event.pressure if "pressure" in event else 1.0)
	for line in lines:
		var points_to_remove = []
		for i in range(line.get_point_count()):
			if line.get_point_position(i).distance_to(position) < erase_radius:
				points_to_remove.append(i)
		
		points_to_remove.sort()
		points_to_remove.reverse()

		for i in points_to_remove:
			if line.get_point_count() > i:
				line.remove_point(i)

		if line.get_point_count() == 0:
			lines.erase(line)
			line.queue_free()

func _on_clear_button_pressed():
	for line in lines:
		line.queue_free()
	lines.clear()

func _on_save_button_pressed():
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

func _on_tilt_sensitivity_changed(value):
	tilt_sensitivity = value
	$"../../RightPanel/VBoxContainer/ControlsContainer/TiltLabel".text = "Tilt: %.1f" % value

func _on_eraser_toggle_changed(button_pressed):
	erase_mode = button_pressed

func _on_clear_log_button_pressed():
	$"../../RightPanel/VBoxContainer/EventLog".text = ""

func _on_save_log_button_pressed():
	var datetime = Time.get_datetime_dict_from_system()
	var default_name = "log_%04d%02d%02d_%02d%02d%02d.txt" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	file_dialog.current_file = default_name
	file_dialog.popup_centered(Vector2(800, 600))

func _on_file_selected(path):
	var event_log = $"../../RightPanel/VBoxContainer/EventLog"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(event_log.text)
		file.close()
		print("Log saved successfully to: ", path)
	else:
		print("Error saving log file")
