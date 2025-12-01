extends Control

signal closed

@onready var panel = $Panel
@onready var npc_name_label = $Panel/TitleBar/Label
@onready var messages_container = $Panel/VBoxContainer/ContentContainer/CurrentChat/ScrollContainer/MessagesContainer
@onready var scroll_container = $Panel/VBoxContainer/ContentContainer/CurrentChat/ScrollContainer
@onready var history_container = $Panel/VBoxContainer/ContentContainer/HistoryPanel/ScrollContainer/HistoryMessages
@onready var history_scroll = $Panel/VBoxContainer/ContentContainer/HistoryPanel/ScrollContainer
@onready var input_field = $Panel/VBoxContainer/InputContainer/InputField
@onready var send_button = $Panel/VBoxContainer/InputContainer/SendButton
@onready var status_label = $Panel/VBoxContainer/StatusLabel
@onready var current_tab = $Panel/VBoxContainer/TabContainer/CurrentTab
@onready var history_tab = $Panel/VBoxContainer/TabContainer/HistoryTab
@onready var current_chat_panel = $Panel/VBoxContainer/ContentContainer/CurrentChat
@onready var history_panel = $Panel/VBoxContainer/ContentContainer/HistoryPanel
@onready var http_request = $HTTPRequest
@onready var summary_http_request = $SummaryHTTPRequest

var current_npc_id: String = ""
var current_npc_data: Dictionary = {}
var player_data: Dictionary = {}
var player_id: String = "player_1"
var current_session_messages: Array = []  # Messages in current session only
var system_prompt: String = ""

var dragging = false
var _llm_client
var _context_builder
var _awaiting_greeting = false
var _summarizing = false

# Action mode - when enabled, NPC can take actions based on conversation
var action_mode_enabled: bool = false
var _current_npc_node: Node2D = null

func _ready():
	visible = false
	_llm_client = preload("res://src/services/llm_client.gd").new()
	_context_builder = preload("res://src/services/npc_context_builder.gd").new()
	http_request.request_completed.connect(_on_http_request_completed)
	summary_http_request.request_completed.connect(_on_summary_request_completed)
	
	# Handle LLM client failures (e.g., no API key configured)
	_llm_client.request_failed.connect(_on_llm_request_failed)
	
	# Tab switching
	current_tab.pressed.connect(_show_current_chat)
	history_tab.pressed.connect(_show_history)
	
	# Ensure input field can receive focus
	if input_field:
		input_field.focus_mode = Control.FOCUS_ALL
		input_field.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		push_error("DialogueWindow: input_field is null!")

func open(npc_id: String, npc_node: Node2D = null):
	current_npc_id = npc_id
	current_npc_data = DatabaseManager.characters.get_by_id(npc_id)
	player_data = DatabaseManager.characters.get_player()
	player_id = player_data.get("id", "player_1")
	_current_npc_node = npc_node
	
	if not current_npc_data:
		print("DialogueWindow: NPC not found: ", npc_id)
		return
	
	# Clear current session
	current_session_messages.clear()
	_clear_messages()
	
	# Build system prompt - use action mode if NPC node is provided
	if action_mode_enabled and _current_npc_node:
		system_prompt = _context_builder.build_action_prompt(npc_id, player_id, _current_npc_node)
		print("DialogueWindow: Action mode enabled for ", npc_id)
	else:
		system_prompt = _context_builder.build_system_prompt(npc_id, player_id)
	
	# Update UI
	npc_name_label.text = "Talking to: " + current_npc_data.get("name", "Unknown")
	status_label.text = ""
	input_field.text = ""
	input_field.editable = true  # Ensure input is enabled
	send_button.disabled = false
	
	# Show current chat tab
	_show_current_chat()
	
	# Load history into history panel
	_load_history()
	
	visible = true
	_center_panel()
	
	# Check if we should generate a greeting
	var has_met = DatabaseManager.conversations.has_previous_conversations(npc_id, player_id)
	if has_met:
		_request_greeting()
	else:
		# First meeting - no greeting needed, just let player type
		await get_tree().process_frame  # Wait a frame for UI to be ready
		input_field.grab_focus()

func _center_panel():
	var viewport_size = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2

