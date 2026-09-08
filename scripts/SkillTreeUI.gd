class_name SkillTreeUI
extends CanvasLayer

var game
var panel:Panel
var title:Label
var points_label:Label
var profile_label:Label
var progress_label:Label
var branch_label:Label
var branch_box:HBoxContainer
var scroll:ScrollContainer
var list:VBoxContainer
var notice:Label
var visible_state:=false

func _ready()->void:
    layer=30
    call_deferred("setup")

func setup()->void:
    game=get_parent()
    build()
    hide_tree()

func build()->void:
    panel=Panel.new()
    panel.position=Vector2(250,28)
    panel.size=Vector2(920,650)
    add_child(panel)
    var header:=VBoxContainer.new()
    header.position=Vector2(18,10)
    header.size=Vector2(884,102)
    panel.add_child(header)
    var top:=HBoxContainer.new()
    top.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    header.add_child(top)
    title=Label.new()
    title.add_theme_font_size_override("font_size",24)
    top.add_child(title)
    var spacer:=Control.new()
    spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    points_label=Label.new()
    points_label.add_theme_font_size_override("font_size",18)
    top.add_child(points_label)
    var close:=Button.new()
    close.text="CLOSE [F]"
    close.pressed.connect(hide_tree)
    top.add_child(close)
    profile_label=Label.new()
    profile_label.add_theme_font_size_override("font_size",14)
    header.add_child(profile_label)
    progress_label=Label.new()
    progress_label.add_theme_font_size_override("font_size",13)
    header.add_child(progress_label)
    branch_label=Label.new()
    branch_label.add_theme_font_size_override("font_size",13)
    header.add_child(branch_label)
    branch_box=HBoxContainer.new()
    branch_box.add_theme_constant_override("separation",6)
    branch_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    header.add_child(branch_box)
    var line:=HSeparator.new()
    line.position=Vector2(18,116)
    line.size=Vector2(884,2)
    panel.add_child(line)
    scroll=ScrollContainer.new()
    scroll.position=Vector2(18,126)
    scroll.size=Vector2(884,482)
    panel.add_child(scroll)
    list=VBoxContainer.new()
    list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation",7)
    scroll.add_child(list)
    notice=Label.new()
    notice.position=Vector2(18,616)
    notice.size=Vector2(884,28)
    notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(notice)

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F:
        toggle_tree()

func toggle_tree()->void:
    if visible_state: hide_tree()
    else: show_tree()

func show_tree()->void:
    if game==null: return
    visible_state=true
    panel.visible=true
    refresh()
    get_viewport().set_input_as_handled()

func hide_tree()->void:
    visible_state=false
    if panel: panel.visible=false

func refresh()->void:
    if game==null or list==null: return
    SkillSystem.ensure_state(game.hero)
    ClassTreeSystem.ensure_state(game.hero)
    var class_id:=str(game.hero.get("class","Warrior"))
    var summary:=ClassTreeSystem.summary(game.hero)
    var profile:Dictionary=summary["profile"]
    points_label.text="Skill Points: %d" % int(game.hero.get("skill_points",0))
    title.text="%s • %s" % [class_id,profile["title"]]
    profile_label.text="%s   •   Primary %s   •   Secondary %s" % [profile["identity"],profile["primary"],profile["secondary"]]
    progress_label.text="Skill Mastery: %d/%d ranks   •   Current Tier: %d   •   Capstone: %s (Lv.200)" % [int(summary["learned"]),int(summary["total"]),int(summary["available_tier"]),str(summary["capstone"])]
    _refresh_branches(profile,summary)
    for child in list.get_children(): child.queue_free()
    var skills:Array=SkillSystem.all_skills(class_id)
    var current_tier:=0
    for skill in skills:
        var tier:=int(skill["tier"])
        if tier!=current_tier:
            current_tier=tier
            _add_tier_header(current_tier,ClassTreeSystem.TIER_NAMES.get(current_tier,"Mastery"),int(ClassTreeSystem.TIER_LEVELS.get(current_tier,1)),ClassTreeSystem.tier_unlocked(game.hero,current_tier))
        _add_skill_row(skill)
    notice.text="F: toggle • Choose ONE specialization at Lv.25. Four paths are permanent for this class; mastery grows after specialization."

