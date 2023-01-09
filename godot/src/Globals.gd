extends Node

enum Direction {
	None,
	Left,
	Right,
	Up,
	Down
}

enum ItemType {
	None
	ToolScythe,
	ToolWateringCan,
	PlantChili,
	PlantTomato,
	PlantPotato,
	PlantAubergine,
	TowerWindmill,
	TowerWatertower,
	TowerWIP
}

const ITEM_NAMES = {
	# Items
	ItemType.ToolScythe : "Scythe",
	ItemType.ToolWateringCan : "Watering Can",

	# Plants
	ItemType.PlantChili : "Chili",
	ItemType.PlantTomato : "Tomato",
	ItemType.PlantAubergine : "Aubergine",
	ItemType.PlantPotato : "Potato",

	# Towers
	ItemType.TowerWindmill : "Windmill",
	ItemType.TowerWatertower : "Watertower",
	ItemType.TowerWIP : "WIP"
}

const TOOLS = [
	ItemType.ToolScythe,
	ItemType.ToolWateringCan
]

const PLANTS = [
	ItemType.PlantChili,
	ItemType.PlantTomato,
	ItemType.PlantAubergine,
	ItemType.PlantPotato
]

const TOWERS = [
	ItemType.TowerWindmill,
	ItemType.TowerWatertower,
	ItemType.TowerWIP
]

var ITEM_TEXTURE_LOOKUP = {
	ItemType.None : 0,
	
	# Items
	ItemType.ToolScythe : 1,
	ItemType.ToolWateringCan : 2,

	#Plants
	ItemType.PlantChili : 3,
	ItemType.PlantTomato : 4,
	ItemType.PlantPotato : 5,
	ItemType.PlantAubergine : 6,

	# Towers
	ItemType.TowerWindmill : 7,
	ItemType.TowerWatertower : 8,
	ItemType.TowerWIP : 9
}
