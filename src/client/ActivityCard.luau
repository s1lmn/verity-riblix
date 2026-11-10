--!nonstrict
local W=require(script.Parent.UIWidgets)
local Skin=require(script.Parent.HUDSkin)
local Players=game:GetService("Players")
local MobileHUD=require(script.Parent.MobileHUDLayout)
local Card={}

function Card.Build(parent,name,leaveName)
 local root=Skin.PanelFrame(parent,name,UDim2.fromOffset(320,64),12)
 root.Visible=false
 Skin.Accent(root,Skin.Sky)
 local title=W.Text(root,"Title","",13,true,Skin.Sky)
 title.Position=UDim2.fromOffset(15,5);title.Size=UDim2.new(1,-72,0,23)
 local detail=W.Text(root,"Detail","",11,false,Skin.Text)
 detail.Position=UDim2.fromOffset(15,29);detail.Size=UDim2.new(1,-72,1,-34)
 local leave=W.Button(root,leaveName,"×",Skin.Pink)
 leave.Size=UDim2.fromOffset(44,44);leave.Position=UDim2.new(1,-54,0,10)
 return root,title,detail,leave
end

function Card.Layout(root,title,detail,size)
 if MobileHUD.IsTouch() then
  root.AnchorPoint=Vector2.new(1,0)
  root.Position=UDim2.new(1,-8,0,MobileHUD.StatusTop)
  root.Size=UDim2.fromOffset(MobileHUD.StatusWidth(size),74)
  title.TextSize=12
  detail.TextSize=11
  return
 end
 local narrow=size.X<640
 root.AnchorPoint=Vector2.new(if narrow then 1 else .5,0)
 root.Position=if narrow then UDim2.new(1,-8,0,8) else UDim2.new(.5,0,0,8)
 root.Size=UDim2.fromOffset(if narrow then math.clamp(size.X-174,1,300) else 320,if narrow then 74 else 64)
 title.TextSize=if narrow then 11 else 13
 detail.TextSize=if narrow then 10 else 11
end

function Card.ActivityRunning()
 local player=Players.LocalPlayer
 return player:GetAttribute("VerityDiversionKind")~=nil or player:GetAttribute("VerityFusionSlot")~=nil or player:GetAttribute("VerityRaceSlot")~=nil or player:GetAttribute("VerityParkourStep")~=nil or player:GetAttribute("VerityBattleActive")==true
end

function Card.Blocked(ctx)
 return ctx.active or ctx.presenting or ctx.forgeReveal or ctx.rewardOverlay
end

return Card
