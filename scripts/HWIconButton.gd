extends Button

var icon_kind:String="character"

func setup(kind:String,label_text:String)->void:
    icon_kind=kind
    text=label_text
    alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_theme_font_size_override("font_size",10)
    add_theme_color_override("font_color",Color("#e8edf3"))
    add_theme_color_override("font_hover_color",Color("#fff4ce"))
    add_theme_color_override("font_pressed_color",Color("#ffffff"))
    queue_redraw()

func _draw()->void:
    var c:=Color("#e7ca7a")
    var x:=size.x*0.5
    var y:=18.0
    draw_circle(Vector2(x,y),15.0,Color("#0a1422"))
    draw_arc(Vector2(x,y),15.5,0.0,TAU,32,c,1.5)
    match icon_kind:
        "character":
            draw_circle(Vector2(x,y-4),4.0,c)
            draw_arc(Vector2(x,y+6),8.0,PI,TAU,20,c,2.2)
            draw_line(Vector2(x-8,y+9),Vector2(x+8,y+9),c,2.0)
        "pet":
            draw_arc(Vector2(x,y+1),8.0,0.0,TAU,24,c,2.0)
            draw_circle(Vector2(x-4,y),1.6,c)
            draw_circle(Vector2(x+4,y),1.6,c)
            draw_line(Vector2(x-5,y-6),Vector2(x-10,y-11),c,2.0)
            draw_line(Vector2(x+5,y-6),Vector2(x+10,y-11),c,2.0)
        "skills":
            for i in range(4):
                var a:=TAU*float(i)/4.0-PI*0.25
                draw_line(Vector2(x,y),Vector2(x+cos(a)*10.0,y+sin(a)*10.0),c,2.0)
            draw_circle(Vector2(x,y),3.0,c)
        "inventory":
            draw_rect(Rect2(x-9,y-7,18,15),c,false,2.0)
            draw_line(Vector2(x-5,y-11),Vector2(x+5,y-11),c,2.0)
            draw_line(Vector2(x-4,y-2),Vector2(x+4,y-2),c,1.5)
        "equipment":
            draw_circle(Vector2(x,y),8.5,Color.TRANSPARENT)
            draw_arc(Vector2(x,y),8.5,0.0,TAU,24,c,2.0)
            draw_line(Vector2(x-7,y+7),Vector2(x+7,y-7),c,2.2)
            draw_line(Vector2(x-1,y-10),Vector2(x-9,y-2),c,2.0)
        "refine":
            draw_line(Vector2(x-9,y-8),Vector2(x+7,y+8),c,3.0)
            draw_circle(Vector2(x+10,y+11),3.5,c)
            draw_arc(Vector2(x-5,y-5),7.0,PI*0.1,PI*1.1,16,c,2.0)
        "map":
            draw_arc(Vector2(x,y),9.0,0.0,TAU,28,c,2.0)
            draw_line(Vector2(x-9,y),Vector2(x+9,y),c,2.0)
            draw_line(Vector2(x,y-9),Vector2(x,y+9),c,2.0)
            draw_circle(Vector2(x,y),2.0,c)
        "objectives":
            draw_rect(Rect2(x-8,y-9,16,19),c,false,2.0)
            draw_line(Vector2(x-5,y-3),Vector2(x-1,y+1),c,2.0)
            draw_line(Vector2(x-1,y+1),Vector2(x+6,y-6),c,2.0)
            draw_line(Vector2(x-4,y+7),Vector2(x+6,y+7),c,1.6)
        "system":
            draw_circle(Vector2(x,y),4.5,c)
            for i in range(8):
                var a:=TAU*float(i)/8.0
                draw_line(Vector2(x+cos(a)*8.0,y+sin(a)*8.0),Vector2(x+cos(a)*11.0,y+sin(a)*11.0),c,2.0)
