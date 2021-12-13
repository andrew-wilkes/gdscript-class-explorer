extends WindowDialog

var unzipped = OK

func show_files():
	var n = 0
	var files = Data.get_file_list("")
	for b in $VBox.get_children():
		if n > 0:
			b.hide()
		n += 1
	n = 1
	for file in files:
		if file.get_extension() == "zip":
			var button: Button
			if n < $VBox.get_child_count():
				button = $VBox.get_child(n)
			else:
				button = $VBox/Button.duplicate()
				$VBox.add_child(button)
			n += 1
			button.text = file
			button.show()
			if not button.is_connected("pressed", self, "extract"):
				var _e = button.connect("pressed", self, "extract", [button])
			call_deferred("fit_content")
	if n == 1:
		$VBox/Label.text = "No ZIP file(s) found."


func fit_content():
	rect_size = $VBox.rect_size + Vector2(15, 15)


func extract(button: Button):
	if OS.execute("tar", ["-xf", button.text]) != OK:
		alert("There was an error running tar on your computer.")
		return
	print(button.text)


func alert(msg):
	get_node("Alert").dialog_text = msg
	get_node("Alert").popup_centered()


func _on_Alert_popup_hide():
	if unzipped == OK:
		hide()


func _on_ZipExtract_about_to_show():
	show_files()
