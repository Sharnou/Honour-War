extends Button

var icon_kind:String="character"

func setup(kind:String,label_text:String)->void:
    icon_kind=kind
    text=label_text
    alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_theme_font_size_override("font_size",10)
    queue_redraw()

func _draw()->void:
    var c:=Color("#e7ca7a")
    var x:=size.x*0.5
    var y:=18.0
    draw_circle(Vector2(x,y),13.0,Color("#0c1624"))
    draw_arc(Vector2(x,y),14.0,0.0,TAU,24,c,1.6)
    match icon_kind:
        "character":
            draw_circle(Vector2(x,y-4),4.0,c)
            draw_arc(Vector2(x,y+6),7.0,PI,TAU,16,c,2.0)
        "pet":
            draw_circle(Vector2(x,y+1),8.0,c,false,2.0)
            draw_circle(Vector2(x-4,y),1.5,c)
            draw_circle(Vector2(x+4,y),1.5,c)
            draw_line(Vector2(x-6,y-6),Vector2(x-10,y-10),c,2.0)
            draw_line(Vector2(x+6,y-6),Vector2(x+10,y-10),c,2.0)
        "skills":
            for i in range(4):
                var a:=TAU*float(i)/4.0-PI*0.25
                draw_line(Vector2(x,y),Vector2(x+cos(a)*9.0,y+sin(a)*9.0),c,2.0)
            draw_circle(Vector2(x,y),3.0,c)
        "inventory":
            draw_rect(Rect2(x-8,y-7,16,15),c,false,2.0)
            draw_line(Vector2(x-4,y-10),Vector2(x+4,y-10),c,2.0)
        "equipment":
            draw_circle(Vector2(x,y),9.0,c,false,2.0)
            draw_line(Vector2(x-7,y+7),Vector2(x+7,y-7),c,2.0)
            draw_line(Vector2(x-2,y-9),Vector2(x-9,y-2),c,2.0)
        "refine":
            draw_line(Vector2(x-8,y-7),Vector2(x+7,y+8),c,3.0)
            draw_circle(Vector2(x+9,y+10),4.0,c)
            draw_arc(Vector2(x-5,y-5),7.0,PI*0.1,PI*1.1,12,c,2.0)
        "map":
            draw_circle(Vector2(x,y),8.0,c,false,2.0)
            draw_line(Vector2(x-8,y),Vector2(x+8,y),c,2.0)
            draw_line(Vector2(x,y-8),Vector2(x,y+8),c,2.0)
        "system":
            draw_circle(Vector2(x,y),5.0,c)
            for i in range(8):
                var a:=TAU*float(i)/8.0
                draw_line(Vector2(x+cos(a)*8.0,y+sin(a)*8.0),Vector2(x+cos(a)*11.0,y+sin(a)*11.0),c,2.0)
