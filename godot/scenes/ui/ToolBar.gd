extends HBoxContainer

signal item_selected(globals_itemtype, costs_or_null)
signal player_inventory_changed(inventory)

var is_active
var selected_item: int = Globals.ItemType.ToolScythe
var selected_item_subspace: float = Globals.ItemType.ToolScythe
const child_count := 9

const ITEM_NAMES := [
	"ToolItem1",
	"ToolItem2",
	"PlantItem1",
	"PlantItem2",
	"PlantItem3",
	"PlantItem4",
	"BuildItem1",
	"BuildItem2",
	"BuildItem3",
]

func get_item_node(id) -> Node:
	return get_node(ITEM_NAMES[id - 1])

func _ready():
	for item in Globals.ItemType.values():
		if item == Globals.ItemType.values()[Globals.ItemType.None]:
			continue
		var item_node := get_item_node(item)
		item_node.slot_id = item
		item_node.connect("item_selected", self, "_on_Toolbar_item_selected")
		connect("player_inventory_changed", item_node, "_on_player_inventory_changed")

		item_node.set_item(item)
		item_node.register_callback(self)
	update_selected_item(true)

func _on_Toolbar_item_selected(slot_id, _costs_or_null):
	selected_item_subspace = slot_id
	update_selected_item()

func _process(_delta):
	if not is_active:
		return
	var zoom_mod := Input.is_action_pressed("zoom_modifier")
	var mouse_scroll_left := not zoom_mod and Input.is_action_just_released("scroll_left_mouse")
	var mouse_scroll_right := not zoom_mod and Input.is_action_just_released("scroll_right_mouse")
	# TODO: scrolling with joypad with different action
	#       beacause scroll buttons don't support Input.get_axis :(
	var scroll := float(mouse_scroll_right) - float(mouse_scroll_left)
	if scroll != 0:
		selected_item_subspace += scroll
		update_selected_item()
	else:
		for item in range(child_count):
			if Input.is_action_just_pressed("toolbar_item" + str(item + 1)):
				selected_item_subspace = item + Globals.ItemType.ToolScythe
				update_selected_item()
				break

func update_selected_item(force=false):
	if selected_item_subspace < 1:
		selected_item_subspace = child_count + selected_item_subspace
	elif selected_item_subspace >= child_count + 1:
		selected_item_subspace -= child_count
	var new_selected_item: int = int(floor(selected_item_subspace))
	if !force and new_selected_item == selected_item:
		return
	selected_item = new_selected_item

	var costs_or_null = get_item_node(selected_item).get_costs()
	emit_signal("item_selected", selected_item, costs_or_null)

func update_inventory(inventory):
	emit_signal("player_inventory_changed", inventory)

	var item_node = get_item_node(selected_item)
	if item_node.has_costs() and not inventory.can_pay(item_node.get_costs()):
		_on_Toolbar_item_selected(Globals.ItemType.ToolScythe, null)
