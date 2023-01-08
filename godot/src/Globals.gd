extends Node

enum ItemType {
	ToolScythe,
	ToolWateringCan,
	PlantChili,
	PlantTomato,
	PlantAubergine,
	PlantPotato,
	TowerWindmill,
	TowerWatertower,
	TowerWIP
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
