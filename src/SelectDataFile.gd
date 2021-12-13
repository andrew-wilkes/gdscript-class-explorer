extends WindowDialog

signal selected_data_file(file)

func show_files():
	var n = 0
	var files = Data.get_file_list("")
	for b in $VBox.get_children():
		if n > 0:
			b.hide()
		n += 1
	n = 1
	for file in files:
		# Don't show current data file
		if file == Data.settings.data_file:
			continue
		if file.get_extension() == "dat":
			var button: Button
			if n < $VBox.get_child_count():
				button = $VBox.get_child(n)
			else:
				button = $VBox/Button.duplicate()
				$VBox.add_child(button)
			n += 1
			button.text = file
			button.show()
			if not button.is_connected("pressed", self, "close"):
				var _e = button.connect("pressed", self, "close", [button])
			call_deferred("fit_content")
	if n == 1:
		$VBox/Label.text = "No new data files found."


func close(button):
	emit_signal("selected_data_file", button.text)
	hide()


func fit_content():
	rect_size = $VBox.rect_size + Vector2(15, 15)


func _on_SelectDataFile_about_to_show():
	show_files()
