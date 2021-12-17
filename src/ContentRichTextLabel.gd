extends RichTextLabel

class_name RichContent

export(Color) var code_color = Color(255, 155, 0)

var links_regex
var codeblock_regex
var codeblocks_regex

func _ready():
	links_regex = RegEx.new()
	links_regex.compile("\\[([A-Z][\\w\\d]+|bool|int|float|(\\w+ ([\\w\\d]+)))\\]")
	codeblock_regex = RegEx.new()
	codeblock_regex.compile("")
	codeblocks_regex = RegEx.new()
	codeblocks_regex.compile("")


func set_content(txt: String):
	txt = add_links(txt)
	txt = convert_colors(txt)
	txt = txt.c_unescape()
	txt = txt.replace("[code]", "[code][color=#" + code_color.to_html(false) + "]") \
	.replace("[/code]", "[/color][/code]")
	var bbcode =  parse_codeblocks(txt)
	if parse_bbcode(bbcode) != OK:
		print("Error parsing bbcode for: " + Data.selected_class)


func parse_codeblocks(txt: String):
	# Assume single blocks of code are GDScript
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
	var regex = RegEx.new()
	regex.compile("Color\\(([0-9\\., ]+?)\\)")
	for result in regex.search_all(txt):
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
