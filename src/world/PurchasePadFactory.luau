--!nonstrict
-- Shared physical decoration only. Existing server prompts own all purchases.
local Factory={}
local function disc(model,cf,name,diameter,thickness,alpha,color,glow)
	local p=Instance.new("Part");p.Name=name;p.Shape=Enum.PartType.Cylinder
	p.Size=Vector3.new(thickness,diameter,diameter)
	p.CFrame=cf*CFrame.Angles(0,0,math.pi/2)
	p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
	p.Color=Color3.fromHex(color);p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Transparency=alpha;p:SetAttribute("PadAlpha",alpha);p:SetAttribute("PadGlow",glow==true)
	p:SetAttribute("PadSize",p.Size)
	p.Parent=model;return p
end
function Factory.Create(parent,cf,kind,plotId,prompt)
	local model=Instance.new("Model");model.Name=kind.."PurchaseCircle"
	model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
	model:SetAttribute("PurchaseKind",kind);model:SetAttribute("PlotId",plotId);model:SetAttribute("OwnerUserId",0)
	local anchor=Instance.new("Part");anchor.Name="Anchor";anchor.Size=Vector3.one*.1;anchor.CFrame=cf
	anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
	anchor.Parent=model;model.PrimaryPart=anchor
	disc(model,cf*CFrame.new(0,-.035,0),"Halo",6.35,.07,.83,"FF6C8F",true)
	disc(model,cf,"Rim",5.45,.12,.08,"FF6C8F",true)
	disc(model,cf*CFrame.new(0,.045,0),"Center",4.65,.14,.08,"17263B",false)
	disc(model,cf*CFrame.new(0,.125,0),"InnerGlow",.65,.04,.05,"FF6C8F",true)
	local light=Instance.new("PointLight");light.Color=Color3.fromHex("FF6C8F")
	light.Brightness=.35;light.Range=9;light.Shadows=false;light.Parent=anchor
	local reference=Instance.new("ObjectValue");reference.Name="Prompt";reference.Value=prompt;reference.Parent=model
	prompt.Style=Enum.ProximityPromptStyle.Custom
	prompt.RequiresLineOfSight=false
	prompt:SetAttribute("PurchaseCircle",true)
	prompt.ClickablePrompt=true
	model.Parent=parent;model:AddTag("VerityPurchasePad")
	return model
end
return Factory
