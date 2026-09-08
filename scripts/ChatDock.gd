class_name ChatDock
extends Control

const ChatService = preload("res://scripts/ChatService.gd")

@export var chat_service:Node
@onready var channel_tabs: OptionButton = get_node_or_null("Margin/VBox/ChannelTabs")
@onready var message_list: RichTextLabel = get_node_or_null("Margin/VBox/MessageList")
@onready var input_box: LineEdit = get_node_or_null("Margin/VBox/InputBox")

var active_channel := "General"

func _ready() -> void:
    if chat_service:
        if chat_service.has_signal("message_received"):
            chat_service.message_received.connect(_on_message_received)
        if chat_service.has_signal("system_message"):
            chat_service.system_message.connect(_on_system_message)
    if channel_tabs:
        for channel in ChatService.CHANNELS:
            channel_tabs.add_item(channel)
        channel_tabs.item_selected.connect(_on_channel_selected)
    if input_box:
        input_box.text_submitted.connect(_on_text_submitted)
    if message_list:
        message_list.bbcode_enabled = true
        message_list.scroll_following = true

func _on_channel_selected(index: int) -> void:
    if channel_tabs and index >= 0 and index < ChatService.CHANNELS.size():
        active_channel = ChatService.CHANNELS[index]

func _on_text_submitted(text: String) -> void:
    if not chat_service:
        return
    var sender_id := str(get_meta("sender_id", "local"))
    var sender_name := str(get_meta("sender_name", "Hero"))
    if text.begins_with("/w "):
        var parts := text.split(" ", false, 2)
        if parts.size() < 3:
            _on_system_message("Usage: /w player message")
            return
        chat_service.submit_message(sender_id, sender_name, "Whisper", parts[2], parts[1])
    else:
        chat_service.submit_message(sender_id, sender_name, active_channel, text)
    if input_box:
        input_box.clear()

func _on_message_received(message: Dictionary) -> void:
    if chat_service and chat_service.has_method("is_hidden") and chat_service.is_hidden(message):
        return
    if message_list:
        message_list.append_text("[color=#9aa8c7][" + str(message.get("channel", "General")) + "][/color] " + str(message.get("sender_name", "Unknown")) + ": " + str(message.get("text", "")) + "\n")

func _on_system_message(text: String) -> void:
    if message_list:
        message_list.append_text("[color=#e5c07b][System][/color] " + text + "\n")
