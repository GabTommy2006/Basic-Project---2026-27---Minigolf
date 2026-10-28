-- SummerUI v1: editable pixel-art assets explicitly requested by the user.
-- Exact SummerTile palette; exported at native 1x. No game scenes are changed.
local out=assert(app.params.out)
local base=assert(app.params.base)
local source=assert(app.params.source)
local atlasSource=Image(assert(app.open(source)))
local allowed,colors={},{}
for it in atlasSource:pixels() do local c=it();if app.pixelColor.rgbaA(c)>0 then allowed[c]=true end end
local function C(hex)
  local c=app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
  assert(allowed[c],"Color outside SummerTile: "..hex)
  colors[hex]=c;return c
end
local P={edge=C("54311F"),shadow=C("7A4C32"),wood=C("9C6546"),woodLight=C("C7A663"),cream=C("FCE9BD"),gold=C("F0D69F"),goldShade=C("E5C687"),yellow=C("FCE128"),yellowDark=C("8A7200"),yellowShade=C("D1B008"),dark=C("151D2E"),grayDark=C("484C57"),gray=C("6C717D"),grayLight=C("A1A1AA"),white=C("E4E4E7"),red=C("B91C1C"),redDark=C("7F1D1D"),greenDark=C("2D7D51"),green=C("48A874"),greenLight=C("67C794"),track=C("2A2D36"),lockShade=C("A68545")}
local image
local items={}
local groups,groupOrder={},{}
local ninepatch={button_primary=4,button_secondary=4,button_icon=4,panel=4,hud_panel=4,level_card=4,power_frame=2,slider_track=2}
local function classify(name)
  local state=name:match("^primary%-(.+)$");if state then return "button_primary",state end
  state=name:match("^secondary%-(.+)$");if state then return "button_secondary",state end
  state=name:match("^icon%-button%-(.+)$");if state then return "button_icon",state end
  state=name:match("^icon%-(.+)$");if state then return "icons",state end
  state=name:match("^level%-(.+)$");if state then return "level_card",state end
  local size,s=name:match("^star%-(%d+)%-(.+)$");if size then return size=="8" and "star_small" or "star_large",s end
  state=name:match("^slider%-handle%-(.+)$");if state then return "slider_handle",state end
  state=name:match("^checkbox%-(.+)$");if state then return "checkbox",state:gsub("%-","_") end
  state=name:match("^mouse%-hint%-(%d)$");if state then return "mouse_drag_hint",({"press","drag","release"})[tonumber(state)] end
  if name:match("^music%-") or name:match("^sound%-") then return "audio_icons",name:gsub("%-","_") end
  local fixed={panel="panel",["hud-panel"]="hud_panel",logo="logo",lock="lock",["power-frame"]="power_frame",["power-fill"]="power_fill",["slider-track"]="slider_track",["slider-fill"]="slider_fill",["optional-check"]="check",["optional-aim"]="aim_head",["optional-ring"]="ball_ready_ring",["optional-banner"]="result_banner",background="menu_background"}
  assert(fixed[name],"Unclassified asset "..name)
  return fixed[name],"normal"
end
local multiple={button_primary=true,button_secondary=true,button_icon=true,icons=true,audio_icons=true,level_card=true,star_small=true,star_large=true,slider_handle=true,checkbox=true,mouse_drag_hint=true}
local optional={check=true,aim_head=true,ball_ready_ring=true,result_banner=true,mouse_drag_hint=true,power_frame=true,power_fill=true}
local function start(w,h) image=Image(w,h,ColorMode.RGB);image:clear(0) end
local function px(x,y,c)
  x,y=math.floor(x),math.floor(y)
  if x>=0 and y>=0 and x<image.width and y<image.height then image:drawPixel(x,y,c) end
end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end end
local function line(x0,y0,x1,y1,c,size)
  local dx,dy=math.abs(x1-x0),-math.abs(y1-y0)
  local sx,sy=x0<x1 and 1 or -1,y0<y1 and 1 or -1
  local err=dx+dy
  while true do
    rect(x0,y0,size or 1,size or 1,c)
    if x0==x1 and y0==y1 then break end
    local e=2*err
    if e>=dy then err=err+dy;x0=x0+sx end
    if e<=dx then err=err+dx;y0=y0+sy end
  end
