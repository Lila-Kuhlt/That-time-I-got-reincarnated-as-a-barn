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
