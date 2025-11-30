extends Control

signal back_requested

@onready var panel = $Panel
@onready var provider_dropdown = $Panel/VBoxContainer/ProviderContainer/ProviderDropdown
@onready var api_key_input = $Panel/VBoxContainer/ApiKeyContainer/ApiKeyInput
@onready var model_dropdown = $Panel/VBoxContainer/ModelContainer/ModelDropdown
@onready var fetch_button = $Panel/VBoxContainer/ModelContainer/FetchButton
@onready var speculation_dropdown = $Panel/VBoxContainer/SpeculationContainer/SpeculationDropdown
@onready var status_label = $Panel/VBoxContainer/StatusLabel
@onready var http_request = $HTTPRequest

var dragging = false
var _current_fetching_provider = ""

func _ready():
	visible = false
	
	# Populate provider dropdown
	var providers = DatabaseManager.llm.get_provider_ids()
	var provider_names = DatabaseManager.llm.get_provider_names()
	
	provider_dropdown.clear()
	for provider_id in providers:
		provider_dropdown.add_item(provider_names[provider_id])
		provider_dropdown.set_item_metadata(provider_dropdown.item_count - 1, provider_id)
	
	# Populate speculation dropdown
	speculation_dropdown.clear()
	var modes = DatabaseManager.settings.get_speculation_modes()
	for mode_id in modes.keys():
		speculation_dropdown.add_item(modes[mode_id])
		speculation_dropdown.set_item_metadata(speculation_dropdown.item_count - 1, mode_id)
	
	# Connect HTTP request
	http_request.request_completed.connect(_on_http_request_completed)

func open():
	visible = true
	_center_panel()
	_load_current_settings()
	status_label.text = ""

func _center_panel():
	var viewport_size = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2

func _load_current_settings():
	# Set provider dropdown
	var current_provider = DatabaseManager.settings.get_current_provider()
	for i in range(provider_dropdown.item_count):
		if provider_dropdown.get_item_metadata(i) == current_provider:
			provider_dropdown.select(i)
			break
	
	# Set API key
	api_key_input.text = DatabaseManager.settings.get_api_key(current_provider)
	
	# Set model dropdown
	model_dropdown.clear()
	var current_model = DatabaseManager.settings.get_current_model()
	if current_model != "":
		model_dropdown.add_item(current_model)
		model_dropdown.select(0)
	
	# Set speculation mode
	var current_speculation = DatabaseManager.settings.get_speculation_mode()
	for i in range(speculation_dropdown.item_count):
		if speculation_dropdown.get_item_metadata(i) == current_speculation:
			speculation_dropdown.select(i)
			break

func _get_selected_provider() -> String:
	var idx = provider_dropdown.selected
	if idx >= 0:
		return provider_dropdown.get_item_metadata(idx)
	return "xai"

func _on_provider_changed(index: int):
	var provider = provider_dropdown.get_item_metadata(index)
	DatabaseManager.settings.set_current_provider(provider)
	
	# Load API key for this provider
	api_key_input.text = DatabaseManager.settings.get_api_key(provider)
	
	# Clear model dropdown
	model_dropdown.clear()
	status_label.text = "Provider changed. Fetch models to see available options."

func _on_api_key_changed(new_text: String):
	var provider = _get_selected_provider()
	DatabaseManager.settings.set_api_key(provider, new_text)

func _on_fetch_models_pressed():
	var provider = _get_selected_provider()
	var api_key = api_key_input.text.strip_edges()
	
	if api_key == "":
		status_label.text = "Please enter an API key first"
		return
	
	status_label.text = "Fetching models..."
	fetch_button.disabled = true
	_current_fetching_provider = provider
	
	DatabaseManager.llm.fetch_models(provider, api_key, http_request)

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	fetch_button.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		status_label.text = "Network error"
		return
	
	var models = DatabaseManager.llm.parse_response(_current_fetching_provider, response_code, body)
	
	if models.is_empty():
		status_label.text = "No models found or invalid API key"
		return
	
	model_dropdown.clear()
	for model in models:
		model_dropdown.add_item(model)
	
	# Try to select current model if it exists
	var current_model = DatabaseManager.settings.get_current_model()
	for i in range(model_dropdown.item_count):
		if model_dropdown.get_item_text(i) == current_model:
			model_dropdown.select(i)
			break
	
	status_label.text = "Found " + str(models.size()) + " models"

func _on_model_selected(index: int):
	var model = model_dropdown.get_item_text(index)
	DatabaseManager.settings.set_current_model(model)
	status_label.text = "Model saved: " + model

func _on_speculation_changed(index: int):
	var mode = speculation_dropdown.get_item_metadata(index)
	DatabaseManager.settings.set_speculation_mode(mode)
	status_label.text = "NPC speculation mode updated"

func _on_back_pressed():
	visible = false
	emit_signal("back_requested")

func _on_close_pressed():
	visible = false

func _on_titlebar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		panel.position += event.relative
