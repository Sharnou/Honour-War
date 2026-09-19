extends CanvasLayer

const HWAccountDatabaseClass = preload("res://scripts/HWAccountDatabase.gd")

## Optional online account/login layer. Offline play remains the default path.
## Fast Register uses username + password only; no email or verification step is required.
## Login accepts the exact username or a unique base name when it has one _M/_F account.
## Automatic Login stores only a revocable server-issued session token locally, never the password.
## Authentication is sent only after ENet reaches CONNECTION_CONNECTED.
## The existing LegacyGame hero is replaced only after a verified server response.

const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"
const AUTO_LOGIN_PATH:String = "/root/HWAutoLoginService"
const AUTO_LOGIN_STORE_PATH:String = "user://honour_war_auto_login.cfg"

var panel:Panel
var address_edit:LineEdit
var port_edit:LineEdit
var username_edit:LineEdit
var password_edit:LineEdit
var remember_login_check:CheckBox
var status_label:Label
var identity_hint:Label
var open_button:Button
var pending_auth_action:String = ""
var pending_manual_remember:bool = false
var automatic_login_mode:bool = false
var local_database:HWAccountDatabaseClass
var local_mode:bool = true
var saved_auto_username:String = ""
var saved_auto_token:String = ""

func _ready() -> void:
    layer = 220
    local_database = HWAccountDatabaseClass.new()
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
            _status("Fast registration sent. Creating account...")
        elif action == "auto_login":
            var auto_login:Node = get_node_or_null(AUTO_LOGIN_PATH)
            if auto_login != null:
                auto_login.request_auto_login(saved_auto_username,saved_auto_token)
                _status("Automatic Login: authenticating saved session...")
    elif state == MultiplayerPeer.CONNECTION_DISCONNECTED:
        pending_auth_action = ""
        if automatic_login_mode:
            automatic_login_mode = false
            _status("Automatic Login could not connect to the saved server.")
        else:
            _status("Connection failed or was disconnected.")

func _build() -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority != null:
        if not authority.authentication_succeeded.is_connected(_on_authentication_succeeded):
            authority.authentication_succeeded.connect(_on_authentication_succeeded)
        if not authority.authentication_failed.is_connected(_on_authentication_failed):
            authority.authentication_failed.connect(_on_authentication_failed)
        if not authority.registration_succeeded.is_connected(_on_registration_succeeded):
            authority.registration_succeeded.connect(_on_registration_succeeded)
    var auto_login:Node = get_node_or_null(AUTO_LOGIN_PATH)
    if auto_login != null and not auto_login.auto_login_token_issued.is_connected(_on_auto_login_token_issued):
        auto_login.auto_login_token_issued.connect(_on_auto_login_token_issued)
    open_button = Button.new()
    open_button.name = "OnlineButton"
    open_button.text = "ONLINE"
    open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    open_button.position = Vector2(-190,18)
    open_button.size = Vector2(172,42)
    open_button.pressed.connect(_toggle_panel)
    add_child(open_button)
    _build_panel()
    _load_auto_login_state()
    call_deferred("_attempt_saved_auto_login")

