extends SceneTree

## Honour War dedicated authoritative server entrypoint.
## Run with:
##   Godot_v4.7.2-stable --headless --path . --script res://scripts/HWServerMain.gd -- --port 24567
## The server owns accepted gameplay events through HWOnlineAuthorityRuntime.

const AUTHORITY_SCRIPT = preload("res://scripts/HWOnlineAuthorityRuntime.gd")

var authority:Node
var port:int = 24567

func _initialize() -> void:
    port = _read_port()
    authority = AUTHORITY_SCRIPT.new()
    root.add_child(authority)
    if not authority.start_server(port):
        push_error("Honour War dedicated server failed to bind port %d" % port)
        quit(1)
        return
    print("HONOUR WAR SERVER READY: port=%d protocol=%d max_players=%d" % [
        port,
        int(authority.PROTOCOL_VERSION),
        int(authority.MAX_PLAYERS)
    ])

func _read_port() -> int:
    var args:PackedStringArray = OS.get_cmdline_user_args()
    for index in range(args.size()):
        if args[index] == "--port" and index + 1 < args.size():
            var candidate:int = int(args[index + 1])
            if candidate >= 1024 and candidate <= 65535:
                return candidate
    return 24567
