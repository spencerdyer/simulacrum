extends RefCounted

# Prompt Template Manager - loads and renders prompt templates

const TEMPLATES_PATH = "res://src/prompt_templates/"

var _cache = {}  # Cache loaded templates

func get_template(category: String, template_name: String) -> String:
	var key = category + "/" + template_name
	
	if _cache.has(key):
		return _cache[key]
	
	var path = TEMPLATES_PATH + category + "/" + template_name + ".txt"
	
	if not FileAccess.file_exists(path):
		print("PromptTemplates: Template not found: ", path)
		return ""
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		_cache[key] = content
		return content
	
	return ""

func render_template(template: String, variables: Dictionary) -> String:
	var result = template
	
	for key in variables.keys():
		var placeholder = "{{" + key + "}}"
		var value = str(variables[key])
		result = result.replace(placeholder, value)
	
	return result

func get_and_render(category: String, template_name: String, variables: Dictionary) -> String:
	var template = get_template(category, template_name)
	if template == "":
		return ""
	return render_template(template, variables)

func clear_cache():
	_cache.clear()

