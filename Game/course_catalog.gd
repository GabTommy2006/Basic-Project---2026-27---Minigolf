extends RefCounted

const COUNT := 10
var courses: Array = []

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://Game/courses.json"))
	assert(parsed is Dictionary and parsed.get("courses") is Array)
	courses = parsed.courses
	assert(courses.size() == COUNT)
	for index in COUNT:
		assert(int(courses[index].number) == index + 1)
		assert(int(courses[index].three_star_strokes) > 0)
		assert(int(courses[index].two_star_strokes) >= int(courses[index].three_star_strokes))

func path(number: int) -> String:
	return "res://Maps/Courses/Map%d.tscn" % clampi(number, 1, COUNT)

func stars(number: int, strokes: int) -> int:
	var course: Dictionary = courses[clampi(number, 1, COUNT) - 1]
	if strokes <= int(course.three_star_strokes):
		return 3
	if strokes <= int(course.two_star_strokes):
		return 2
	return 1

func target(number: int) -> int:
	return int(courses[clampi(number, 1, COUNT) - 1].three_star_strokes)
