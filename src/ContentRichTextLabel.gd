extends RichTextLabel

class_name RichContent

export(Color) var code_color = Color(255, 155, 0)

func set_content(txt: String):
	txt = add_links(txt)
	txt = convert_colors(txt)
	bbcode_text = txt.c_unescape() \
	.replace("codeblock]", "code]") \
	.replace("[code]", "[code][color=#" + code_color.to_html(false) + "]") \
	.replace("[/code]", "[/color][/code]")


func add_links(txt: String):
	var regex = RegEx.new()
	regex.compile("\\[([A-Z][\\w\\d]+|bool|int|float|(\\w+ (\\w+[\\w\\d_]*\\w*)\\d*))\\]")
	for result in regex.search_all(txt):
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
				var bbcode = "[color=#%02x%02x%02x]%s[/color]" % [float(rgb[0]) * 255, float(rgb[1]) * 255, float(rgb[2]) * 255, col_code]
				txt = txt.replace(col_code, bbcode)
	return txt