func _refresh_branches(profile:Dictionary,summary:Dictionary)->void:
    for child in branch_box.get_children(): child.queue_free()
    var current:=str(summary.get("branch",""))
    var descriptions:Dictionary=ClassTreeSystem.branch_descriptions(str(summary.get("class","Warrior")))
    branch_label.text="SPECIALIZATION: %s   •   Mastery %d/100" % [current if current!="" else "NOT SELECTED",int(summary.get("mastery",0))]
    for branch_value in profile["branches"]:
        var branch:=str(branch_value)
        var button:=Button.new()
        button.text=branch
        button.custom_minimum_size=Vector2(205,34)
        button.tooltip_text=str(descriptions.get(branch,""))
        button.disabled=current!="" or int(game.hero.get("level",1))<25
        if current==branch: button.text="✓ "+branch
        button.pressed.connect(select_branch.bind(branch))
        branch_box.add_child(button)

func select_branch(branch:String)->void:
    if ClassTreeSystem.select_branch(game.hero,branch):
        notice.text="Specialization selected: %s. This path is now permanent for this character." % branch
        game.log_message("Specialized into %s." % branch)
        game.save_game()
        game.update_ui()
        refresh()
    else:
        notice.text="Specialization unavailable: reach Lv.25 and select an unchosen path."

func _add_tier_header(tier:int,tier_name:String,required:int,unlocked:bool)->void:
    var tier_label:=Label.new()
    var state:="UNLOCKED" if unlocked else "LOCKED"
    tier_label.text="TIER %d  •  %s  •  Lv.%d  •  %s" % [tier,tier_name,required,state]
    tier_label.add_theme_font_size_override("font_size",17)
    list.add_child(tier_label)
    var divider:=HSeparator.new()
    list.add_child(divider)

func _add_skill_row(skill:Dictionary)->void:
    var row:=PanelContainer.new()
    row.custom_minimum_size=Vector2(840,76)
    list.add_child(row)
    var hb:=HBoxContainer.new()
    hb.add_theme_constant_override("separation",10)
    row.add_child(hb)
    var info:=Label.new()
    var skill_id:=str(skill["id"])
    var lvl:=SkillSystem.skill_level(game.hero,skill_id)
    var state:="LOCKED"
    if lvl>0: state="Lv.%d/%d" % [lvl,int(skill["max_level"])]
    var branch:=ClassTreeSystem.branch_for_skill(skill_id)
    var kind:=str(skill["kind"]).to_upper()
    info.text="%s  [%s]  •  %s  •  %s\n%s\nReq Lv.%d • Cost %d SP • Power %d • SP %d • CD %.1fs" % [str(skill["name"]),state,kind,branch,str(skill["description"]),int(skill["required_level"]),int(skill["cost"]),SkillSystem.power(game.hero,skill_id),SkillSystem.sp_cost(game.hero,skill_id),float(skill["cooldown"])]
    info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    hb.add_child(info)
    var button:=Button.new()
    button.text="LEARN" if lvl<=0 else "UPGRADE"
    button.custom_minimum_size=Vector2(105,50)
    button.disabled=not SkillSystem.can_learn(game.hero,skill_id)
    button.pressed.connect(learn_skill.bind(skill_id))
    hb.add_child(button)

func learn_skill(skill_id:String)->void:
    if SkillSystem.learn(game.hero,skill_id):
        notice.text="Skill upgraded successfully. Mastery and combat power updated."
        game.log_message("Learned %s Lv.%d." % [SkillSystem.skill_map(str(game.hero.get("class","Warrior")))[skill_id]["name"],SkillSystem.skill_level(game.hero,skill_id)])
        game.save_game()
        game.update_ui()
        refresh()
    else:
        notice.text="Cannot learn: check level, prerequisites, maximum rank, or skill points."
