extends Node

## Rental-only AI hero. Never available from Create New Character.
const SkillSystemClass = preload("res://scripts/SkillSystem.gd")
const PetSystemClass = preload("res://scripts/PetSystem.gd")
const RENT_PRICE_ZENY:int = 1000000
const SS_CLASS_NAME:String = "Super Champion (Rental Only)"
const SS_LEVEL:int = 0
const SS_MAX_LEVEL:int = 250
const SS_DEFAULT_SKILL:String = "Champion's Asura"
const SS_RENT_NPC_NAME:String = "Rent"
const COLLECTION_ITEM_LIMIT:int = 50
const COLLECTION_CARD_LIMIT:int = 20
