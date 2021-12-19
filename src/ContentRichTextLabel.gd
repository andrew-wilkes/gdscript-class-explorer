extends RichTextLabel

class_name RichContent

export(Color) var code_color = Color(255, 155, 0)
export(Color) var lang_name_color = Color.greenyellow

var links_regex
var code_regex
var code_block_regex
var code_blocks_regex
var code_snippets_regex
var bb_regex
var color_regex

func _ready():
	links_regex = RegEx.new()
	links_regex.compile("\\[([A-Z][\\w\\d]+|bool|int|float|(\\w+ ([\\w\\d]+)))\\]")
	code_regex = RegEx.new()
	code_regex.compile("\\[code\\](.+?)\\[/code\\]")
	code_block_regex = RegEx.new()
	code_block_regex.compile("(?s)\\[codeblock\\](.*?)\\[/codeblock\\]")
	code_blocks_regex = RegEx.new()
	code_blocks_regex.compile("(?s)\\[codeblocks\\](.*?)\\[/codeblocks\\]")
	code_snippets_regex = RegEx.new()
	code_snippets_regex.compile("(?s)\\[(gdscript|csharp)\\](.*?)\\[/(?:gdscript|csharp)\\]")
	bb_regex = RegEx.new()
	bb_regex.compile("\\[.+?\\]")
	color_regex = RegEx.new()
	color_regex.compile("Color\\(([0-9\\., ]+?)\\)")
	
	if get_parent().name == "root":
		test_parser()


func set_content(txt: String):
	txt = add_links(txt)
	txt = convert_colors(txt)
	txt = txt.c_unescape() # Should have commented on why this was needed
	txt = txt.replace("kbd]", "code]") # A kbd tag shows up one time in the whole of the docs xml of Godot 4
	var bbcode =  parse_codeblocks(txt)
	if parse_bbcode(bbcode) != OK:
		print("Error parsing bbcode for: " + Data.selected_class)


func test_parser():
	print(parse_codeblocks(bbcode_text))


func parse_codeblocks(txt: String):
	# Just colorize inline code
	for result in code_regex.search_all(txt):
		var code_block = result.get_string(0)
		if code_block.length() > 0:
			var inner = result.get_string(1)
			var new = code_block.replace(inner, filter_bbcode(inner))
			txt = txt.replace(code_block, highlight_code(new))

	# Assume single blocks of code are GDScript
	for result in code_block_regex.search_all(txt):
		var code_block = result.get_string(0)
		if code_block.length() > 0:
			txt = txt.replace(code_block, highlight_code("[code]" + filter_bbcode(result.get_string(1)) + "[/code]"))

	# Codeblocks
	for result in code_blocks_regex.search_all(txt):
		var code_block = result.get_string(0)
		if code_block.length() > 0:
			var new = PoolStringArray([])
			for block in code_snippets_regex.search_all(code_block):
				var snippet = block.get_string(0)
				if snippet.length() > 0:
					# Add lang name
					new.append("[color=#" + lang_name_color.to_html(false) + "]" + get_lang_name(block.get_string(1)) + "[/color]")
					# Add highlighted code
					new.append(highlight_code("[code]" + filter_bbcode(block.get_string(2)) + "[/code]"))
			txt = txt.replace(code_block, new.join("\n"))
	return txt


# This wraps the code tags, but later, this could be an inner-content syntax highlighter. But the Doc code snippets are very short so far.
func highlight_code(code):
	return "[color=#" + code_color.to_html(false) + "]" + code + "[/color]"


# Prevent bb_code from working in codeblock and breaking the tag stack
func filter_bbcode(code):
	for result in bb_regex.search_all(code):
		var bb_code = result.get_string(0)
		if bb_code.length() > 0:
			code = code.replace(bb_code, "[[/code][code]" + bb_code.substr(1))
	return code


func get_lang_name(txt):
	if txt == "csharp":
		return "C#" # That seems like the correct name for it
	if txt == "gdscript":
		return "GDScript"
	return txt


func add_links(txt: String):
	for result in links_regex.search_all(txt):
		var url = result.get_string(1)
		var link_text = url
		var goto = result.get_string(2)
		if goto.length() > 0:
			url = goto
			link_text = result.get_string(3)
		var link = "[url=%s]%s[/url]" % [url, link_text]
		var target = result.get_string(0)
		txt = txt.replace(target, link)
	return txt


func convert_colors(txt: String):
	# Color( 0.6, 0.8, 0.2, 1 ) > [color=#ffffff]Color( 0.6, 0.8, 0.2, 1 )[/color]
	for result in color_regex.search_all(txt):
		var col_code = result.get_string(0)
		var rgb_code = result.get_string(1)
		if rgb_code.length() > 0:
			var rgb = rgb_code.split(", ")
			if rgb.size() > 2:
				var bbcode = "[color=#%02x%02x%02x]%s[/color]" % [rgb_to_num(rgb[0]), rgb_to_num(rgb[1]), rgb_to_num(rgb[2]), col_code]
				txt = txt.replace(col_code, bbcode)
	return txt


func rgb_to_num(rgb):
	return float(rgb) * 255