func _show_current_chat():
	current_chat_panel.visible = true
	history_panel.visible = false
	current_tab.disabled = true
	history_tab.disabled = false

func _show_history():
	current_chat_panel.visible = false
	history_panel.visible = true
	current_tab.disabled = false
	history_tab.disabled = true

func _load_history():
	# Clear history container
	for child in history_container.get_children():
		child.queue_free()
	
	var messages = DatabaseManager.conversations.get_messages(current_npc_id, player_id)
	
	if messages.is_empty():
		var label = Label.new()
		label.text = "No previous conversations."
		label.add_theme_font_size_override("font_size", 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_container.add_child(label)
		return
	
	for msg in messages:
		var is_player = msg.get("role") == "user"
		var sender = player_data.get("name", "You") if is_player else current_npc_data.get("name", "NPC")
		_add_message_to_container(history_container, sender, msg.get("content", ""), is_player)

func _clear_messages():
	for child in messages_container.get_children():
		child.queue_free()

func _add_message(sender_name: String, content: String, is_player: bool):
	_add_message_to_container(messages_container, sender_name, content, is_player)
	
	# Scroll to bottom
	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _add_message_to_container(container: Control, sender_name: String, content: String, is_player: bool):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var bubble_content = VBoxContainer.new()
	bubble_content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bubble_content.custom_minimum_size.x = 150
	
	var name_label = Label.new()
	name_label.text = sender_name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_END if is_player else Control.SIZE_SHRINK_BEGIN
	
	var style = StyleBoxFlat.new()
	if is_player:
		style.bg_color = Color(0.2, 0.4, 0.6, 1.0)
	else:
		style.bg_color = Color(0.3, 0.3, 0.35, 1.0)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(20)
	bubble.add_theme_stylebox_override("panel", style)
	
	var message_label = Label.new()
	message_label.text = content
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size.x = 300
	message_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	message_label.add_theme_font_size_override("font_size", 28)
	
	bubble.add_child(message_label)
	
	if is_player:
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bubble_content.add_child(name_label)
		bubble_content.add_child(bubble)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(bubble_content)
	else:
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		bubble_content.add_child(name_label)
		bubble_content.add_child(bubble)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bubble_content)
		row.add_child(spacer)
	
	container.add_child(row)

func _request_greeting():
	_awaiting_greeting = true
	input_field.editable = false
	send_button.disabled = true
	status_label.text = "..."
	
	var greeting_prompt = _context_builder.build_greeting_prompt(current_npc_id, player_id)
	
	var messages = [
		{"role": "system", "content": greeting_prompt},
		{"role": "user", "content": "Generate a greeting."}
	]
	
	print("DialogueWindow: Requesting greeting from LLM...")
	_llm_client.send_message(messages, http_request)

func _on_llm_request_failed(error: String):
	print("DialogueWindow: LLM request failed - ", error)
	_awaiting_greeting = false
	input_field.editable = true
	send_button.disabled = false
	status_label.text = error
	input_field.grab_focus()

func _on_send_pressed():
	var message = input_field.text.strip_edges()
	if message == "":
		return
	
	input_field.text = ""
	_send_player_message(message)

func _on_input_text_submitted(new_text: String):
	_on_send_pressed()

