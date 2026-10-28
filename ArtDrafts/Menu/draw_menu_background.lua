-- Native Aseprite drawing script. Creates a separate editable draft, never edits game scenes.
-- Run: Aseprite.exe --batch --script-param out=<folder> --script draw_menu_background.lua
local W, H = 320, 180
local out = assert(app.params.out, "Pass --script-param out=<output directory>")
local sprite = Sprite(W, H, ColorMode.RGB)
local initialLayer = sprite.layers[1]
local P = {}
local colors = {
  forest="286b50", forestMid="348060", forestLight="42966a", forestTip="67b87c",
  leafDark="255b46", leafMid="327954", leaf="49955e", leafLight="70b16b",
  woodDark="513b35", wood="955c43", woodLight="bc7e53", woodTop="d89c66",
  cream="f7e9bf", shadow="327455", turf="64c391", turfLight="69c795",
  turfShade="55b784", green="79cf99", greenEdge="5cbd88",
  sandEdge="a9a16c", sandShade="d9bd80", sand="efdaa1", sandLight="fae8b8",
  waterDark="316b81", water="438fad", waterLight="63b2c8", foam="a0d9d3",
  hole="283c35", poleShadow="69796a", white="fff5d8", flagDark="964c3d", flag="d46d4c",
  flower="efd47f", stone="7f9281", stoneLight="bac3a1"
}
for key, hex in pairs(colors) do
  P[key] = app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
