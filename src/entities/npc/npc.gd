extends CharacterBody2D

@export var npc_id = "npc_merchant_1"

func _ready():
	# In a real game, we'd load appearance from DB based on npc_id
	pass

func interact():
	print("Interacting with NPC: ", npc_id)
	# Emit a signal or call a global event to open the interaction menu
	# For now, we can use a group or direct call if we had a reference.
	# Better approach: The Player emits "interaction_started(target)" signal.
	return self

