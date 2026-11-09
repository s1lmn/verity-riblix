--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local F=require(RS.Shared.WeatherForgeConfig)
local Service={};Service.__index=Service
function Service.new(model,data,state,players,clock,guid,notify)
 local self=setmetatable({model=model,data=data,state=state,players=players,clock=clock,guid=guid,notify=notify,links={},openAt={}},Service)
 self.remote=Instance.new("RemoteEvent");self.remote.Name="VerityWeatherForge";self.remote.Parent=RS
 table.insert(self.links,model.prompt.Triggered:Connect(function(p)
  if clock()<(self.openAt[p] or 0) then return end;self.openAt[p]=clock()+.5
  if self:Near(p.UserId) then self.remote:FireClient(p,{version=F.Version,kind="Open"}) end
 end))
 return self
end
function Service:Near(id)
 local p=self.players:GetPlayerByUserId(id);local profile=self.data:Get(id)
 local char=p and p.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not p or not profile or not self.state.sessions[id] or not profile.Data.VerityUnlocked or not root or not hum or hum.Health<=0 or hum.SeatPart or root.Anchored then return nil end
 for _,attr in {"VerityDiversionKind","VerityFusionSlot","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityRiding"} do if p:GetAttribute(attr) then return nil end end
 local distance=(root.Position-self.model.core.Position).Magnitude
 if distance~=distance or distance>F.Reach+1 then return nil end
 return p,profile
end
function Service:SeedLegacy(id)
 local profile=self.data:Get(id);if not profile or profile.Data.WeatherMaterialsSeeded then return end
 local d=profile.Data
 for _,entry in {{"home_ember_lantern","Ember",5},{"home_star_mobile","Stardust",5},{"home_rain_relic","RainPearl",3}} do
  if d.CosmeticsOwned[entry[1]] then d.WeatherMaterials[entry[2]]=math.min(F.MaxMaterial,(d.WeatherMaterials[entry[2]] or 0)+entry[3]) end
 end
 d.WeatherMaterialsSeeded=true;self.data:Touch(profile)
end
function Service:GrantHarvest(id,activity)
 local harvest=F.Harvest[activity];local profile=self.data:Get(id);if not harvest or not profile then return end
 self:SeedLegacy(id)
 for material,amount in harvest do profile.Data.WeatherMaterials[material]=math.min(F.MaxMaterial,(profile.Data.WeatherMaterials[material] or 0)+amount) end
 self.data:Touch(profile);self.state:Publish(id,true)
 local p=self.players:GetPlayerByUserId(id)
 if p then self.remote:FireClient(p,{version=F.Version,kind="Materials",activity=activity}) end
 self.notify(id,"FORGE_MATERIALS")
end
function Service:Craft(id,recipeId)
 local p,profile=self:Near(id);if not p then return "FORGE_TOO_FAR" end
 local recipe=F.Recipes[recipeId];if not recipe then return "INVALID_ITEM" end
 self:SeedLegacy(id)
 local d=profile.Data
 if d.CosmeticsOwned[recipe.Item] then return "ALREADY_OWNED" end
 for material,amount in recipe.Cost do if (d.WeatherMaterials[material] or 0)<amount then return "FORGE_NEED_MATERIALS" end end
 -- Non-yielding, idempotent through the existing RemoteService operationId journal.
 for material,amount in recipe.Cost do d.WeatherMaterials[material]-=amount end
 d.CosmeticsOwned[recipe.Item]=true
 if recipe.Type=="Look" then d.WeatherLook=recipe.Look
 elseif recipe.Type=="Cosmetic" then d.CosmeticsEquipped.Head=recipe.Item end
 self.data:Touch(profile)
 local eventId=self.guid();self.model.core:SetAttribute("ForgeRecipe",recipeId);self.model.core:SetAttribute("ForgeCastAt",self.clock())
 self.remote:FireClient(p,{version=F.Version,kind="Crafted",recipeId=recipeId,eventId=eventId})
 return "OK"
end
function Service:SelectLook(id,lookId)
 local profile=self.data:Get(id)
 if not profile or not self.state.sessions[id] then return "NOT_READY" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 if lookId~="Auto" and lookId~="Original" then
  local look=F.Looks[lookId];if not look then return "INVALID_ITEM" end
  if not profile.Data.CosmeticsOwned[look.Item] then return "NOT_OWNED" end
 end
 if profile.Data.WeatherLook~=lookId then profile.Data.WeatherLook=lookId;self.data:Touch(profile) end
 return "OK"
end
function Service:Remove(p) self.openAt[p]=nil end
function Service:Destroy()
 for _,link in self.links do link:Disconnect() end;self.remote:Destroy();table.clear(self.openAt)
end
return Service
