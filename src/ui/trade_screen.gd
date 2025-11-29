extends Control

var current_npc_id = ""
var player_id = "player_1"

# Staging
var player_offer_items = []
var npc_offer_items = []

@onready var player_list = $Panel/HBoxContainer/PlayerSide/ScrollContainer/VBoxContainer
@onready var npc_list = $Panel/HBoxContainer/NPCSide/ScrollContainer/VBoxContainer

@onready var player_offer_list = $Panel/HBoxContainer/Middle/PlayerOfferScroll/PlayerOfferList
@onready var npc_offer_list = $Panel/HBoxContainer/Middle/NPCOfferScroll/NPCOfferList

@onready var trade_button = $Panel/HBoxContainer/Middle/TradeButton

func _ready():
	# Initial Setup
	pass

func open_trade(npc_id):
	current_npc_id = npc_id
	player_offer_items.clear()
	npc_offer_items.clear()
	visible = true
	update_display()

func update_display():
	# Main Inventories
	_populate_list(player_list, DatabaseManager.inventory.get_by_owner(player_id), "player_inv")
	_populate_list(npc_list, DatabaseManager.inventory.get_by_owner(current_npc_id), "npc_inv")
	
	# Offer Lists
	_populate_offer_list(player_offer_list, player_offer_items, "player_offer")
	_populate_offer_list(npc_offer_list, npc_offer_items, "npc_offer")
	
	# Update labels
	$Panel/HBoxContainer/Middle/PlayerOfferLabel.text = "Player Offer: " + str(player_offer_items.size())
	$Panel/HBoxContainer/Middle/NPCOfferLabel.text = "NPC Offer: " + str(npc_offer_items.size())

func _populate_list(container, items, source):
	for child in container.get_children():
		child.queue_free()
		
	for item in items:
		if _is_in_offer(item): continue
		
		var btn = Button.new()
		btn.text = item["name"]
		btn.pressed.connect(_on_item_clicked.bind(item, source))
		container.add_child(btn)

func _populate_offer_list(container, items, source):
	for child in container.get_children():
		child.queue_free()
		
	for item in items:
		var btn = Button.new()
		btn.text = item["name"]
		# Clicking an offer item should remove it from the offer
		btn.pressed.connect(_on_item_clicked.bind(item, source))
		container.add_child(btn)

func _is_in_offer(item):
	return (item in player_offer_items) or (item in npc_offer_items)

func _on_item_clicked(item, source):
	if source == "player_inv":
		player_offer_items.append(item)
	elif source == "npc_inv":
		npc_offer_items.append(item)
	elif source == "player_offer":
		player_offer_items.erase(item)
	elif source == "npc_offer":
		npc_offer_items.erase(item)
		
	update_display()

func _on_trade_button_pressed():
	DatabaseManager.trade.execute_trade(player_offer_items, current_npc_id, npc_offer_items, player_id)
	
	player_offer_items.clear()
	npc_offer_items.clear()
	update_display()

func _on_close_pressed():
	visible = false