end
local image, layer
local names = {}
local function beginLayer(name)
  layer = sprite:newLayer()
  layer.name = name
  names[#names+1] = name
  image = Image(W,H,ColorMode.RGB)
  image:clear(0)
end
local function endLayer()
  sprite:newCel(layer,1,image,Point(0,0))
end
local function pixel(x,y,c)
  x,y=math.floor(x),math.floor(y)
  if x>=0 and y>=0 and x<W and y<H then image:drawPixel(x,y,c) end
end
local function rect(x,y,w,h,c)
  for yy=y,y+h-1 do for xx=x,x+w-1 do pixel(xx,yy,c) end end
end
local function ellipse(cx,cy,rx,ry,c)
  for y=math.floor(cy-ry),math.ceil(cy+ry) do
    for x=math.floor(cx-rx),math.ceil(cx+rx) do
      if ((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then pixel(x,y,c) end
    end
  end
end
local function inside(x,y,poly)
  local result=false
  local j=#poly
  for i=1,#poly do
    local a,b=poly[i],poly[j]
    if ((a[2]>y)~=(b[2]>y)) and (x < (b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]) then result=not result end
    j=i
  end
  return result
end
local function polygon(poly,c)
  local x0,y0,x1,y1=W,H,0,0
  for _,p in ipairs(poly) do x0=math.min(x0,p[1]);y0=math.min(y0,p[2]);x1=math.max(x1,p[1]);y1=math.max(y1,p[2]) end
  for y=y0,y1 do for x=x0,x1 do if inside(x+0.5,y+0.5,poly) then pixel(x,y,c) end end end
end
local function octagon(x,y,w,h,k,c)
  local p={{x+k,y},{x+w-k,y},{x+w-k,y+k/2},{x+w,y+k/2},{x+w,y+h-k/2},{x+w-k,y+h-k/2},{x+w-k,y+h},{x+k,y+h},{x+k,y+h-k/2},{x,y+h-k/2},{x,y+k/2},{x+k,y+k/2}}
  polygon(p,c)
  return p
end
local seed=431730
local function random(lo,hi)
  seed=(seed*48271)%2147483647
  return lo+(seed%(hi-lo+1))
end
local function grass(x,y,c)
  pixel(x,y,c);pixel(x,y-1,c);pixel(x-1,y-2,c);pixel(x+2,y-1,c);pixel(x+2,y-3,c)
end

beginLayer("01 - Outer meadow")
rect(0,0,W,H,P.forest)
for n=1,300 do
  local x,y=random(0,W-1),random(0,H-1)
  if x<20 or x>299 or y<20 or y>159 then
    rect(x,y,random(1,3),1,n%3==0 and P.forestLight or P.forestMid)
  end
end
endLayer()

beginLayer("02 - Timber course border")
octagon(14,18,292,148,12,P.shadow)
octagon(14,13,292,148,12,P.woodDark)
octagon(15,14,290,146,12,P.wood)
octagon(16,15,288,143,12,P.woodLight)
rect(27,15,266,1,P.woodTop)
rect(16,22,1,129,P.woodTop)
rect(27,157,266,2,P.wood)
rect(303,22,2,129,P.woodDark)
-- Cream course markers echo the red/brown and ivory edging in the existing tileset.
for x=40,280,40 do
  rect(x,14,4,5,P.cream)
  rect(x,155,4,4,P.cream)
end
for y=39,139,25 do
  rect(15,y,5,3,P.cream)
  rect(300,y,4,3,P.cream)
end
for _,point in ipairs({{27,17},{291,17},{27,155},{291,155}}) do
  rect(point[1],point[2],2,2,P.woodDark)
  pixel(point[1],point[2],P.woodTop)
end
endLayer()

beginLayer("03 - Quiet mint turf")
local turfPoly=octagon(21,20,278,134,9,P.turfShade)
local inner=octagon(23,22,274,130,8,P.turf)
for y=22,151 do for x=23,296 do
  if inside(x+0.5,y+0.5,inner) and math.floor((x+y*0.5)/28)%2==0 then pixel(x,y,P.turfLight) end
end end
-- Intentionally leave x=104..216, y=25..151 free of objects for logo/buttons.
endLayer()

beginLayer("04 - Static sand bunker")
local rim={{37,33},{68,33},{68,36},{79,36},{79,42},{85,42},{85,56},{79,56},{79,65},{67,65},{67,70},{45,70},{45,67},{34,67},{34,59},{29,59},{29,44},{33,44},{33,37},{37,37}}
polygon(rim,P.greenEdge)
local bank={{38,34},{67,34},{67,37},{78,37},{78,43},{83,43},{83,55},{77,55},{77,64},{66,64},{66,68},{46,68},{46,65},{35,65},{35,58},{31,58},{31,45},{35,45},{35,38},{38,38}}
polygon(bank,P.sandEdge)
local sand={{39,36},{65,36},{65,39},{76,39},{76,45},{81,45},{81,53},{75,53},{75,62},{64,62},{64,66},{47,66},{47,63},{37,63},{37,56},{33,56},{33,46},{37,46},{37,40},{39,40}}
polygon(sand,P.sand)
for n=1,85 do
  local x,y=random(33,81),random(36,66)
  if inside(x+0.5,y+0.5,sand) then
    pixel(x,y,n%3==0 and P.sandShade or P.sandLight)
    if n%5==0 and inside(x+1.5,y+0.5,sand) then pixel(x+1,y,P.sandLight) end
  end
end
endLayer()

beginLayer("05 - Static pond")
local bank={{261,103},{284,103},{284,107},{294,107},{294,117},{298,117},{298,141},{291,141},{291,150},{263,150},{263,146},{248,146},{248,137},{241,137},{241,119},{246,119},{246,109},{261,109}}
polygon(bank,P.green)
local edge={{262,105},{283,105},{283,109},{292,109},{292,118},{296,118},{296,140},{289,140},{289,148},{264,148},{264,144},{250,144},{250,135},{243,135},{243,120},{248,120},{248,111},{262,111}}
polygon(edge,P.waterDark)
local pond={{263,107},{282,107},{282,111},{290,111},{290,120},{294,120},{294,138},{287,138},{287,146},{265,146},{265,142},{252,142},{252,133},{245,133},{245,122},{250,122},{250,113},{263,113}}
polygon(pond,P.water)
for y=107,145 do for x=245,293 do
  if inside(x+0.5,y+0.5,pond) and not inside(x+0.5,y-1.5,pond) then pixel(x,y,P.waterLight) end
end end
for _,p in ipairs({{265,114,6},{280,121,5},{251,128,6},{268,136,8},{284,140,3}}) do
  rect(p[1],p[2],p[3],1,P.waterLight)
  pixel(p[1]+1,p[2]-1,P.foam)
end
-- Two reeds, completely static.
rect(247,140,1,6,P.leafDark);rect(249,139,1,7,P.leafMid);rect(251,142,1,5,P.leafDark)
endLayer()

beginLayer("06 - Putting green and flag")
ellipse(263,70,26,19,P.greenEdge)
ellipse(263,69,25,18,P.green)
ellipse(269,76,6,2,P.turfShade)
ellipse(267,74,4,2,P.hole)
rect(266,43,2,31,P.poleShadow)
rect(266,42,1,31,P.white)
polygon({{267,43},{284,47},{284,49},{267,54}},P.flagDark)
polygon({{268,43},{282,47},{282,48},{268,51}},P.flag)
rect(268,43,3,1,P.cream)
endLayer()

beginLayer("07 - Golf ball and small details")
ellipse(58,131,6,2,P.turfShade)
ellipse(56,128,4,4,P.poleShadow)
ellipse(56,127,4,4,P.cream)
ellipse(55,126,3,3,P.white)
pixel(57,128,P.stoneLight);pixel(54,127,P.stoneLight);pixel(56,130,P.stoneLight)
-- Static tee markers away from the menu's central column.
rect(43,138,3,3,P.woodDark);rect(43,137,3,2,P.cream)
rect(67,138,3,3,P.woodDark);rect(67,137,3,2,P.flag)
for _,p in ipairs({{37,86},{72,102},{89,143},{230,40},{283,89},{232,149}}) do
  grass(p[1],p[2],P.turfShade)
end
local function flower(x,y)
  pixel(x,y+2,P.leafMid);pixel(x-1,y+1,P.leafMid)
  pixel(x,y-1,P.white);pixel(x-1,y,P.white);pixel(x+1,y,P.white);pixel(x,y+1,P.white);pixel(x,y,P.flower)
end
flower(85,40);flower(80,44);flower(36,115);flower(230,141);flower(282,37)
endLayer()

beginLayer("08 - Border shrubs")
local function shrub(cx,cy,r)
  ellipse(cx+2,cy+3,r+1,math.max(3,r-3),P.shadow)
  ellipse(cx,cy,r,r-2,P.leafDark)
  ellipse(cx-4,cy-2,r-3,r-3,P.leafMid)
  ellipse(cx+4,cy-4,r-4,r-3,P.leafMid)
  ellipse(cx-2,cy-5,r-5,r-5,P.leaf)
  ellipse(cx+4,cy-6,3,3,P.leafLight)
  rect(cx-7,cy-5,3,1,P.leafLight)
  rect(cx+4,cy+2,3,1,P.leaf)
end
shrub(8,12,14);shrub(29,3,12);shrub(307,9,15);shrub(318,30,10)
shrub(7,164,15);shrub(28,176,13);shrub(309,168,16);shrub(287,179,12)
for _,p in ipairs({{7,45},{9,88},{12,132},{311,62},{310,113},{89,8},{177,169},{245,8}}) do grass(p[1],p[2],P.forestLight) end
endLayer()

if initialLayer then sprite:deleteLayer(initialLayer) end
sprite:assignColorSpace(ColorSpace{ sRGB=true })
local palette=Palette(35)
local colorKeys={}
for key in pairs(colors) do colorKeys[#colorKeys+1]=key end
table.sort(colorKeys)
palette:resize(#colorKeys)
for i,key in ipairs(colorKeys) do palette:setColor(i-1,Color(P[key])) end
sprite:setPalette(palette)
sprite:saveAs(out.."/menu-background-static-v1.aseprite")
local flat=Image(sprite)
assert(flat.width==320 and flat.height==180,"Incorrect canvas size")
assert(#sprite.frames==1,"Background must be static")
for it in flat:pixels() do assert(app.pixelColor.rgbaA(it())==255,"Unexpected transparent background pixel") end
flat:saveAs(out.."/menu-background-static-v1.png")
local preview=Image(flat)
preview:resize(1280,720)
preview:saveAs(out.."/menu-background-static-v1-preview-4x.png")
local report=assert(io.open(out.."/validation.txt","w"))
report:write("Canvas: 320 x 180\nFrames: 1 (static)\nLayers: "..#sprite.layers.."\nAll pixels opaque: yes\n")
for _,name in ipairs(names) do report:write(name.."\n") end
report:close()
print("Created static minigolf background: 320 x 180, "..#sprite.layers.." layers, 1 frame")
