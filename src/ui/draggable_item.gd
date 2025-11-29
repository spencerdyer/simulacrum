extends Button

var item_data = {}

func _get_drag_data(_at_position):
	# Create a visual preview
	var preview = Label.new()
	preview.text = item_data["name"]
	set_drag_preview(preview)
	
	# Return data payload
	return {
		"source": "inventory",
		"item": item_data
	}

