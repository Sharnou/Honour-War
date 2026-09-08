class_name HDChatBootstrap
extends CanvasLayer

@export var chat_panel_scene: PackedScene
var chat_service: ChatService
var chat_dock: Control

func _ready() -> void:
    chat_service = ChatService.new()
    chat_service.name = "ChatService"
    add_child(chat_service)
    if chat_panel_scene:
        chat_dock = chat_panel_scene.instantiate()
        add_child(chat_dock)
        if chat_dock.has_method("set_meta"):
            chat_dock.set_meta("sender_id", "local")
            chat_dock.set_meta("sender_name", "Hero")
        if "chat_service" in chat_dock:
            chat_dock.chat_service = chat_service

func toggle_chat() -> void:
    if chat_dock:
        chat_dock.visible = not chat_dock.visible
