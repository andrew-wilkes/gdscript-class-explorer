extends Resource

class_name Settings

export var class_list = []

export(int) var list_mode = 0
export(int) var sort_order = 0
export(int) var group_mode = 0
export var data_file = ""

func get_class_from_list(cname):
	for c in class_list:
		var _class: ClassItem = c
		if _class.keyword == cname:
			return _class
