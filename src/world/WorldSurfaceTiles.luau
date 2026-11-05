--!nonstrict
-- Keep one invisible physics slab; render small tiles so distant Studs can be culled locally.
local Tiles={}
local TILE=32
function Tiles.Build(world)
 local environment=world:FindFirstChild("Environment")
 if not environment then return end
 local bases={}
 for _,base in environment:GetChildren()do
  if base:IsA("BasePart") and (base.Name=="Ground" or base.Name=="Road" or base.Name:match("^Sidewalk")) then table.insert(bases,base)end
 end
 local plots=world:FindFirstChild("Plots")
 if plots then for _,plot in plots:GetChildren()do
  local lawn=plot:FindFirstChild("Lawn")
  if lawn and lawn:IsA("BasePart") and lawn.TopSurface==Enum.SurfaceType.Studs then table.insert(bases,lawn)end
 end end
 for _,base in bases do
  if base:GetAttribute("StudTiles") then continue end
  local folder=Instance.new("Folder");folder.Name=base.Name.."SurfaceTiles";folder.Parent=base.Parent
  local nx,nz=math.ceil(base.Size.X/TILE),math.ceil(base.Size.Z/TILE)
  for x=1,nx do for z=1,nz do
   local sx,sz=math.min(TILE,base.Size.X-(x-1)*TILE),math.min(TILE,base.Size.Z-(z-1)*TILE)
   local p=Instance.new("Part");p.Name="StudTile";p.Anchored=true
   p.Size=Vector3.new(sx,.06,sz)
   p.CFrame=base.CFrame*CFrame.new(-base.Size.X/2+(x-1)*TILE+sx/2,base.Size.Y/2+.03,-base.Size.Z/2+(z-1)*TILE+sz/2)
   p.Color=base.Color;p.Material=Enum.Material.Plastic
   p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
   p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
   p:SetAttribute("StudSurfaceDetail",true);p.Parent=folder
  end end
  base.TopSurface=Enum.SurfaceType.Smooth;base.Transparency=1;base.CastShadow=false
  base:SetAttribute("StudTiles",true)
 end
end
return Tiles
