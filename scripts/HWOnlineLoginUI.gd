extends CanvasLayer

## Optional online account/login layer. Offline play remains the default path.
## Authentication is sent only after ENet reaches CONNECTION_CONNECTED.
## The existing LegacyGame hero is replaced only after a verified server response.

const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"

var panel:Panel
var address_edit:LineEdit
var port_edit:LineEdit
var username_edit:LineEdit
var password_edit:LineEdit
var status_label:Label
var open_button:Button
var pending_auth_action:String = ""

func _ready() -> void:
    layer = 220
    if DisplayServer.get_name() == "headless":
        return
    call_deferred("_build")

func _process(_delta:float) -> void:
    if pending_auth_action.is_empty():
        return
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        return
    var peer:Variant = authority.multiplayer.multiplayer_peer
    if peer == null:
        return
    var state:int = peer.get_connection_status()
    if state == MultiplayerPeer.CONNECTION_CONNECTED:
        var action:String = pending_auth_action
        pending_auth_action = ""
        if action == "login":
            authority.request_login(username_edit.text,password_edit.text)
            _status("Login request sent. Waiting for server challenge...")
        elif action == "register":
            authority.request_register(username_edit.text,password_edit.text)
            _status("Registration request sent...")
    elif state == MultiplayerPeer.CONNECTION_DISCONNECTED:
        pending_auth_action = ""
        _status("Connection failed or was disconnected.")

func _build() -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority != null:
        if not authority.authentication_succeeded.is_connected(_on_authentication_succeeded):
            authority.authentication_succeeded.connect(_on_authentication_succeeded)
        if not authority.authentication_failed.is_connected(_on_authentication_failed):
            authority.authentication_failed.connect(_on_authentication_failed)
    open_button = Button.new()
    open_button.name = "OnlineButton"
    open_button.text = "ONLINE"
    open_button.position = Vector2(1710,18)
    open_button.size = Vector2(180,42)
    open_button.pressed.connect(_toggle_panel)
    add_child(open_button)
    _build_panel()

func _build_panel() -> void:
    panel = Panel.new()
    panel.name = "OnlineLoginPanel"
    panel.position = Vector2(1300,76)
    panel.size = Vector2(590,470)
    panel.visible = false
    add_child(panel)

    var title:Label = Label.new()
    title.text = "HONOUR WAR • ONLINE ACCOUNT"
    title.position = Vector2(22,18)
    title.add_theme_font_size_override("font_size",22)
    panel.add_child(title)

    _field("Server Address",Vector2(22,70),"127.0.0.1")
    address_edit = panel.get_node("ServerAddress") as LineEdit
    _field("Port",Vector2(300,70),"24567")
    port_edit = panel.get_node("ServerPort") as LineEdit
    _field("Username",Vector2(22,150),"your_account")
    username_edit = panel.get_node("Username") as LineEdit
    _field("Password",Vector2(22,230),"8+ characters")
    password_edit = panel.get_node("Password") as LineEdit
    password_edit.secret = true

    var connect_button:Button = Button.new()
    connect_button.text = "CONNECT"
    connect_button.position = Vector2(22,318)
    connect_button.size = Vector2(165,44)
    connect_button.pressed.connect(_connect)
    panel.add_child(connect_button)

    var login_button:Button = Button.new()
    login_button.text = "LOGIN"
    login_button.position = Vector2(202,318)
    login_button.size = Vector2(165,44)
    login_button.pressed.connect(_login)
    panel.add_child(login_button)

    var register_button:Button = Button.new()
    register_button.text = "REGISTER"
    register_button.position = Vector2(382,318)
    register_button.size = Vector2(165,44)
    register_button.pressed.connect(_register)
    panel.add_child(register_button)

    status_label = Label.new()
    status_label.text = "Offline mode remains active until you connect."
    status_label.position = Vector2(22,382)
    status_label.size = Vector2(540,66)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(status_label)

func _field(label_text:String,pos:Vector2,placeholder:String) -> void:
    var label:Label = Label.new()
    label.text = label_text
    label.position = pos
    panel.add_child(label)
    var edit:LineEdit = LineEdit.new()
    var node_name:String
    match label_text:
        "Server Address": node_name = "ServerAddress"
        "Port": node_name = "ServerPort"
        "Username": node_name = "Username"
        _: node_name = "Password"
    edit.name = node_name
    edit.position = pos + Vector2(0,24)
    edit.size = Vector2(255,38)
    edit.placeholder_text = placeholder
    panel.add_child(edit)

func _toggle_panel() -> void:
    if panel != null:
        panel.visible = not panel.visible
        open_button.text = "CLOSE ONLINE" if panel.visible else "ONLINE"

func _connect() -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        _status("Online runtime is unavailable.")
        return
    var address:String = address_edit.text.strip_edges()
    var port:int = clampi(int(port_edit.text),1024,65535)
    if address.is_empty():
        _status("Enter a server address.")
        return
    if authority.connect_client(address,port):
        _status("Connecting to %s:%d..." % [address,port])
    else:
        _status("Connection could not be started.")

func _login() -> void:
    if not _prepare_auth("login"):
        return
    _status("Connecting before login...")

func _register() -> void:
    if not _prepare_auth("register"):
        return
    _status("Connecting before registration...")

func _prepare_auth(action:String) -> bool:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        _status("Online runtime is unavailable.")
        return false
    if username_edit.text.strip_edges().is_empty() or password_edit.text.length() < 8:
        _status("Enter a username and a password of at least 8 characters.")
        return false
    var peer:Variant = authority.multiplayer.multiplayer_peer
    if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
        var address:String = address_edit.text.strip_edges()
        var port:int = clampi(int(port_edit.text),1024,65535)
        if not authority.connect_client(address,port):
            _status("Connection could not be started.")
            return false
    pending_auth_action = action
    return true

func _on_authentication_succeeded(_peer_id:int,username:String,player:Dictionary) -> void:
    var scene:Node = get_tree().current_scene
    var legacy:Node = scene.get_node_or_null("LegacyGame") if scene != null else null
    if legacy != null and not player.is_empty():
        legacy.set("hero",player.duplicate(true))
        if legacy.has_method("save_game"):
            legacy.call("save_game")
    pending_auth_action = ""
    if password_edit != null:
        password_edit.clear()
    _status("Authenticated as %s. Persistent hero restored from server." % username)

func _on_authentication_failed(_peer_id:int,username:String,reason:String) -> void:
    pending_auth_action = ""
    _status("Authentication failed for %s: %s" % [username,reason])

func _status(text:String) -> void:
    if status_label != null:
        status_label.text = text
