local source = assert(app.params.source, "Missing source")
local out = assert(app.params.out, "Missing out")
local sprite = app.open(source)
assert(sprite, "Cannot open SummerTile")
local flat = Image(sprite)
flat:saveAs(out.."/summer-source-reference.png")
local zoom = Image(flat)
zoom:resize(flat.width*4, flat.height*4)
zoom:saveAs(out.."/summer-source-reference-4x.png")
for _,part in ipairs({
  {"sand",48,160,48,48}, {"water",96,160,48,48},
  {"rail-horizontal",0,192,48,16}, {"rail-vertical",64,96,16,48},
  {"turf",48,0,64,64}, {"target-frame",60,12,40,40}
}) do
  local crop=Image(flat,Rectangle(part[2],part[3],part[4],part[5]))
  crop:resize(crop.width*8,crop.height*8)
  crop:saveAs(out.."/summer-part-"..part[1]..".png")
end
local counts, list = {}, {}
for it in flat:pixels() do
  local c=it()
  if app.pixelColor.rgbaA(c)>0 then counts[c]=(counts[c] or 0)+1 end
end
for c,n in pairs(counts) do list[#list+1]={c=c,n=n} end
table.sort(list,function(a,b) return a.n>b.n end)
local f=assert(io.open(out.."/summer-source-colors.txt","w"))
f:write("Source: "..source.."\nCanvas: "..flat.width.." x "..flat.height.."\nFrames: "..#sprite.frames.."\nUsed visible colors: "..#list.."\n")
for _,entry in ipairs(list) do
  local c=entry.c
  f:write(string.format("#%02x%02x%02x alpha=%d pixels=%d\n",app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c),app.pixelColor.rgbaA(c),entry.n))
end
f:close()
print("Inspected "..source..": "..flat.width.."x"..flat.height..", "..#list.." visible colors")
