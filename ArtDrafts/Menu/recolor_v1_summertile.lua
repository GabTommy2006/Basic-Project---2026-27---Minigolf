-- Recolors a copy of v1, preserving every layer, cel position, silhouette and frame.
-- Only colors that actually occur in SummerTile are allowed in the result.
local input=assert(app.params.input,"Missing v1 file")
local sourcePath=assert(app.params.source,"Missing SummerTile file")
local out=assert(app.params.out,"Missing output directory")
local original=assert(app.open(input),"Cannot open v1")
local source=assert(app.open(sourcePath),"Cannot open SummerTile")
local sourceImage=Image(source)
local sourceColors,sourceList={},{}
for it in sourceImage:pixels() do
  local c=it()
  if app.pixelColor.rgbaA(c)>0 then sourceColors[c]=(sourceColors[c] or 0)+1 end
end
for c,n in pairs(sourceColors) do sourceList[#sourceList+1]={c=c,n=n} end
table.sort(sourceList,function(a,b) if a.n==b.n then return a.c<b.c end return a.n>b.n end)
local function rgba(hex)
  return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
end
-- Map by material, not by an indiscriminate nearest-RGB match.
local pairsByMaterial={
  {"286b50","2d7d51"}, {"348060","48a874"}, {"42966a","48a874"}, {"67b87c","67c794"},
  {"255b46","151d2e"}, {"327954","2d7d51"}, {"49955e","48a874"}, {"70b16b","67c794"},
  {"513b35","54311f"}, {"955c43","7a4c32"}, {"bc7e53","9c6546"}, {"d89c66","c7a663"},
  {"f7e9bf","fce9bd"}, {"327455","2d7d51"}, {"64c391","67c794"}, {"69c795","67c794"},
  {"55b784","48a874"}, {"79cf99","67c794"}, {"5cbd88","48a874"},
  {"a9a16c","a68545"}, {"d9bd80","e5c687"}, {"efdaa1","f0d69f"}, {"fae8b8","fce9bd"},
  {"316b81","316e8c"}, {"438fad","3b95d9"}, {"63b2c8","51a5e6"}, {"a0d9d3","e4e4e7"},
  {"283c35","151d2e"}, {"69796a","6c717d"}, {"fff5d8","e4e4e7"},
  {"964c3d","7f1d1d"}, {"d46d4c","b91c1c"}, {"efd47f","f0d69f"},
  {"7f9281","6c717d"}, {"bac3a1","a1a1aa"}
}
local mapping={}
for _,pair in ipairs(pairsByMaterial) do
  local old,new=rgba(pair[1]),rgba(pair[2])
  assert(sourceColors[new],"Replacement not present in SummerTile: "..pair[2])
  mapping[old]=new
end
local result=Sprite(original)
assert(#result.layers==#original.layers,"Layer count changed")
assert(#result.frames==#original.frames,"Frame count changed")
local changedCount=0
for index,cel in ipairs(result.cels) do
  local old=original.cels[index]
  assert(cel.position.x==old.position.x and cel.position.y==old.position.y,"Cel moved")
  assert(cel.image.width==old.image.width and cel.image.height==old.image.height,"Cel size changed")
  local replacement=Image(cel.image)
  for it in replacement:pixels() do
    local c=it()
    if app.pixelColor.rgbaA(c)>0 then
      assert(mapping[c],"Unmapped v1 pixel color")
      it(mapping[c]);changedCount=changedCount+1
    end
  end
  -- Assert an exact per-pixel recolor, with unchanged alpha masks and no new marks.
  for y=0,replacement.height-1 do for x=0,replacement.width-1 do
    local before,after=old.image:getPixel(x,y),replacement:getPixel(x,y)
    assert(app.pixelColor.rgbaA(before)==app.pixelColor.rgbaA(after),"Silhouette changed")
    assert(after==(mapping[before] or before),"Unexpected geometry or pixel edit")
  end end
  cel.image=replacement
end
for i,layer in ipairs(result.layers) do assert(layer.name==original.layers[i].name,"Layer name changed") end
local palette=Palette(#sourceList)
for i,entry in ipairs(sourceList) do palette:setColor(i-1,Color(entry.c)) end
result:setPalette(palette)
local flat=Image(result)
local actualColors={}
for it in flat:pixels() do
  local c=it()
  assert(app.pixelColor.rgbaA(c)==255,"Transparent background pixel")
  assert(sourceColors[c],"Output color absent from SummerTile")
  actualColors[c]=true
end
local count=0
for _ in pairs(actualColors) do count=count+1 end
result:saveAs(out.."/menu-background-v1-summertile-colors.aseprite")
flat:saveAs(out.."/menu-background-v1-summertile-colors.png")
local preview=Image(flat);preview:resize(1280,720)
preview:saveAs(out.."/menu-background-v1-summertile-colors-preview-4x.png")
local f=assert(io.open(out.."/v1-summertile-recolor-validation.txt","w"))
f:write("Input: "..input.."\nPalette source: "..sourcePath.."\nCanvas: "..result.width.." x "..result.height.."\nFrames: "..#result.frames.."\nLayers: "..#result.layers.."\nLayer names and cel positions unchanged: yes\nPer-layer alpha masks unchanged: yes\nEvery visible pixel is an exact mapped v1 pixel: yes\nNew shapes or objects: none\nPalette entries: "..#sourceList.."\nVisible background colors: "..count.."\nAll visible colors belong to SummerTile: yes\n")
f:write("Some subtle v1 green shades share the same SummerTile color; the faint mowing stripes merge into the base grass.\n")
f:close()
print("Recolored v1: "..#result.layers.." unchanged layers; "..count.." visible SummerTile colors; "..changedCount.." layer pixels remapped")
