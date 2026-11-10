--!nonstrict
-- Decoration only. All transactions still use the existing native server prompts.
local Factory={}
local function piece(model,cf,name,size,alpha,color,glow,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf
 if shape then p.Shape=shape end
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Color=Color3.fromHex(color);p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
 p.Transparency=alpha;p:SetAttribute("PadAlpha",alpha);p:SetAttribute("PadGlow",glow==true);p:SetAttribute("PadSize",size)
 p.Parent=model;return p
end
local function disc(model,cf,name,diameter,thickness,alpha,color,glow)
 return piece(model,cf*CFrame.Angles(0,0,math.pi/2),name,Vector3.new(thickness,diameter,diameter),alpha,color,glow,Enum.PartType.Cylinder)
end
function Factory.Create(parent,cf,kind,plotId,prompt)
 local model=Instance.new("Model");model.Name=kind.."PurchaseCircle";model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute("PurchaseKind",kind);model:SetAttribute("PlotId",plotId);model:SetAttribute("OwnerUserId",0)
 local anchor=Instance.new("Part");anchor.Name="Anchor";anchor.Size=Vector3.one*.1;anchor.CFrame=cf
 anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
 anchor.Parent=model;model.PrimaryPart=anchor
 local radius=if kind=="Hero" then 3.05 else 2.35
 disc(model,cf*CFrame.new(0,-.045,0),"Base",radius*2+.3,.12,.08,"253549",false)
 disc(model,cf*CFrame.new(0,.025,0),"ThinRim",radius*2,.055,.12,"72FFAC",true)
 disc(model,cf*CFrame.new(0,.065,0),"Inset",radius*2-.18,.04,.02,"172639",false)
 -- A thin rim and two guides use eight parts in total; no animated halo.
 for _,side in {-1,1} do
  local frame=cf*CFrame.new(0,.1,side*(radius+.12))
  piece(model,frame,"Guide",Vector3.new(.6,.045,.12),.12,"72FFAC",true)
 end
 disc(model,cf*CFrame.new(0,.105,0),"Badge",1.25,.04,.1,"32465C",false)
 piece(model,cf*CFrame.new(0,.15,0),"PurchasePlus",Vector3.new(.13,.045,.68),.04,"72FFAC",true)
 piece(model,cf*CFrame.new(0,.15,0),"PurchasePlus",Vector3.new(.68,.045,.13),.04,"72FFAC",true)
 local light=Instance.new("PointLight");light.Color=Color3.fromHex("72FFAC")
 light.Brightness=.28;light.Range=6;light.Shadows=false;light.Parent=anchor
 local reference=Instance.new("ObjectValue");reference.Name="Prompt";reference.Value=prompt;reference.Parent=model
 prompt.Style=Enum.ProximityPromptStyle.Default;prompt.UIOffset=Vector2.new(0,48)
 prompt.RequiresLineOfSight=false;prompt:SetAttribute("PurchaseCircle",true);prompt.ClickablePrompt=true
 model.Parent=parent;model:AddTag("VerityPurchasePad")
 return model
end
return Factory
