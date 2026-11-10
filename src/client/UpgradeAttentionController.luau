--!nonstrict
-- Only owns its added strokes/badges. Does not fight button feedback tweens or change prices.
local RS=game:GetService("ReplicatedStorage")
local Houses=require(RS.Shared.HouseConfig)
local Card=require(script.Parent.ActivityCard)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Cleanup=require(script.Parent.Cleanup)
local Controller={};Controller.__index=Controller
local function affordable(cash,cost)
 return type(cost)=="number" and cost==cost and cost>0 and cash>=cost
end
function Controller.new(ctx,workshopRows,abilityRows)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),targets={},ready={},nextAt=0},Controller)
 local function add(button,key,panel,nav)
  if not button then return end
  local frame=self.cleanup:Add(W.Round(W.Frame(button,"UpgradeAttention",UDim2.new(1,-6,1,-6)),10))
  frame.Position=UDim2.fromOffset(3,3);frame.BackgroundTransparency=1;frame.Visible=false;frame.ZIndex=4
  local glow=W.Stroke(frame,Color3.fromHex("B8FF87"),5);glow.Transparency=.6
  local inner=W.Round(W.Frame(frame,"InnerRing",UDim2.new(1,-2,1,-2)),9)
  inner.Position=UDim2.fromOffset(1,1);inner.BackgroundTransparency=1;inner.ZIndex=4
  local ring=W.Stroke(inner,T.Gold,2);ring.Transparency=.12
  if nav then
   local badge=W.Round(W.Frame(frame,"UpgradeDot",UDim2.fromOffset(13,13),Color3.fromHex("DFFF9B")),100)
   badge.AnchorPoint=Vector2.new(.5,.5);badge.Position=UDim2.new(1,-3,0,3);badge.ZIndex=5
   local plus=W.Text(badge,"Plus","+",12,true,T.Ink);plus.Size=UDim2.fromScale(1,1);plus.TextXAlignment=Enum.TextXAlignment.Center;plus.ZIndex=6
  end
  table.insert(self.targets,{button=button,root=frame,glow=glow,ring=ring,key=key,panel=panel,nav=nav})
  self.cleanup:Add(function()if button.Parent then button:SetAttribute("UpgradeAvailable",nil)end end)
 end
 for _,name in {"VERITY","WORKSHOP","ABILITIES"} do add(ctx.refs.Nav[name],name,"MORE") end
 add(ctx.refs.Panels.VERITY.Buy,"grow","VERITY")
 add(ctx.refs.Panels.PHONE.Grow,"grow","PHONE")
 add(ctx.refs.Panels.PHONE.Power,"swipe","PHONE")
 for index,row in workshopRows or {} do add(row.buy,"house:"..index,"WORKSHOP") end
 for id,row in abilityRows or {} do add(row.button,"ability:"..id,"ABILITIES") end
 return self
end
function Controller:Refresh()
 local ctx=self.ctx;local state=ctx.net.state;local ready={}
 local available=state and state.VerityUnlocked and ctx.net.connected and not ctx.net:IsBusy()
 if available then
  local cash=state.Cash or 0
  ready.grow=state.VerityLevel<100 and affordable(cash,state.NextVerityUpgradeCost)
  ready.swipe=state.SwipeUpgradeLevel<40 and affordable(cash,state.NextSwipeUpgradeCost)
  ready.VERITY=ready.grow;ready.PHONE=ready.grow or ready.swipe
  local stage=state.HouseIncomeLevel or 0;local nextBuild=Houses.IncomeUpgrades[stage+1]
  local canBuild=nextBuild and state.VerityLevel>=nextBuild.Level and affordable(cash,nextBuild.Cost)
  ready["house:"..(stage+1)]=canBuild==true
  ready.WORKSHOP=canBuild==true
  for _,feature in Houses.Features do
   if not state[feature.Field] and affordable(cash,feature.Cost) then ready.WORKSHOP=true end
  end
  for _,entry in state.AbilityCollection or {} do
   local canBuy=entry.canBuy==true and entry.affordable==true and not entry.premium and not entry.owned
   ready["ability:"..entry.id]=canBuy
   if canBuy then ready.ABILITIES=true end
  end
 end
 ready.MORE=ready.WORKSHOP or ready.ABILITIES
 self.ready=ready
end
function Controller:Tick(now)
 if now>=self.nextAt then self.nextAt=now+.15;self:Refresh() end
 local ctx=self.ctx;local calm=ctx.settings.values.ReducedMotion or ctx.settings.values.ReducedEffects
 local blocked=ctx.presenting or ctx.forgeReveal or ctx.rewardOverlay or Card.ActivityRunning()
 local pulse=if calm then .78 else .5+.5*math.sin(now*math.pi*2/1.6)
 for _,r in self.targets do
  local canUpgrade=self.ready[r.key]==true
  if r.button:GetAttribute("UpgradeAvailable")~=canUpgrade then r.button:SetAttribute("UpgradeAvailable",canUpgrade) end
  local visible=canUpgrade and not blocked and (if r.nav then ctx.active~=r.panel else ctx.active==r.panel)
  r.root.Visible=visible==true
  if visible then r.glow.Transparency=.85-.48*pulse;r.ring.Transparency=.55-.48*pulse end
 end
end
function Controller:Destroy() self.cleanup:Destroy();table.clear(self.targets);table.clear(self.ready) end
return Controller
