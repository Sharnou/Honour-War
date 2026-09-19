extends Node

## Final HD visual ownership pass.
## One authoritative authored GLB actor per hero/pet/monster is kept visible.
## Competing legacy visual generators and environment/light stacks are removed
## so the production presentation cannot duplicate or black out the world.

const GameDataClass = preload("res://scripts/GameData.gd")
const GENERATED_ROOT:String = "res://assets/3d/generated"
