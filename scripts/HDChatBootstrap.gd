class_name HDChatBootstrap
extends CanvasLayer

const ChatService = preload("res://scripts/ChatService.gd")

@export var chat_panel_scene: PackedScene
@export var toggle_key := KEY_ENTER
var chat_service:Node
var chat_dock:Control

func _ready() -> void:
    layer = 20
    chat_service = ChatService.new()
    chat_service.name = "ChatService"
    add_child(chat_service)
    if chat_panel_scene:
        chat_dock = chat_panel_scene.instantiate()
        add_child(chat_dock)
        chat_dock.set_meta("sender_id", "local")
        chat_dock.set_meta("sender_name", "Hero")
        chat_dock.set("chat_service", chat_service)
        chat_dock.visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == toggle_key:
        if chat_dock and not chat_dock.visible:
            chat_dock.visible = true
            var input_box := chat_dock.get_node_or_null("Margin/VBox/InputBox") as LineEdit
            if input_box:
                input_box.grab_focus()
                get_viewport().set_input_as_handled()
        elif chat_dock:
            toggle_chat()
            get_viewport().set_input_as_handled()

func toggle_chat() -> void:
    if chat_dock:
        chat_dock.visible = not chat_dock.visible
        if chat_dock.visible:
            var input_box := chat_dock.get_node_or_null("Margin/VBox/InputBox") as LineEdit
            if input_box:
                input_box.grab_focus()
