extends Node2D

const CHARS = "/ :.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const CHAR_WIDHTS = [
#   /  _ . : 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L  M N O P  Q R S T U V  W X Y Z
	10,5,3,3,7,5,7,7,7,6,7,6,7,7,8,8,7,8,7,7,8,8,3,8,9,7,10,9,8,8,10,8,7,7,8,8,10,8,9,7
]

const TEXTURE = preload("res://assets/ui/font.png")

func _ready():
	var font:BitmapFont = BitmapFont.new()
	font.add_texture(TEXTURE)
	font.height = 13

	var cur_x = 0
	for i in CHARS.length():
		var char_unicode = ord(CHARS[i])
		var char_width = CHAR_WIDHTS[i]

		font.add_char(char_unicode, 0, Rect2(cur_x, 0, char_width, TEXTURE.get_height()))

		if ord('A') <= char_unicode and char_unicode <= ord('Z'):
			var char_unicode_lower =  ord(CHARS[i].to_lower())
			font.add_char(char_unicode_lower, 0, Rect2(cur_x, 0, char_width, TEXTURE.get_height()))

		cur_x += char_width

	ResourceSaver.save("res://assets/font.tres", font)
	print("Saved Font")
