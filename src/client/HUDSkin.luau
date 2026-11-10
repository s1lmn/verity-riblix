--!nonstrict
local W = require(script.Parent.UIWidgets)
local Skin = {
 Ink=Color3.fromHex("161423"),
 Panel=Color3.fromHex("282638"),
 Text=Color3.fromHex("FBFAFF"),
 Soft=Color3.fromHex("DAD7F0"),
 Mint=Color3.fromHex("A8FA6B"),
 Sky=Color3.fromHex("87DFFF"),
 Gold=Color3.fromHex("FFDB73"),
 Pink=Color3.fromHex("FF849C"),
}

function Skin.PanelFrame(parent,name,size,radius)
 local frame=W.Round(W.Frame(parent,name,size,Skin.Panel),radius)
 W.Stroke(frame,Skin.Ink,2.5).Transparency=0
 return frame
end

function Skin.TextOutline(label)
 W.New("UIStroke",{Color=Skin.Ink,Thickness=1.5},label)
 return label
end

function Skin.Accent(parent,color)
 local stripe=W.Round(W.Frame(parent,"Accent",UDim2.new(0,4,1,-16),color),3)
 stripe.Position=UDim2.fromOffset(6,8)
 return stripe
end

return Skin
