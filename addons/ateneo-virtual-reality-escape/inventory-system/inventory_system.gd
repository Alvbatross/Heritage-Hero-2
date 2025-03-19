@tool
class_name InventorySystem
extends Node3D

@export_category("Editor Settings")
@export var reinitialize_inventory: bool

@export_category("Inventory Settings")
@export_range(1,5) var row_count : int = 3
@export_range(1,5) var column_count : int = 2

@export_category("Spacing Options")
@export_range(0,2) var row_spacing : float = 0.3
@export_range(0,2) var column_spacing : float = 0.3

@export_category("Slot Options")
@export var update_slot_radius: bool
@export_range(0,2) var slot_size : float = 0.1

@export_category("Debug")
@export var inventory_dictionary : Dictionary


# REMOVE THIS SECTION LATER
@export var test_item : Node3D
var lolbool : bool
@export var test_dict: Dictionary = { 0: [["adasda", null, "res://src/ois-objects/ois_screw_driver.tscn"], ["adasda", null, "res://src/ois-objects/ois_flashlight_radio.tscn"], ["adasda", null, null]], 1: [["adasda", null, null], ["adasda", null, null], ["adasda", null, null]]}


var space_count_row = 0
var space_count_column = 0
var mesh_shape := SphereMesh.new()

var load_inventory_from_save : bool



# Place all common Inventory System Stuff in here. Common to shelf type and Wrist type inventories. 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_child_count() == 0:
		initialize_inv()
	
	# Make sure signals are connected.
	for inventory_slot in get_children():
		inventory_slot.current_object_in_slot.connect(update_slot_item)
		
		# Ensure the slots in runtime are the ones inside the inventory dictionary EVERY TIME.
		inventory_dictionary[int(inventory_slot.name.split("_")[1])][int(inventory_slot.name.split("_")[2])][0] = inventory_slot
	
	# REMOVE THIS SECTION LATER
	lolbool = true
	

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint() and reinitialize_inventory:
		initialize_inv()
		reinitialize_inventory = false
	
	if Engine.is_editor_hint():
		_update_inventory_system()
	
	# REMOVE THIS SECTION LATER
	if not Engine.is_editor_hint():
		if lolbool:
			print("[AVRE - Inventory] [DEBUG] Currently autoloads the test dictionary for testing purposes. REMOVE THIS CODE LATER.")
			import_save_data(test_dict)
			lolbool = false
		
	


func initialize_inv() -> void:
	print("[AVRE - Inventory] Initializing inventory...")
	
	clear_all_children()
	inventory_dictionary.clear()
	space_count_row = row_count
	space_count_column = column_count
		
	for x in range(space_count_row):
		var row_array = []
		for y in range(space_count_column):
			var inventory_slot := InventorySlot.new()
			
			inventory_slot.name = "Slot_"+str(x)+"_"+str(y)
			inventory_slot.position = Vector3(column_spacing * y, x * row_spacing, 0)
			inventory_slot.snap_zone_radius = slot_size
			inventory_slot.update_slot_settings = true
			
			add_child(inventory_slot,true)
			if y < column_count and x < row_count:
				inventory_slot.owner = get_tree().edited_scene_root
			
			var content = null
			var file_path = null
			row_array.append([inventory_slot,content,file_path])

		inventory_dictionary[x] = row_array

	
func _update_inventory_system() -> void:
	if Engine.is_editor_hint() and has_node("Slot_0_0"):
		for row_slots in inventory_dictionary.keys():
			for column_slots in range(inventory_dictionary[row_slots].size()):
				if is_instance_valid(inventory_dictionary[row_slots][column_slots][0]):
					inventory_dictionary[row_slots][column_slots][0].position = Vector3(column_spacing * column_slots, int(row_slots) * row_spacing, 0)
		if update_slot_radius:
			for slot in get_children():
				slot.snap_zone_radius = slot_size
				slot.update_slot_settings = true
			update_slot_radius = false
					
				
func clear_all_children() -> void:
	if get_child_count() > 0:
		for child in get_children():
			self.remove_child(child)
			child.queue_free()

func update_slot_item(what, row, col) -> void:
	inventory_dictionary[row][col][1] = what
	if inventory_dictionary[row][col][1] != null:
		inventory_dictionary[row][col][2] = inventory_dictionary[row][col][1].get_scene_file_path()
		print("[AVRE - Inventory] "+inventory_dictionary[row][col][1].name+" path: "+inventory_dictionary[row][col][1].get_scene_file_path())
	else:
		print("[AVRE - Inventory] No object in slot row "+str(row)+" column "+str(col)+".")

func export_save_data() -> Dictionary:
	print("[AVRE - Inventory] Saving data..")
	return inventory_dictionary

func import_save_data(data : Dictionary) -> void:
	print("[AVRE - Inventory] Loading save data..")
	for row_slots in inventory_dictionary.keys():
			for column_slots in range(inventory_dictionary[row_slots].size()):
				
				if data[row_slots][column_slots][2] != null:
					inventory_dictionary[row_slots][column_slots][2] = data[row_slots][column_slots][2]
					var loaded_item = load(inventory_dictionary[row_slots][column_slots][2]).instantiate()
					
					# Making sure if the object has the InventoryItem script.
					if is_instance_valid(loaded_item.get_node("InventoryItem")):
						# If the item is supposed to be unique, find it inside the scene.
						
						if loaded_item.get_node("InventoryItem").unique:
							print("im unique")
							var loaded_item_name = loaded_item.name
							if is_instance_valid(get_parent().find_child(loaded_item_name)):
								print("the item is unique AND in the scene")
								inventory_dictionary[row_slots][column_slots][0]._pick_up_object(get_parent().find_child(loaded_item_name))
								inventory_dictionary[row_slots][column_slots][1] = inventory_dictionary[row_slots][column_slots][0].current_object
							else:
								print("the item is unique but not in the scene")
								get_parent().add_child(loaded_item)
								inventory_dictionary[row_slots][column_slots][0]._pick_up_object(loaded_item)
								inventory_dictionary[row_slots][column_slots][1] = inventory_dictionary[row_slots][column_slots][0].current_object
						else:
							print("not unique and may or may not be in the scene")
							get_parent().add_child(loaded_item)
							inventory_dictionary[row_slots][column_slots][0]._pick_up_object(loaded_item)
							inventory_dictionary[row_slots][column_slots][1] = inventory_dictionary[row_slots][column_slots][0].current_object
					# If it doesn't have it, just put the item as is.
					else:
						print("no inventory item script in this item")
						get_parent().add_child(loaded_item)
						inventory_dictionary[row_slots][column_slots][0]._pick_up_object(loaded_item)
						inventory_dictionary[row_slots][column_slots][1] = inventory_dictionary[row_slots][column_slots][0].current_object
	
	
