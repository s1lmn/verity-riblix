--!nonstrict
-- Optional WorldEvent extension. Never teleports the character from the client.
local Players=game:GetService("Players")
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Interior={}
Interior.__index=Interior

function Interior.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),operationId=nil,deadline=0,complete=false},Interior)
	local gui=W.New("ScreenGui",{Name="VerityInteriorTransition",ResetOnSpawn=false,DisplayOrder=30,ScreenInsets=Enum.ScreenInsets.None},ctx.refs.Gui.Parent)
	self.cleanup:Add(gui)
	self.overlay=W.Frame(gui,"Fade",nil,T.Ink)
	self.overlay.BackgroundTransparency,self.overlay.Visible=1,false
	local hint=W.Text(self.overlay,"Hint","Entering your home…",20,true,T.Paper)
	hint.TextXAlignment,hint.AnchorPoint,hint.Position=Enum.TextXAlignment.Center,Vector2.new(0.5,0.5),UDim2.fromScale(0.5,0.5)
	hint.Size=UDim2.new(0.9,0,0,60)
	self.hint=hint
	self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function() self:Clear() end))
	self.cleanup:Add(Players.LocalPlayer.CharacterAdded:Connect(function() self:Clear() end))
	return self
end

function Interior:Handle(event)
	if event.kind~="InteriorTransition" or type(event.operationId)~="string" then return end
	if event.phase=="Begin" then
		self.operationId,self.deadline,self.complete=event.operationId,os.clock()+8,false
		self.destination=nil
		self.overlay.Visible=true
		self.hint.Text=if event.direction=="Exit" then "Returning to your neighborhood…" else "Entering your home…"
		self.ctx.animation:Tween(self.overlay,0.16,{BackgroundTransparency=0})
	elseif event.operationId==self.operationId then
		if event.phase=="Complete" then
			self.complete=true
			self.destination=if typeof(event.destination)=="Vector3" then event.destination else nil
		elseif event.phase=="Failed" then self:Clear();self.ctx.notifications:Show("The home transition could not finish. Please try the door again.","Error") end
	end
end

function Interior:Tick()
	if not self.operationId then return end
	if os.clock()>self.deadline then self:Clear();self.ctx.notifications:Show("Home loading timed out. The screen has been restored.","Error");return end
	if not self.complete then return end
	if not self.destination then return end
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position-self.destination).Magnitude>18 then return end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={character}
	local result=workspace:Raycast(root.Position,Vector3.new(0,-12,0),params)
	-- A local floor must exist before uncovering the view. Server transition has its own timeout.
	if result and result.Instance.CanCollide then self:Clear() end
end

function Interior:Clear()
	self.operationId,self.complete,self.destination=nil,false,nil
	self.ctx.animation:Tween(self.overlay,0.15,{BackgroundTransparency=1})
	self.overlay.Visible=false
end

function Interior:Destroy() self:Clear();self.cleanup:Destroy() end
return Interior
