class_name ChatService
extends Node

signal message_received(message)
signal system_message(text)

const CHANNELS := ["General", "Party", "Guild", "Whisper", "System", "Combat", "Trade"]
const MAX_MESSAGE_LENGTH := 240
const MIN_SEND_INTERVAL := 0.35

var history: Array[Dictionary] = []
var muted_players: Dictionary = {}
var blocked_players: Dictionary = {}
var _last_send_time := -INF
var _sequence := 0

func submit_message(sender_id: String, sender_name: String, channel: String, text: String, recipient_id: String = "") -> bool:
    if not CHANNELS.has(channel):
        system_message.emit("Unknown chat channel.")
        return false
    if Time.get_ticks_msec() / 1000.0 - _last_send_time < MIN_SEND_INTERVAL:
        system_message.emit("Please wait before sending another message.")
        return false
    var clean_text := text.strip_edges()
    if clean_text.is_empty() or clean_text.length() > MAX_MESSAGE_LENGTH:
        system_message.emit("Message must contain 1–%d characters." % MAX_MESSAGE_LENGTH)
        return false
    if channel == "Whisper" and recipient_id.is_empty():
        system_message.emit("A whisper requires a recipient.")
        return false
    _last_send_time = Time.get_ticks_msec() / 1000.0
    _sequence += 1
    var message := {
        "id": _sequence,
        "sender_id": sender_id,
        "sender_name": sender_name,
        "channel": channel,
        "recipient_id": recipient_id,
        "text": clean_text,
        "timestamp": Time.get_datetime_string_from_system()
    }
    history.append(message)
    if history.size() > 300:
        history.pop_front()
    message_received.emit(message)
    return true

func mute_player(player_id: String) -> void:
    muted_players[player_id] = true

func unmute_player(player_id: String) -> void:
    muted_players.erase(player_id)

func block_player(player_id: String) -> void:
    blocked_players[player_id] = true
    muted_players[player_id] = true

func is_hidden(message: Dictionary) -> bool:
    return muted_players.has(message.get("sender_id", "")) or blocked_players.has(message.get("sender_id", ""))

func clear_history() -> void:
    history.clear()
