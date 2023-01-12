tool
extends Node2D

const CHARS = "/ :.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


#const CHAR_WIDHTS = [
##   /  _ . : 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L  M N O P  Q R S T U V  W X Y Z
#	10,5,3,3,7,5,7,7,7,6,7,6,7,7,8,8,7,8,7,7,8,8,3,8,9,7,10,9,8,8,10,8,7,7,8,8,10,8,9,7
#]
#const CHAR_HEIGHT = 13
#const CHAR_SPACING = 0
#const TEXTURE = preload("res://assets/ui/font.png")
#const RESOURCE_PATH = "res://assets/font.tres"

const CHAR_WIDHTS = [
#   / _ . : 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
	4,2,1,1,4,3,4,4,3,4,4,3,4,4,4,4,4,4,4,4,4,4,1,4,4,4,5,4,4,4,5,4,4,3,4,4,5,5,5,4
]
const CHAR_HEIGHT = 8
const CHAR_SPACING = 1
const TEXTURE = preload("res://assets/ui/font_small.png")
const RESOURCE_PATH = "res://assets/font_small.tres"

export var click_to_create_font = false setget create_font

func _ready():
	create_font()

func create_font(_v = null):
	var font:BitmapFont = BitmapFont.new()
	font.add_texture(TEXTURE)
	font.height = CHAR_HEIGHT

	var cur_x = 0
	for i in CHARS.length():
		var char_unicode = ord(CHARS[i])
		var char_width = CHAR_WIDHTS[i] + CHAR_SPACING

		font.add_char(char_unicode, 0, Rect2(cur_x, 0, char_width, TEXTURE.get_height()))

		if ord('A') <= char_unicode and char_unicode <= ord('Z'):
			var char_unicode_lower =  ord(CHARS[i].to_lower())
			font.add_char(char_unicode_lower, 0, Rect2(cur_x, 0, char_width, TEXTURE.get_height()))

		cur_x += char_width

	ResourceSaver.save(RESOURCE_PATH, font)
	prints("Saved Font to", RESOURCE_PATH)
