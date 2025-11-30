extends RefCounted

# LLM Provider Service - fetches models from various LLM providers

signal models_fetched(provider: String, models: Array)
signal fetch_failed(provider: String, error: String)

const PROVIDER_ENDPOINTS = {
	"xai": "https://api.x.ai/v1/models",
	"openai": "https://api.openai.com/v1/models",
	"anthropic": "https://api.anthropic.com/v1/models",
	"gemini": "https://generativelanguage.googleapis.com/v1beta/models"
}

const PROVIDER_NAMES = {
	"xai": "xAI (Grok)",
	"openai": "OpenAI",
	"anthropic": "Anthropic (Claude)",
	"gemini": "Google Gemini"
}

var _http_request: HTTPRequest = null
var _current_provider: String = ""
var _current_api_key: String = ""

func get_provider_names() -> Dictionary:
	return PROVIDER_NAMES

func get_provider_ids() -> Array:
	return ["xai", "openai", "gemini", "anthropic"]

func fetch_models(provider: String, api_key: String, http_node: HTTPRequest):
	if api_key.strip_edges() == "":
		emit_signal("fetch_failed", provider, "No API key provided")
		return
	
	_http_request = http_node
	_current_provider = provider
	_current_api_key = api_key
	
	var endpoint = PROVIDER_ENDPOINTS.get(provider, "")
	if endpoint == "":
		emit_signal("fetch_failed", provider, "Unknown provider")
		return
	
	var headers = _get_headers(provider, api_key)
	
	# For Gemini, API key is in query param
	if provider == "gemini":
		endpoint += "?key=" + api_key
	
	print("LLMProvider: Fetching models from ", provider)
	
	var error = _http_request.request(endpoint, headers, HTTPClient.METHOD_GET)
	if error != OK:
		emit_signal("fetch_failed", provider, "HTTP request failed")

func _get_headers(provider: String, api_key: String) -> PackedStringArray:
	var headers = PackedStringArray()
	
	match provider:
		"xai":
			headers.append("Authorization: Bearer " + api_key)
			headers.append("Content-Type: application/json")
		"openai":
			headers.append("Authorization: Bearer " + api_key)
			headers.append("Content-Type: application/json")
		"anthropic":
			headers.append("x-api-key: " + api_key)
			headers.append("anthropic-version: 2023-06-01")
			headers.append("Content-Type: application/json")
		"gemini":
			# API key in query param, no auth header needed
			headers.append("Content-Type: application/json")
	
	return headers

func parse_response(provider: String, response_code: int, body: PackedByteArray) -> Array:
	if response_code != 200:
		print("LLMProvider: HTTP error ", response_code, " from ", provider)
		return []
	
	var json = JSON.new()
	var body_str = body.get_string_from_utf8()
	
	if json.parse(body_str) != OK:
		print("LLMProvider: Failed to parse response from ", provider)
		return []
	
	var data = json.data
	var models = []
	
	match provider:
		"xai":
			# xAI returns { "data": [ { "id": "grok-..." }, ... ] }
			if data.has("data"):
				for model in data["data"]:
					if model.has("id"):
						models.append(model["id"])
		"openai":
			# OpenAI returns { "data": [ { "id": "gpt-4", ... }, ... ] }
			if data.has("data"):
				for model in data["data"]:
					if model.has("id"):
						# Filter to chat models
						var id = model["id"]
						if "gpt" in id or "o1" in id or "o3" in id:
							models.append(id)
		"anthropic":
			# Anthropic returns { "data": [ { "id": "claude-...", ... }, ... ] }
			if data.has("data"):
				for model in data["data"]:
					if model.has("id"):
						models.append(model["id"])
			else:
				# Fallback: Anthropic might not have a models endpoint, use known models
				models = ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307", "claude-3-5-sonnet-20241022"]
		"gemini":
			# Gemini returns { "models": [ { "name": "models/gemini-pro", ... }, ... ] }
			if data.has("models"):
				for model in data["models"]:
					if model.has("name"):
						var name = model["name"]
						# Strip "models/" prefix
						if name.begins_with("models/"):
							name = name.substr(7)
						models.append(name)
	
	models.sort()
	return models