func _send_player_message(message: String):
	# Add to UI
	_add_message(player_data.get("name", "You"), message, true)
	
	# Add to current session
	current_session_messages.append({
		"role": "user",
		"content": message
	})
	
	# Save to conversation history
	DatabaseManager.conversations.add_message(current_npc_id, player_id, "user", message)
	
	# Disable input while waiting
	input_field.editable = false
	send_button.disabled = true
	status_label.text = "Waiting for response..."
	
	# Build messages array for API
	var messages = []
	messages.append({
		"role": "system",
		"content": system_prompt
	})
	
	for msg in current_session_messages:
		messages.append(msg)
	
	# Send to LLM
	_llm_client.send_message(messages, http_request)

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	input_field.editable = true
	send_button.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		status_label.text = "Network error"
		_awaiting_greeting = false
		return
	
	var provider = DatabaseManager.settings.get_current_provider()
	var response_text = _llm_client.parse_response(provider, response_code, body)
	
	if response_text == "":
		status_label.text = "Failed to get response (check API key/model)"
		_awaiting_greeting = false
		return
	
	status_label.text = ""
	
	if _awaiting_greeting:
		_awaiting_greeting = false
		# Add greeting to UI only (not to session messages, it's just a greeting)
		var greeting_text = _extract_dialogue_from_response(response_text)
		_add_message(current_npc_data.get("name", "NPC"), greeting_text, false)
		input_field.grab_focus()
		return
	
	# Parse response - handle both plain text and action JSON
	var dialogue_text = ""
	var has_actions = false
	
	if action_mode_enabled and _current_npc_node:
		var parsed = _parse_action_response(response_text)
		dialogue_text = parsed.dialogue
		has_actions = parsed.has_actions
		
		# Execute any actions
		if has_actions:
			var action_result = DatabaseManager.execute_npc_actions(_current_npc_node, response_text)
			if action_result.success:
				print("DialogueWindow: Executing ", action_result.action_count, " actions")
			else:
				print("DialogueWindow: Action execution failed - ", action_result.error)
	else:
		dialogue_text = response_text
	
	# Add NPC response to session
	current_session_messages.append({
		"role": "assistant",
		"content": response_text
	})
	
	# Save to conversation history (save full response for context)
	DatabaseManager.conversations.add_message(current_npc_id, player_id, "assistant", dialogue_text)
	
	# Add to UI (only show dialogue, not the full JSON)
	if dialogue_text != "":
		_add_message(current_npc_data.get("name", "NPC"), dialogue_text, false)
	
	input_field.grab_focus()

func _on_close_pressed():
	# Create memory of conversation
	if current_session_messages.size() > 0:
		DatabaseManager.npc_memories.create_conversation_memory(
			current_npc_id, 
			player_data.get("name", "the adventurer")
		)
		
		# Initialize relationship if first meeting
		DatabaseManager.relationships.get_or_create(current_npc_id, player_id)
		DatabaseManager.relationships.get_or_create(player_id, current_npc_id)
		
		# Request async summarization
		_request_summarization()
	
	visible = false
	emit_signal("closed")

func _request_summarization():
	if current_session_messages.size() < 2:
		return  # Not enough to summarize
	
	_summarizing = true
	
	var summary_prompt = _context_builder.build_summarization_prompt(
		current_npc_id, 
		player_id, 
		current_session_messages
	)
	
	var messages = [
		{"role": "system", "content": summary_prompt},
		{"role": "user", "content": "Summarize this conversation."}
	]
	
	_llm_client.send_message(messages, summary_http_request)

func _on_summary_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	_summarizing = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("DialogueWindow: Summary request failed")
		return
	
	var provider = DatabaseManager.settings.get_current_provider()
	var summary = _llm_client.parse_response(provider, response_code, body)
	
	if summary != "":
		# Get existing summary and append
		var existing = DatabaseManager.conversations.get_summary(current_npc_id, player_id)
		var new_summary = summary
		if existing != "":
			new_summary = existing + "\n\n" + summary
		
		DatabaseManager.conversations.update_summary(current_npc_id, player_id, new_summary)
		print("DialogueWindow: Conversation summarized")

func _on_titlebar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		panel.position += event.relative

# Parse an action-mode response to extract dialogue and detect actions
func _parse_action_response(response_text: String) -> Dictionary:
	var result = {
		"dialogue": response_text,
		"has_actions": false
	}
	
	# Try to parse as JSON
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result != OK:
		# Not valid JSON - treat as plain text
		return result
	
	var data = json.data
	if not data is Dictionary:
		return result
	
	# Extract dialogue
	result.dialogue = data.get("dialogue", "")
	
	# Check for actions
	var actions = data.get("actions", [])
	if actions is Array and actions.size() > 0:
		result.has_actions = true
	
	return result

# Extract just the dialogue from a response (handles both JSON and plain text)
func _extract_dialogue_from_response(response_text: String) -> String:
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result != OK:
		return response_text
	
	var data = json.data
	if data is Dictionary and data.has("dialogue"):
		return data.get("dialogue", response_text)
	
	return response_text

# Enable or disable action mode
func set_action_mode(enabled: bool):
	action_mode_enabled = enabled
	print("DialogueWindow: Action mode ", "enabled" if enabled else "disabled")