end
local function ellipse(cx,cy,rx,ry,c)
  for y=math.floor(cy-ry),math.ceil(cy+ry) do for x=math.floor(cx-rx),math.ceil(cx+rx) do
    if ((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then px(x,y,c) end
  end end
end
local function poly(points,c)
  for y=0,image.height-1 do for x=0,image.width-1 do
    local inside=false;local j=#points
    for i=1,#points do
      local a,b=points[i],points[j]
      if ((a[2]>y+0.5)~=(b[2]>y+0.5)) and x+0.5<(b[1]-a[1])*(y+0.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
      j=i
    end
    if inside then px(x,y,c) end
  end end
end
local function save(name)
  for it in image:pixels() do assert(app.pixelColor.rgbaA(it())==0 or allowed[it()],"Color outside SummerTile") end
  local group,state=classify(name)
  local file=group..(multiple[group] and ("_"..state) or "")..".png"
  image:saveAs(out.."/png/"..file)
  local item={name=name,group=group,state=state,file="png/"..file,image=Image(image)}
  items[#items+1]=item
  if not groups[group] then groups[group]={};groupOrder[#groupOrder+1]=group end
  groups[group][#groups[group]+1]=item
end
local function button(w,h,state,primary)
  start(w,h)
  local edge,shadow,face,shine=P.edge,P.shadow,primary and P.gold or P.cream,P.cream
  if state=="hover" then face=primary and P.cream or P.white end
  if state=="pressed" then face=P.goldShade end
  if state=="disabled" then edge=P.grayDark;shadow=P.gray;face=P.grayLight;shine=P.grayLight end
  rect(2,0,w-4,h,edge);rect(1,1,w-2,h-2,edge);rect(0,2,w,h-4,edge)
  rect(2,1,w-4,h-3,state=="disabled" and P.gray or P.wood)
  rect(1,2,w-2,h-5,state=="disabled" and P.gray or P.wood)
  rect(2,h-3,w-4,2,shadow)
  local top=state=="pressed" and 4 or 3
  rect(3,top,w-6,h-top-4,face)
  if state~="pressed" and state~="disabled" then
    line(3,2,w-4,2,P.woodLight);line(2,3,2,h-5,P.woodLight)
    line(4,top,w-5,top,shine)
    px(2,2,P.cream);px(w-3,2,P.woodLight)
  end
  if state=="hover" then
    local focus=primary and P.yellow or P.gold
    line(3,top,w-4,top,focus);line(3,top,3,h-5,focus)
    line(w-4,top,w-4,h-5,focus);line(3,h-5,w-4,h-5,focus)
  end
  if state=="pressed" then line(3,3,w-4,3,shadow) end
end
for _,state in ipairs({"normal","hover","pressed","disabled"}) do
  button(88,18,state,true);save("primary-"..state)
  button(88,18,state,false);save("secondary-"..state)
  button(20,20,state,false);save("icon-button-"..state)
end
local function panel(w,h)
  start(w,h);rect(1,0,w-2,h,P.edge);rect(0,1,w,h-2,P.edge)
  rect(1,1,w-2,h-2,P.wood);line(2,1,w-3,1,P.woodLight);line(1,2,1,h-3,P.woodLight)
  line(2,h-2,w-3,h-2,P.shadow);line(w-2,2,w-2,h-3,P.shadow)
  rect(4,4,w-8,h-8,P.cream)
  for _,p in ipairs({{2,2},{w-4,2},{2,h-4},{w-4,h-4}}) do
    rect(p[1],p[2],2,2,P.edge);px(p[1],p[2],P.woodLight)
  end
end
panel(32,32);save("panel");panel(80,24);save("hud-panel")
local function glyph(name)
  start(16,16)
  if name=="pause" then rect(4,3,3,10,P.edge);rect(9,3,3,10,P.edge)
  elseif name=="back" then poly({{2,8},{8,2},{8,6},{14,6},{14,10},{8,10},{8,14}},P.edge)
  elseif name=="next" then poly({{14,8},{8,2},{8,6},{2,6},{2,10},{8,10},{8,14}},P.edge)
  elseif name=="home" then poly({{1,8},{8,1},{15,8}},P.edge);rect(4,8,9,6,P.edge);rect(7,10,3,4,0)
  elseif name=="restart" then
    line(4,4,11,4,P.edge,2);line(11,4,12,10,P.edge,2);line(12,10,8,13,P.edge,2);line(8,13,3,10,P.edge,2)
    poly({{1,2},{7,4},{2,8}},P.edge)
  elseif name=="settings" then
    rect(6,1,4,14,P.edge);rect(1,6,14,4,P.edge)
    rect(3,3,3,3,P.edge);rect(10,3,3,3,P.edge);rect(3,10,3,3,P.edge);rect(10,10,3,3,P.edge)
    ellipse(7.5,7.5,5.5,5.5,P.edge);ellipse(7.5,7.5,4.5,4.5,P.wood)
    ellipse(7.5,7.5,2.5,2.5,P.edge);ellipse(7.5,7.5,1.5,1.5,0)
    line(6,3,9,3,P.woodLight)
  elseif name=="close" then line(3,3,11,11,P.red,2);line(3,11,11,3,P.red,2)
  elseif name=="help" then
    local rows={"01110","10001","00001","00010","00100","00000","00100"}
    for y,row in ipairs(rows) do for x=1,#row do if row:sub(x,x)=="1" then px(5+x-1,4+y-1,P.edge) end end end
  end
end
for _,name in ipairs({"pause","back","restart","home","settings","close","next","help"}) do glyph(name);save("icon-"..name) end
for _,kind in ipairs({"music","sound"}) do for _,state in ipairs({"on","off"}) do
  start(16,16)
  if kind=="music" then
    rect(5,3,7,2,P.edge);rect(5,4,2,7,P.edge);rect(10,4,2,6,P.edge)
    ellipse(4,11,2,2,P.edge);ellipse(9,10,2,2,P.edge)
  else
    rect(2,6,3,5,P.edge);poly({{5,6},{9,3},{9,14},{5,11}},P.edge)
    line(11,5,13,7,P.edge);line(13,7,13,10,P.edge);line(13,10,11,12,P.edge)
  end
  if state=="off" then line(2,13,13,2,P.redDark,2);line(2,12,12,2,P.red) end
  save(kind.."-"..state)
end end
-- Native pixel lettering for the MINIGOLF logo; other UI text stays dynamic in Godot.
local letters={M={"10001","11011","10101","10101","10001","10001","10001"},I={"11111","00100","00100","00100","00100","00100","11111"},N={"10001","11001","11001","10101","10011","10011","10001"},G={"01111","10000","10000","10111","10001","10001","01110"},O={"01110","10001","10001","10001","10001","10001","01110"},L={"10000","10000","10000","10000","10000","10000","11111"},F={"11111","10000","10000","11110","10000","10000","10000"}}
start(112,32)
local word="MINIGOLF"
for index=1,#word do local rows=letters[word:sub(index,index)]
  for y,row in ipairs(rows) do for x=1,5 do if row:sub(x,x)=="1" then rect(8+(index-1)*12+(x-1)*2-1,8+(y-1)*2-1,4,4,P.edge) end end end
end
for index=1,#word do local rows=letters[word:sub(index,index)]
  for y,row in ipairs(rows) do for x=1,5 do if row:sub(x,x)=="1" then rect(8+(index-1)*12+(x-1)*2,8+(y-1)*2,2,2,y<3 and P.cream or P.gold) end end end
end
ellipse(6,27,3,3,P.grayLight);ellipse(5,26,2,2,P.white)
rect(107,5,1,23,P.white);poly({{108,5},{112,7},{108,10}},P.red)
save("logo")
for _,state in ipairs({"normal","hover","pressed","locked"}) do
  panel(40,40)
  if state=="hover" then rect(3,3,34,34,P.yellow);rect(4,4,32,32,P.cream)
  elseif state=="pressed" then rect(4,4,32,32,P.goldShade)
  elseif state=="locked" then
    rect(1,1,38,38,P.gray);rect(0,1,1,38,P.grayDark);rect(39,1,1,38,P.grayDark);rect(4,4,32,32,P.grayLight)
  end
  save("level-"..state)
end
start(12,12)
ellipse(5.5,4,3.5,4,P.gray);ellipse(5.5,4,2,2.5,0)
rect(1,5,10,7,P.edge);rect(2,6,8,5,P.woodLight);rect(2,10,8,1,P.lockShade)
rect(5,7,2,3,P.edge);px(3,6,P.cream);save("lock")
for _,size in ipairs({8,16}) do for _,state in ipairs({"empty","full"}) do
  start(size,size)
  local edge=state=="full" and P.yellowDark or P.grayDark
  local face=state=="full" and P.yellow or P.grayLight
  if size==8 then
    local points={}
    for k=0,9 do local a=-math.pi/2+k*math.pi/5;local r=k%2==0 and 4 or 1.9;points[#points+1]={4+math.cos(a)*r,4+math.sin(a)*r} end
    poly(points,edge)
    local old=Image(image)
    for y=1,6 do for x=1,6 do
      if old:getPixel(x,y)~=0 and (y==2 or y==3 or y==4 or x==3 or x==4) then px(x,y,face) end
    end end
    if state=="full" then px(3,2,P.cream);px(2,3,P.cream) end
  else
    local p={}
    for k=0,9 do local a=-math.pi/2+k*math.pi/5;local r=k%2==0 and 7.5 or 3.5;p[#p+1]={8+math.cos(a)*r,8+math.sin(a)*r} end
    poly(p,edge)
    local old=Image(image)
    for y=1,14 do for x=1,14 do
      if old:getPixel(x,y)~=0 and old:getPixel(x-1,y)~=0 and old:getPixel(x+1,y)~=0 and old:getPixel(x,y-1)~=0 and old:getPixel(x,y+1)~=0 then px(x,y,y>9 and (state=="full" and P.yellowShade or P.gray) or face) end
    end end
    if state=="full" then line(7,4,6,7,P.cream) end
  end
  save("star-"..size.."-"..state)
end end
start(80,10);rect(0,0,80,10,P.edge);rect(1,1,78,8,P.wood);line(2,1,77,1,P.woodLight);rect(2,2,76,6,P.track);save("power-frame")
start(76,6);rect(0,0,76,6,P.yellow);rect(0,5,76,1,P.yellowShade);save("power-fill")
start(80,6);rect(0,0,80,6,P.track);rect(2,2,76,2,P.grayDark);save("slider-track")
start(76,2);rect(0,0,76,2,P.gold);save("slider-fill")
for _,state in ipairs({"normal","hover","dragging"}) do
  start(8,12);rect(1,0,6,12,P.edge);rect(0,1,8,10,P.edge)
  rect(1,1,6,10,state=="normal" and P.wood or state=="hover" and P.woodLight or P.shadow)
  line(2,1,5,1,state=="hover" and P.cream or P.woodLight)
  line(2,2,2,9,state=="hover" and P.cream or P.woodLight);save("slider-handle-"..state)
end
for _,state in ipairs({"unchecked","checked","unchecked-focus","checked-focus"}) do
  start(12,12);rect(0,0,12,12,P.edge);rect(1,1,10,10,P.shadow);rect(2,2,8,8,P.cream)
  if state:find("focus") then rect(1,1,10,10,P.yellow);rect(2,2,8,8,P.cream) end
  if state=="checked" or state=="checked-focus" then line(3,6,5,8,P.greenDark);line(5,8,9,4,P.greenDark) end
  save("checkbox-"..state)
end
for step=1,3 do
  start(48,24)
  local bx=step==3 and 27 or 21
  ellipse(bx,18,4,4,P.grayLight);ellipse(bx-1,17,3,3,P.white)
  if step==1 then
    rect(34,3,10,15,P.grayDark);rect(35,4,8,13,P.white);rect(35,4,4,6,P.red);line(39,4,39,10,P.gray)
  elseif step==2 then
    poly({{5,7},{5,17},{8,14},{11,18},{13,17},{10,13},{14,13}},P.grayDark)
    poly({{6,9},{6,15},{8,12},{11,12}},P.white)
    line(17,17,10,17,P.woodLight);poly({{8,17},{12,14},{12,20}},P.woodLight)
    line(26,17,40,17,P.red);poly({{43,17},{38,13},{38,21}},P.red)
  else
    line(7,17,17,17,P.gray);line(10,20,18,20,P.grayLight)
    line(33,17,41,17,P.red);poly({{45,17},{39,13},{39,21}},P.red)
  end
  save("mouse-hint-"..step)
end
start(8,8);line(1,4,3,6,P.greenDark);line(3,6,7,1,P.greenDark);save("optional-check")
start(8,8);poly({{1,0},{7,4},{1,8}},P.edge);poly({{2,2},{5,4},{2,6}},P.yellow);save("optional-aim")
start(16,16);ellipse(7.5,7.5,7.5,7.5,P.greenDark);ellipse(7.5,7.5,6.5,6.5,P.cream);ellipse(7.5,7.5,5.5,5.5,0);save("optional-ring")
start(112,24);poly({{0,5},{12,5},{12,0},{100,0},{100,5},{112,5},{108,12},{112,19},{100,19},{100,24},{12,24},{12,19},{0,19},{4,12}},P.edge)
rect(13,1,86,22,P.woodLight);rect(14,2,84,19,P.gold);line(15,2,96,2,P.cream);save("optional-banner")
-- Preserve the previously chosen v1 background, including all 8 editable layers.
local background=assert(app.open(base.."/menu-background-v1-summertile-colors.aseprite"))
image=Image(background);save("background")
local backgroundCopy=Sprite(background)
backgroundCopy:saveAs(out.."/sources/menu_background.aseprite")

-- One editable master atlas: a separate named layer per exported image/state.
local atlasSprite=Sprite(512,512,ColorMode.RGB)
local first=atlasSprite.layers[1]
local x,y,rowH=2,2,0
local regions={}
for _,item in ipairs(items) do
  if x+item.image.width+2>512 then x=2;y=y+rowH+2;rowH=0 end
  assert(y+item.image.height+2<=512,"Master atlas overflow")
  local l=atlasSprite:newLayer();l.name=item.group.." / "..item.state
  atlasSprite:newCel(l,1,item.image,Point(x,y))
  local entry={id=item.group.."/"..item.state,group=item.group,state=item.state,png=item.file,x=x,y=y,width=item.image.width,height=item.image.height,optional=optional[item.group] or false}
  if ninepatch[item.group] then entry.nine_patch_margin=ninepatch[item.group] end
  regions[#regions+1]=entry
  x=x+item.image.width+2;rowH=math.max(rowH,item.image.height)
end
atlasSprite:deleteLayer(first)
local palette=Palette(43);local list={}
for c in pairs(allowed) do list[#list+1]=c end;table.sort(list)
palette:resize(#list)
for i,c in ipairs(list) do palette:setColor(i-1,Color(c)) end
atlasSprite:setPalette(palette)
atlasSprite:saveAs(out.."/SummerUI-v1.aseprite")
local atlasFlat=Image(atlasSprite);atlasFlat:saveAs(out.."/SummerUI-v1.png")
local verifiedFrames=0
-- Also export one conveniently sized .aseprite source per checklist asset group.
for _,group in ipairs(groupOrder) do
  if group~="menu_background" then
    local set=groups[group]
    local sp=Sprite(set[1].image.width,set[1].image.height,ColorMode.RGB)
    local art=sp.layers[1];art.name=group
    for i,item in ipairs(set) do
      assert(item.image.width==sp.width and item.image.height==sp.height,"State canvas mismatch")
      if i>1 then sp:newEmptyFrame(i) end
      sp:newCel(art,i,item.image,Point(0,0))
      local tag=sp:newTag(i,i);tag.name=item.state
    end
    sp:setPalette(palette)
    sp:saveAs(out.."/sources/"..group..".aseprite")
    -- Check the saved source by reopening it and comparing every exported frame.
    local saved=assert(app.open(out.."/sources/"..group..".aseprite"))
    for i,item in ipairs(set) do
      local rendered=Image(saved.width,saved.height,ColorMode.RGB)
      rendered:clear(0);rendered:drawSprite(saved,i,Point(0,0))
      assert(rendered:isEqual(item.image),"Saved frame does not match PNG: "..group)
      verifiedFrames=verifiedFrames+1
    end
  end
end
-- Ensure atlas regions never overlap and contain their original untrimmed image.
for i,item in ipairs(items) do
  local r=regions[i]
  local crop=Image(atlasFlat,Rectangle(r.x,r.y,r.width,r.height))
  assert(crop:isEqual(item.image),"Atlas region mismatch")
  for j=1,i-1 do local a=regions[j]
    assert(not (r.x<a.x+a.width and a.x<r.x+r.width and r.y<a.y+a.height and a.y<r.y+r.height),"Atlas regions overlap")
  end
end
local manifest={name="SummerUI",version=1,canvas_scale=1,atlas="SummerUI-v1.png",atlas_width=512,atlas_height=512,padding=2,palette="SummerTile.gpl",palette_colors=#list,source="SummerTile.aseprite",state_images_are_not_animations=true,regions=regions}
local manifestFile=assert(io.open(out.."/SummerUI-v1.json","w"));manifestFile:write(json.encode(manifest));manifestFile:close()
local f=assert(io.open(out.."/validation.txt","w"))
f:write("Pack: SummerUI v1\nSource palette: SummerTile.aseprite\nAsset groups: "..#groupOrder.."\nIndividual PNGs: "..#items.."\nAll visible asset pixels are exact SummerTile colors: yes\nStatic state images: yes\nMaster atlas layers: "..#atlasSprite.layers.."\nSame canvas size across each group's states: yes\nSaved individual-source frames compared to PNGs: "..verifiedFrames.."\nAtlas regions compared to original pixels: "..#regions.."\nAtlas overlap: none\nGame scene integration: not performed\n")
f:close()
print("Created SummerUI v1: "..#groupOrder.." groups, "..#items.." PNGs, "..verifiedFrames.." saved frames verified")
