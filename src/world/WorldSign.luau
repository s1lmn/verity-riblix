--!nonstrict
local Locale=require(game:GetService("ReplicatedStorage").Shared.LocaleText)
local Sign={}

function Sign.Add(part,source,faces,maxDistance)
 local labels={}
 for _,face in faces or {Enum.NormalId.Front,Enum.NormalId.Back} do
  local gui=Instance.new("SurfaceGui")
  gui.Name="WorldSign";gui.Face=face;gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
  local size=part.Size
  local width=if face==Enum.NormalId.Left or face==Enum.NormalId.Right then size.Z else size.X
  gui.CanvasSize=Vector2.new(320,math.round(320*size.Y/width));gui.MaxDistance=maxDistance or 65
  gui.LightInfluence=0;gui.Parent=part
  local label=Instance.new("TextLabel")
  label.Name="Text";label.Position=UDim2.fromScale(.055,.09);label.Size=UDim2.fromScale(.89,.82)
  label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.TextColor3=Color3.fromHex("FFF4D6")
  label.TextScaled=true;label.TextWrapped=true;label.AutoLocalize=false;label.Parent=gui
  Locale.SetWorld(label,"Text",source)
  table.insert(labels,label)
 end
 return labels
end

return Sign