func _build_panel() -> void:
    panel = Panel.new()
    panel.name = "OnlineLoginPanel"
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-300,-260)
    panel.size = Vector2(600,520)
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
    _field("Username",Vector2(22,150),"Sharnou_M or Sharnou_F")
    username_edit = panel.get_node("Username") as LineEdit
    username_edit.text_changed.connect(_on_username_changed)
    _field("Password",Vector2(22,230),"6+ characters")
    password_edit = panel.get_node("Password") as LineEdit
    password_edit.secret = true

    identity_hint = Label.new()
    identity_hint.text = "Fast Register: username + password only • no email verification"
    identity_hint.position = Vector2(300,150)
    identity_hint.size = Vector2(255,82)
    identity_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(identity_hint)
    _on_username_changed(username_edit.text)

    remember_login_check = CheckBox.new()
    remember_login_check.name = "AutomaticLogin"
    remember_login_check.text = "Automatic Login next time (save this device)"
    remember_login_check.position = Vector2(22,286)
    remember_login_check.size = Vector2(520,32)
    remember_login_check.tooltip_text = "Stores a revocable server session token, not your password."
    remember_login_check.toggled.connect(_on_automatic_login_toggled)
    panel.add_child(remember_login_check)

    var local_label:Label=Label.new()
    local_label.text="LOCAL ACCOUNT MODE: works without a server • saves hero progression on this PC"
    local_label.position=Vector2(22,318)
    local_label.size=Vector2(540,28)
    local_label.add_theme_font_size_override("font_size",11)
    local_label.add_theme_color_override("font_color",Color("#8ed8a6"))
    panel.add_child(local_label)

    var local_login:Button=Button.new()
    local_login.text="LOCAL LOGIN"
    local_login.position=Vector2(22,350)
    local_login.size=Vector2(165,44)
    local_login.pressed.connect(_local_login)
    panel.add_child(local_login)

    var local_register:Button=Button.new()
    local_register.text="LOCAL REGISTER"
    local_register.position=Vector2(202,350)
    local_register.size=Vector2(165,44)
    local_register.pressed.connect(_local_register)
    panel.add_child(local_register)

    var connect_button:Button = Button.new()
    connect_button.text = "CONNECT"
    connect_button.position = Vector2(382,350)
    connect_button.size = Vector2(165,44)
    connect_button.pressed.connect(_connect)
    panel.add_child(connect_button)

    var login_button:Button = Button.new()
    login_button.text = "LOGIN"
    login_button.position = Vector2(22,402)
    login_button.size = Vector2(165,44)
    login_button.pressed.connect(_login)
    panel.add_child(login_button)

    var register_button:Button = Button.new()
    register_button.text = "REGISTER"
    register_button.position = Vector2(202,402)
    register_button.size = Vector2(165,44)
    register_button.pressed.connect(_register)
    panel.add_child(register_button)

    status_label = Label.new()
    status_label.text = "Offline mode remains active until you connect. Automatic Login can restore your session next time."
    status_label.position = Vector2(22,454)
    status_label.size = Vector2(540,54)
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

func _local_register()->void:
    if local_database==null: local_database=HWAccountDatabaseClass.new()
    var username:String=username_edit.text.strip_edges()
    var password:String=password_edit.text
    if not HWAccountDatabaseClass.validate_username(username):
        _status("Local registration: username must be 3–24 letters/numbers/_/- characters.")
        return
    if password.length()<6:
        _status("Local registration: password must contain at least 6 characters.")
        return
    var salt:String=(username+":"+str(Time.get_ticks_usec())).sha256_text().substr(0,32)
    var verifier:String=HWAccountDatabaseClass.password_verifier(password,salt)
    var legacy:=get_tree().current_scene.get_node_or_null("LegacyGame")
    var player:Dictionary={}
    if legacy!=null and legacy.get("hero") is Dictionary:
        player=(legacy.get("hero") as Dictionary).duplicate(true)
    if local_database.create_account(username,salt,verifier,player):
        _status("Local registration successful. You can now use LOCAL LOGIN.")
    else:
        _status("Local registration failed: account may already exist.")

