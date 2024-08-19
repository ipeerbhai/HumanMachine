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
	%CanvasLayer/DrawingArea.modulate = Color(1, 0, 0, 0.5)  # Semi-transparent red for visibility check
	
	# Debug line
	var debug_line = Line2D.new()
	debug_line.add_point(Vector2(100, 100))
	debug_line.add_point(Vector2(200, 200))
	debug_line.default_color = Color.RED
	%CanvasLayer/DrawingArea.add_child(debug_line)

func _gui_input(event):
	print("Received input event: ", event)
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			start_interaction(event)
		else:
			stop_interaction()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		continue_interaction(event)

func start_interaction(event):
	print("Starting interaction")
	var local_position = get_local_mouse_position()
	if event is InputEventMouseMotion and event.pen_inverted:
		erasing = true
		drawing = false
		erase_at_position(local_position, event)
	else:
		erasing = false
		drawing = true
		start_new_line(local_position, event)

func start_new_line(position, event):
	print("Starting new line at position: ", position)
	current_line = Line2D.new()
	current_line.default_color = Color.BLACK
	current_line.width = calculate_line_width(event.pressure if "pressure" in event else 1.0)
	current_line.add_point(position)
	%CanvasLayer/DrawingArea.add_child(current_line)
	lines.append(current_line)

func continue_interaction(event):
	print("Continuing interaction")
	if event is InputEventMouseMotion:
		print("Pen pressure: ", event.pressure)
		if event.pen_inverted:
			erasing = true
			drawing = false
	var local_position = get_local_mouse_position()
	if erasing:
		erase_at_position(local_position, event)
	elif drawing and current_line:
		var width = calculate_line_width(event.pressure if "pressure" in event else 1.0)
		current_line.width = width
		apply_tilt_effect(current_line, event)
		current_line.add_point(local_position)

func stop_interaction():
	print("Stopping interaction")
	drawing = false
	erasing = false
	current_line = null

func calculate_line_width(pressure):
	var adjusted_pressure = lerp(min_pressure, max_pressure, pressure * pressure_sensitivity)
	return lerp(min_width, max_width, adjusted_pressure)

func apply_tilt_effect(line, event):
	if event is InputEventMouseMotion:
		var tilt = event.tilt * tilt_sensitivity
		# This is a placeholder for actual tilt implementation
		line.default_color = Color(1.0 - abs(tilt.x), 1.0 - abs(tilt.y), 1.0, 1.0)

func erase_at_position(position, event):
	print("Erasing at position: ", position)
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
	$CanvasLayer/UI/PressureLabel.text = "Pressure: %.1f" % value
	print("Pressure sensitivity changed to: ", value)

func _on_tilt_sensitivity_changed(value):
	tilt_sensitivity = value
	$CanvasLayer/UI/TiltLabel.text = "Tilt: %.1f" % value
	print("Tilt sensitivity changed to: ", value)

func _on_eraser_toggle_changed(button_pressed):
	erase_mode = button_pressed
	print("Eraser mode: ", "On" if erase_mode else "Off")

func _process(delta):
	queue_redraw()  # Ensure continuous redrawing

func _draw():
	# This function is called when redrawing is needed
	# It's not strictly necessary for Line2D nodes, but can be useful for custom drawing
	pass
