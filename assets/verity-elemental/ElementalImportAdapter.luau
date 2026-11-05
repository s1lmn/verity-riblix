--!nonstrict
-- Optional manual preparation AFTER Studio 3D import into the existing full game.
-- No startup, tags, timers, animations, remotes, or progression writes.
local RS=game:GetService("ReplicatedStorage")
local Face=require(RS.World.VerityFaceUI)
local Adapter={}
local Images={Joy="rbxassetid://80981300413243",Love="rbxassetid://101077299500859",Playful="rbxassetid://99399481880095",
 Wink="rbxassetid://119902996931782",Laugh="rbxassetid://114743070543492",Surprise="rbxassetid://134567600691675",
 Confident="rbxassetid://138239462151078",Stars="rbxassetid://79774909235274"}
local Targets={Aqua=10,Frost=25,Magma=50,Cyber=75,Cosmic=75,Rainbow=100}
Adapter.Emotions=table.freeze(Images)
function Adapter.Prepare(model,skin)
 assert(model:IsA("Model"),"Pass one imported Verity model")
 assert(Targets[skin],"Unknown elemental skin")
 local body=model:FindFirstChild("Body",true)
 assert(body and body:IsA("MeshPart"),"Imported model must contain Body MeshPart")
 for _,item in model:GetDescendants() do
  if item.Name=="FacePreview" then item:Destroy()
  elseif item:IsA("BasePart") then
   item.Anchored=true;item.CanCollide=false;item.CanTouch=false;item.CanQuery=false;item.CastShadow=false
  end
 end
 model.PrimaryPart=body
 body.Color=Color3.new(1,1,1);body.Reflectance=0;body:SetAttribute("VerityTint",false)
 local old=body:FindFirstChild("FaceGui");if old then old:Destroy() end
 local gui=Instance.new("SurfaceGui");gui.Name="FaceGui"
 local image=Instance.new("ImageLabel");image.Name="Expression";image.Image=Images.Joy;image.Parent=gui
 gui.Parent=body;Face.Configure(gui,body)
 -- Loading fallback is refreshed when either copy finishes loading, without a loop.
 local links={}
 for _,item in gui:GetDescendants() do
  if item:IsA("ImageLabel") then table.insert(links,item:GetPropertyChangedSignal("IsLoaded"):Connect(function()Face.Refresh(gui,0)end)) end
 end
 gui.Destroying:Once(function()for _,link in links do link:Disconnect()end end)
 model:SetAttribute("ElementalSkin",skin);model:SetAttribute("PreviewTargetLevel",Targets[skin])
 model:SetAttribute("ElementalApprovalOnly",true);model:SetAttribute("BaseDiameter",1.7)
 return model
end
function Adapter.SetEmotion(model,emotion)
 assert(Images[emotion],"Use one of the eight shared emotions")
 local body=assert(model:FindFirstChild("Body",true),"Body missing")
 local gui=assert(body:FindFirstChild("FaceGui"),"Call Prepare first")
 for _,item in gui:GetDescendants() do if item:IsA("ImageLabel") then item.Image=Images[emotion] end end
 Face.Refresh(gui,0)
end
return Adapter
