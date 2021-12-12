extends WindowDialog

var current_filename = ""
var download_status = OK

func _on_OK_pressed():
	url_selected($VBox/HBox/LineEdit.text)


func _on_Master_pressed():
	url_selected($VBox/Master.text)


func _on_LineEdit_text_entered(new_text):
	if new_text.begins_with("http"):
		url_selected(new_text)


func _on_LineEdit_text_changed(new_text: String):
	if new_text.begins_with("http"):
		$VBox/HBox/OK.disabled = false
	else:
		$VBox/HBox/OK.disabled = true


func url_selected(url: String):
	# ToDo: Add platform specific code and detect errors
	# unzip -u 3.4.zip "godot-3.4/doc/classes/*" -d 3.4
	OS.execute("wget", [url])
	current_filename = url.get_file()
	var file = File.new()
	if file.file_exists(current_filename):
		alert("Done")
		download_status = OK
	else:
		alert("There was an error downloading the file from:\n" + url)
		download_status = -1

	"""
	The HTTP code didn't work. Got TLS handshake problems.
	
	var error = $HTTPRequest.request(url)
	if error != OK:
		warn("There was an error connecting to:\n" + url)
	else:
		hide()
	"""

"""
func _on_HTTPRequest_request_completed(result, response_code, _headers, body):
	if result != OK:
		warn("There was an error code: " + str(result))
	elif response_code != 200:
		warn("There was a web server response code of " + str(result))
	else:
		var file = File.new()
		file.store_buffer(body)
"""

func alert(msg):
	get_node("Alert").dialog_text = msg
	get_node("Alert").popup_centered()


func _on_Alert_popup_hide():
	if download_status == OK:
		hide()
