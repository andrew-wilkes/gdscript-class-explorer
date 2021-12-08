extends Resource

class_name Settings

export var class_list = []

func get_class_from_list(cname):
	for c in class_list:
		var _class: ClassItem = c
		if _class.keyword == cname:
			return _class
