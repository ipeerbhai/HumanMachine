# This script extends the Control node, which is a base class for GUI-related nodes
extends Control

# Declare variables that will be used throughout the script
var current_character: String  # Stores the current player's character (X or O)
var game_over: bool            # A flag to indicate if the game has ended
var available_buttons: Array   # A list of all the buttons on the game board

# This function is called when the scene is loaded and ready
func _ready():
	# Initialize the available_buttons array with the names of all the buttons on the game board
	# This creates a 3x3 grid representation of the tic-tac-toe board
	available_buttons = [
		[ "btnTopLeft", "btnTopMiddle", "btnTopRight"],
		[ "btnMiddleLeft", "btnMiddleMiddle", "btnMiddleRight"],
		[ "btnBottomLeft", "btnBottomMiddle", "btnBottomRight"]
	]
	
	# Set the initial game state
	game_over = false              # The game hasn't ended yet
	current_character = "X"        # X always starts the game
	
	# Update the label to show it's X's turn
	# The % symbol is used to quickly access a node that has been set as "unique" in the editor
	%lblMainText.text = current_character + "'s Move"

# This function is called when a player makes a move (clicks a button)
func _on_move_made(which_button: String):
	# If the game is over, do nothing and exit the function
	if game_over:
		return

	# Construct the full path to the button that was clicked
	var button_path: String = "vbxSingleColLayout/grdMainContainer/%s" % which_button
	# Get the actual button node using the constructed path
	var the_button = get_node(button_path)

	# Check if the button is empty (hasn't been clicked before)
	if the_button.text.is_empty():
		# Set the button's text to the current player's character (X or O)
		the_button.text = current_character
		
		# Initialize a variable to track if someone has won
		var win = false
		
		# Check for a win condition in all rows
		for row in available_buttons:
			# Get the three buttons in the current row
			var b1 = get_node("vbxSingleColLayout/grdMainContainer/%s" % row[0])
			var b2 = get_node("vbxSingleColLayout/grdMainContainer/%s" % row[1])
			var b3 = get_node("vbxSingleColLayout/grdMainContainer/%s" % row[2])
			# If all three buttons are the same and not empty, it's a win
			if not b1.text.is_empty() and b1.text == b2.text and b2.text == b3.text:
				win = true
				break  # Exit the loop early if a win is found

		# If no win in rows, check for a win condition in all columns
		if not win:
			for col in range(3):
				# Get the three buttons in the current column
				var b1 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[0][col])
				var b2 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[1][col])
				var b3 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[2][col])
				# If all three buttons are the same and not empty, it's a win
				if not b1.text.is_empty() and b1.text == b2.text and b2.text == b3.text:
					win = true
					break  # Exit the loop early if a win is found

		# If no win in columns, check the top-left to bottom-right diagonal
		if not win:
			var b1 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[0][0])
			var b2 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[1][1])
			var b3 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[2][2])
			if not b1.text.is_empty() and b1.text == b2.text and b2.text == b3.text:
				win = true

		# If still no win, check the top-right to bottom-left diagonal
		if not win:
			var b1 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[0][2])
			var b2 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[1][1])
			var b3 = get_node("vbxSingleColLayout/grdMainContainer/%s" % available_buttons[2][0])
			if not b1.text.is_empty() and b1.text == b2.text and b2.text == b3.text:
				win = true

		# If a win condition was found
		if win:
			# Update the label to show who won
			%lblMainText.text = current_character + " wins!"
			# Set the game_over flag to true
			game_over = true
		else:
			# If no win, switch to the other player
			current_character = "O" if current_character == "X" else "X"
			# Update the label to show whose turn it is
			%lblMainText.text = current_character + "'s Move"

# This function is called when the reset button is pressed
func _on_btn_reset_pressed():
	# Loop through all buttons on the board
	for row in available_buttons:
		for button_name in row:
			# Get each button and clear its text
			var button = get_node("vbxSingleColLayout/grdMainContainer/%s" % button_name)
			button.text = ""

	# Reset the game state
	game_over = false          # The game is no longer over
	current_character = "X"    # X starts again
	# Update the label to show it's X's turn
	%lblMainText.text = current_character + "'s Move"
