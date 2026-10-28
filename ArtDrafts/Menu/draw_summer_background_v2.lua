-- Draws inside Aseprite from the original SummerTile artwork and its exact used colors.
-- Does not change the source document or integrate this draft into Godot.
local sourcePath=assert(app.params.source,"Missing source file")
local out=assert(app.params.out,"Missing output directory")
local source=assert(app.open(sourcePath),"Cannot open SummerTile")
local atlas=Image(source)
local W,H=320,180
local used,list={},{}
for it in atlas:pixels() do local c=it(); if app.pixelColor.rgbaA(c)>0 then used[c]=(used[c] or 0)+1 end end
for c,n in pairs(used) do list[#list+1]={c=c,n=n} end
table.sort(list,function(a,b) if a.n==b.n then return a.c<b.c end return a.n>b.n end)
local function color(hex)
  local c=app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
  assert(used[c],"Color not present in SummerTile: "..hex)
  return c
end
local P={
  soil=color("9c6546"), soilShade=color("7a4c32"), soilDark=color("54311f"),
  grass=color("67c794"), grassEdge=color("48a874"), grassDark=color("2d7d51"),
  white=color("e4e4e7"), gray=color("a1a1aa"), dark=color("151d2e"),
  red=color("b91c1c"), redDark=color("7f1d1d")
}
local sprite=Sprite(W,H,ColorMode.RGB)
local initialLayer=sprite.layers[1]
local image,layer
local layerNames={}
local function beginLayer(name)
  layer=sprite:newLayer();layer.name=name;layerNames[#layerNames+1]=name
  image=Image(W,H,ColorMode.RGB);image:clear(0)
end
local function endLayer() sprite:newCel(layer,1,image,Point(0,0)) end
local function pixel(x,y,c)
  x,y=math.floor(x),math.floor(y)
  if x>=0 and x<W and y>=0 and y<H then image:drawPixel(x,y,c) end
end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do pixel(xx,yy,c) end end end
local function polygon(poly,c)
  local minx,miny,maxx,maxy=W,H,0,0
  for _,p in ipairs(poly) do minx=math.min(minx,p[1]);miny=math.min(miny,p[2]);maxx=math.max(maxx,p[1]);maxy=math.max(maxy,p[2]) end
  for y=miny,maxy do for x=minx,maxx do
    local inside=false;local j=#poly
    for i=1,#poly do
      local a,b=poly[i],poly[j]
      if ((a[2]>y+0.5)~=(b[2]>y+0.5)) and x+0.5<(b[1]-a[1])*(y+0.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
      j=i
    end
    if inside then pixel(x,y,c) end
  end end
end
local function blit(sx,sy,w,h,dx,dy,filter)
  for y=0,h-1 do for x=0,w-1 do
    local c=atlas:getPixel(sx+x,sy+y)
    if app.pixelColor.rgbaA(c)>0 and (not filter or filter(c)) then pixel(dx+x,dy+y,c) end
  end end
end
local function sliceAxis(d,length)
  if d<8 then return d end
  if d>=length-8 then return 40-(length-d) end
  return 8+(d-8)%24
end

beginLayer("01 - SummerTile brown ground")
rect(0,0,W,H,P.soil)
endLayer()

beginLayer("02 - Original red-white course frame")
-- Exact 40x40 frame from SummerTile's large target, expanded as a tiled nine-slice.
-- Corners and edge pixel patterns are copied, never resampled or recolored.
rect(21,21,286,145,P.soilShade)
rect(23,23,284,143,P.soilDark)
for y=0,147 do for x=0,287 do
  local sx=60+sliceAxis(x,288)
  local sy=12+sliceAxis(y,148)
  pixel(16+x,16+y,atlas:getPixel(sx,sy))
end end
-- Repeat the original straight rail's 16px red/white cadence rather than stretching it.
for i=0,271 do for j=0,3 do
  pixel(24+i,20+j,atlas:getPixel(16+i%16,192+j))
  pixel(24+i,156+j,atlas:getPixel(16+i%16,204+j))
end end
for i=0,131 do for j=0,3 do
  pixel(20+j,24+i,atlas:getPixel(16+i%16,192+j))
  pixel(296+j,24+i,atlas:getPixel(16+i%16,204+j))
end end
endLayer()

beginLayer("03 - Flat beveled SummerTile turf")
-- The atlas uses flat grass with a 1px lighter/darker bevel, without mowing stripes.
rect(24,24,272,132,P.grassDark)
rect(25,25,270,130,P.grassEdge)
rect(26,26,268,128,P.grass)
-- Keep x=104..216 clear for the eventual menu logo and controls.
endLayer()

beginLayer("04 - Sand copied from SummerTile")
blit(48,160,48,48,32,34)
endLayer()

beginLayer("05 - Water copied from SummerTile")
blit(96,160,48,48,242,104)
endLayer()

beginLayer("06 - Hole and static flag - source colors")
-- The existing hole, including its angular 1px design, is reused directly.
blit(20,20,8,8,264,65)
rect(267,44,2,25,P.gray)
rect(267,43,1,25,P.white)
polygon({{269,44},{281,48},{281,50},{269,54}},P.redDark)
polygon({{269,44},{279,48},{269,51}},P.red)
endLayer()

beginLayer("07 - Ball extracted from original target")
-- The original target ball's white/gray pixels, without the surrounding brown floor.
rect(54,130,7,2,P.grassEdge)
blit(74,26,12,12,50,120,function(c) return c==P.white or c==P.gray end)
rect(42,136,3,3,P.redDark);rect(42,135,3,2,P.red)
rect(68,136,3,3,P.gray);rect(68,135,3,2,P.white)
endLayer()

beginLayer("08 - Original direction tile")
blit(128,64,16,16,79,118)
endLayer()

beginLayer("09 - Original diamond markers")
-- Small existing gray diamonds instead of newly invented foliage or flowers.
blit(180,2,14,12,4,82)
blit(180,2,14,12,304,78)
blit(180,2,14,12,278,166)
endLayer()

if initialLayer then sprite:deleteLayer(initialLayer) end
sprite:assignColorSpace(ColorSpace{sRGB=true})
-- Keep ALL 43 actual source colors available, including colors unused by this background.
local palette=Palette(#list)
for i,entry in ipairs(list) do palette:setColor(i-1,Color(entry.c)) end
sprite:setPalette(palette)
local flat=Image(sprite)
local outputColors={}
for it in flat:pixels() do
  local c=it()
  assert(app.pixelColor.rgbaA(c)==255,"Unexpected transparent output pixel")
  assert(used[c],"Output contains a color absent from SummerTile")
  outputColors[c]=true
end
local outputCount=0
for _ in pairs(outputColors) do outputCount=outputCount+1 end
assert(#sprite.frames==1,"Background must have one frame")
assert(sprite.width==320 and sprite.height==180,"Wrong canvas size")
sprite:saveAs(out.."/menu-background-summertile-v2.aseprite")
flat:saveAs(out.."/menu-background-summertile-v2.png")
local preview=Image(flat);preview:resize(1280,720);preview:saveAs(out.."/menu-background-summertile-v2-preview-4x.png")
local paletteFile=assert(io.open(out.."/summertile-used-colors.gpl","w"))
paletteFile:write("GIMP Palette\nName: SummerTile - all actual used colors\nColumns: 8\n#\n")
for _,entry in ipairs(list) do
  local c=entry.c
  paletteFile:write(string.format("%d %d %d\t#%02x%02x%02x\n",app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c),app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c)))
end
paletteFile:close()
local f=assert(io.open(out.."/summertile-v2-validation.txt","w"))
f:write("Source: "..sourcePath.."\nCanvas: 320 x 180\nFrames: 1 (static)\nLayers: "..#sprite.layers.."\nSource used colors: "..#list.."\nFull source palette preserved: "..#list.." entries\nVisible background colors: "..outputCount.."\nAll output colors belong to source: yes\nAll output pixels opaque: yes\nSource opened read-only and never saved: yes\n")
for _,name in ipairs(layerNames) do f:write(name.."\n") end
f:close()
print("Created SummerTile background v2 with "..#list.." source palette entries and "..outputCount.." visible colors")