func _local_login()->void:
    if local_database==null: local_database=HWAccountDatabaseClass.new()
    var username:String=username_edit.text.strip_edges()
    var password:String=password_edit.text
    var record:Dictionary=local_database.get_auth_record(username)
    if record.is_empty():
        _status("Local login failed: account not found.")
        return
    var verifier:String=HWAccountDatabaseClass.password_verifier(password,str(record.get("salt","")))
    if verifier!=str(record.get("verifier","")):
        _status("Local login failed: incorrect password.")
        return
    var legacy:=get_tree().current_scene.get_node_or_null("LegacyGame")
    if legacy!=null:
        var restored:Dictionary=local_database.load_player(username,legacy.get("hero") if legacy.get("hero") is Dictionary else {})
        if not restored.is_empty():
            legacy.set("hero",restored)
            if legacy.has_method("ensure_pet_state"): legacy.call("ensure_pet_state")
            if legacy.has_method("update_pet_visual"): legacy.call("update_pet_visual")
            if legacy.has_method("update_ui"): legacy.call("update_ui")
    local_database.mark_login(username)
    _status("Local login successful. Hero profile restored.")

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
    pending_manual_remember = remember_login_check.button_pressed
    automatic_login_mode = false
    _status("Connecting before login...")

func _register() -> void:
    if not _prepare_auth("register"):
        return
    automatic_login_mode = false
    _status("Connecting before fast registration...")

func _prepare_auth(action:String) -> bool:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        _status("Online runtime is unavailable.")
        return false
    var username:String = username_edit.text.strip_edges()
    var password:String = password_edit.text
    if not HWAccountDatabaseClass.validate_username(username):
        _status("Username: 3-24 characters using A-Z, 0-9, _ or -. For gender, finish with _M or _F.")
        return false
    if password.length() < 6:
        _status("Enter a password of at least 6 characters. Example: 123123")
        return false
    var peer:Variant = authority.multiplayer.multiplayer_peer
    if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
        var address:String = address_edit.text.strip_edges()
        var port:int = clampi(int(port_edit.text),1024,65535)
        if address.is_empty():
            _status("Enter a server address.")
            return false
        if not authority.connect_client(address,port):
            _status("Connection could not be started.")
            return false
    pending_auth_action = action
    return true

func _on_username_changed(value:String) -> void:
    if identity_hint == null:
        return
    var normalized:String = value.strip_edges().to_lower()
    if normalized.ends_with("_m"):
        identity_hint.text = "Gender: Male\nFast Register: username + password only\nNo email verification"
    elif normalized.ends_with("_f"):
        identity_hint.text = "Gender: Female\nFast Register: username + password only\nNo email verification"
    else:
        identity_hint.text = "Gender: not specified\nUse _M for Male or _F for Female\nNo email verification"

func _on_automatic_login_toggled(enabled:bool) -> void:
    if not enabled:
        _clear_auto_login_state()
        _status("Automatic Login disabled. This device will not auto-login next time.")
    elif not saved_auto_token.is_empty():
        _status("Automatic Login enabled for %s." % saved_auto_username)

func _load_auto_login_state() -> void:
    var config:ConfigFile = ConfigFile.new()
    if config.load(AUTO_LOGIN_STORE_PATH) != OK:
        return
    var enabled:bool = bool(config.get_value("auto_login","enabled",false))
    saved_auto_username = str(config.get_value("auto_login","username",""))
    saved_auto_token = str(config.get_value("auto_login","token",""))
    var saved_address:String = str(config.get_value("server","address","127.0.0.1"))
    var saved_port:int = int(config.get_value("server","port",24567))
    if not saved_address.is_empty():
        address_edit.text = saved_address
    port_edit.text = str(clampi(saved_port,1024,65535))
    username_edit.text = saved_auto_username
    remember_login_check.set_pressed_no_signal(enabled and not saved_auto_username.is_empty() and not saved_auto_token.is_empty())

func _save_auto_login_state(username:String,token:String) -> void:
    var config:ConfigFile = ConfigFile.new()
    config.set_value("auto_login","enabled",true)
    config.set_value("auto_login","username",username.strip_edges().to_lower())
    config.set_value("auto_login","token",token)
    config.set_value("server","address",address_edit.text.strip_edges())
    config.set_value("server","port",clampi(int(port_edit.text),1024,65535))
    if config.save(AUTO_LOGIN_STORE_PATH) == OK:
        saved_auto_username = username.strip_edges().to_lower()
        saved_auto_token = token

