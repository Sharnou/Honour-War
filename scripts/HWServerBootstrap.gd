extends SceneTree

## Headless production server entrypoint for Honour War.
## Run with Godot 4.7.2:
##   --headless --path . --script res://scripts/HWServerBootstrap.gd
## Optional:
##   --server-port=24567
##
## The game autoloads HWOnlineAuthorityRuntime automatically. This script only
## starts/stops the authoritative ENet session and keeps the process alive;
## gameplay authority remains in the existing server-authoritative services.

const DEFAULT_PORT:int = 24567
var authority:Node
var port:int = DEFAULT_PORT
var started:bool = false
var heartbeat_timer:float = 0.0

func _initialize() -> void:
    port = _parse_port()
    call_deferred("_start")

func _process(delta:float) -> void:
    if not started:
        return
    heartbeat_timer += delta
    if heartbeat_timer >= 10.0:
        heartbeat_timer = 0.0
        if authority != null and is_instance_valid(authority):
            var snapshot:Dictionary = authority.get_session_snapshot()
            print("HONOUR_WAR_SERVER heartbeat: ", JSON.stringify(snapshot))
        else:
            quit(1)

func _start() -> void:
    authority = get_root().get_node_or_null("HWOnlineAuthorityRuntime")
    if authority == null:
        push_error("HWOnlineAuthorityRuntime autoload is unavailable.")
        quit(1)
        return
    if not authority.has_method("start_server"):
        push_error("HWOnlineAuthorityRuntime.start_server() is unavailable.")
        quit(1)
        return
    if not authority.start_server(port):
        push_error("Honour War dedicated server failed to bind port %d." % port)
        quit(1)
        return
    started = true
    print("HONOUR_WAR_SERVER started: port=%d protocol=%d max_players=%d" % [
        port,
        int(authority.PROTOCOL_VERSION),
        int(authority.MAX_PLAYERS)
    ])

func _notification(what:int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
        if authority != null and is_instance_valid(authority):
            authority.stop_session()

func _parse_port() -> int:
    for arg in OS.get_cmdline_user_args():
        if str(arg).begins_with("--server-port="):
            var raw:String = str(arg).substr("--server-port=".length())
            if raw.is_valid_int():
                var value:int = int(raw)
                if value >= 1024 and value <= 65535:
                    return value
    return DEFAULT_PORT
