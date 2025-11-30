extends RefCounted

# LLM Client - handles API calls to various LLM providers

signal response_received(response: String)
signal request_failed(error: String)

const ENDPOINTS = {
	"xai": "https://api.x.ai/v1/chat/completions",
	"openai": "https://api.openai.com/v1/chat/completions",
	"anthropic": "https://api.anthropic.com/v1/messages",
	"gemini": "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
}

var _http_request: HTTPRequest = null
var _current_provider: String = ""

func send_message(messages: Array, http_node: HTTPRequest, provider: String = "", api_key: String = "", model: String = ""):
	_http_request = http_node
	
	# Use settings if not provided
	if provider == "":
		provider = DatabaseManager.settings.get_current_provider()
	if api_key == "":
		api_key = DatabaseManager.settings.get_current_api_key()
	if model == "":
		model = DatabaseManager.settings.get_current_model()
	
	_current_provider = provider
	
	if api_key.strip_edges() == "":
		emit_signal("request_failed", "No API key configured. Check Settings.")
		return
	
	if model.strip_edges() == "":
		emit_signal("request_failed", "No model selected. Check Settings.")
		return
	
	var endpoint = ENDPOINTS.get(provider, "")
	if endpoint == "":
		emit_signal("request_failed", "Unknown provider: " + provider)
		return
	
	var headers = _get_headers(provider, api_key)
	var body = _build_request_body(provider, model, messages)
	
	# For Gemini, model is in URL
	if provider == "gemini":
		endpoint = endpoint.replace("{model}", model) + "?key=" + api_key
	
	print("LLMClient: Sending request to ", provider, " using model ", model)
	
	var error = _http_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		emit_signal("request_failed", "HTTP request failed to start")

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
			headers.append("Content-Type: application/json")
	
	return headers

func _build_request_body(provider: String, model: String, messages: Array) -> Dictionary:
	match provider:
		"xai", "openai":
			return {
				"model": model,
				"messages": messages,
				"max_tokens": 1024,
				"temperature": 0.8
			}
		"anthropic":
			# Anthropic uses a different format - system message separate
			var system_msg = ""
			var user_messages = []
			
			for msg in messages:
				if msg["role"] == "system":
					system_msg = msg["content"]
				else:
					user_messages.append({
						"role": msg["role"],
						"content": msg["content"]
					})
			
			var body = {
				"model": model,
				"max_tokens": 1024,
				"messages": user_messages
			}
			if system_msg != "":
				body["system"] = system_msg
			return body
		"gemini":
			# Gemini uses a different format
			var contents = []
			var system_instruction = ""
			
			for msg in messages:
				if msg["role"] == "system":
					system_instruction = msg["content"]
				else:
					var role = "user" if msg["role"] == "user" else "model"
					contents.append({
						"role": role,
						"parts": [{"text": msg["content"]}]
					})
			
			var body = {"contents": contents}
			if system_instruction != "":
				body["systemInstruction"] = {"parts": [{"text": system_instruction}]}
			return body
	
	return {}

func parse_response(provider: String, response_code: int, body: PackedByteArray) -> String:
	if response_code != 200:
		var error_text = body.get_string_from_utf8()
		print("LLMClient: HTTP error ", response_code, ": ", error_text.substr(0, 200))
		return ""
	
	var json = JSON.new()
	var body_str = body.get_string_from_utf8()
	
	if json.parse(body_str) != OK:
		print("LLMClient: Failed to parse response")
		return ""
	
	var data = json.data
	
	match provider:
		"xai", "openai":
			# { "choices": [ { "message": { "content": "..." } } ] }
			if data.has("choices") and data["choices"].size() > 0:
				var choice = data["choices"][0]
				if choice.has("message") and choice["message"].has("content"):
					return choice["message"]["content"]
		"anthropic":
			# { "content": [ { "text": "..." } ] }
			if data.has("content") and data["content"].size() > 0:
				var content = data["content"][0]
				if content.has("text"):
					return content["text"]
		"gemini":
			# { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
			if data.has("candidates") and data["candidates"].size() > 0:
				var candidate = data["candidates"][0]
				if candidate.has("content") and candidate["content"].has("parts"):
					var parts = candidate["content"]["parts"]
					if parts.size() > 0 and parts[0].has("text"):
						return parts[0]["text"]
	
	print("LLMClient: Could not extract response from ", provider)
	return ""