func _clear_auto_login_state() -> void:
    saved_auto_username = ""
    saved_auto_token = ""
    var config:ConfigFile = ConfigFile.new()
    config.set_value("auto_login","enabled",false)
    config.set_value("auto_login","username","")
    config.set_value("auto_login","token","")
    config.set_value("server","address",address_edit.text.strip_edges() if address_edit != null else "127.0.0.1")
    config.set_value("server","port",clampi(int(port_edit.text),1024,65535) if port_edit != null else 24567)
    config.save(AUTO_LOGIN_STORE_PATH)

func _attempt_saved_auto_login() -> void:
    if remember_login_check == null or not remember_login_check.button_pressed:
        return
    if saved_auto_username.is_empty() or saved_auto_token.is_empty():
        return
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        return
    var address:String = address_edit.text.strip_edges()
    var port:int = clampi(int(port_edit.text),1024,65535)
    if address.is_empty():
        return
    var peer:Variant = authority.multiplayer.multiplayer_peer
    if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
        if not authority.connect_client(address,port):
            return
    automatic_login_mode = true
    pending_auth_action = "auto_login"
    _status("Automatic Login enabled. Connecting as %s..." % saved_auto_username)

func _on_registration_succeeded(_peer_id:int,username:String,gender:String) -> void:
    pending_auth_action = ""
    automatic_login_mode = false
    pending_manual_remember = false
    if password_edit != null:
        password_edit.clear()
    _status("REGISTERED %s (%s). No email verification required. Press LOGIN and enter the password." % [username,gender])

func _on_authentication_succeeded(_peer_id:int,username:String,player:Dictionary) -> void:
    var scene:Node = get_tree().current_scene
    var legacy:Node = scene.get_node_or_null("LegacyGame") if scene != null else null
    if legacy != null and not player.is_empty():
        legacy.set("hero",player.duplicate(true))
        if legacy.has_method("save_game"):
            legacy.call("save_game")
    var auto_login:Node = get_node_or_null(AUTO_LOGIN_PATH)
    if pending_manual_remember and not automatic_login_mode and auto_login != null:
        auto_login.request_issue_token()
        _status("Authenticated as %s. Saving Automatic Login for this device..." % username)
    elif automatic_login_mode:
        remember_login_check.set_pressed_no_signal(true)
        _status("Automatic Login successful: %s. Persistent hero restored." % username)
    else:
        _clear_auto_login_state()
        remember_login_check.set_pressed_no_signal(false)
        _status("Authenticated as %s. Persistent hero restored from server." % username)
    pending_auth_action = ""
    pending_manual_remember = false
    automatic_login_mode = false
    if password_edit != null:
        password_edit.clear()

func _on_auto_login_token_issued(_peer_id:int,username:String,token:String) -> void:
    if token.is_empty() or username.is_empty():
        return
    if remember_login_check == null or remember_login_check.button_pressed or pending_manual_remember or automatic_login_mode:
        _save_auto_login_state(username,token)
        if remember_login_check != null:
            remember_login_check.set_pressed_no_signal(true)
        if not automatic_login_mode and status_label != null and pending_manual_remember:
            _status("Automatic Login enabled. Next time the game can login without username or password.")

func _on_authentication_failed(_peer_id:int,username:String,reason:String) -> void:
    var was_auto:bool = automatic_login_mode
    pending_auth_action = ""
    pending_manual_remember = false
    automatic_login_mode = false
    if was_auto and reason == "auto_login_invalid":
        _clear_auto_login_state()
        if remember_login_check != null:
            remember_login_check.set_pressed_no_signal(false)
        _status("Saved Automatic Login session expired or was revoked. Enter username and password to login again.")
    else:
        _status("Authentication failed for %s: %s" % [username,reason])

func _status(text:String) -> void:
    if status_label != null:
        status_label.text = text
