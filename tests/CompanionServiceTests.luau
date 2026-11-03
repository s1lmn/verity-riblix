-- Exercises actual service source through the small dependency injection loader.
return function(loadService)
    local function event()
        local handlers={}
        return {Connect=function(_,fn) handlers[#handlers+1]=fn;return {Disconnect=function() end} end,
            Fire=function(_,...) for _,fn in handlers do fn(...) end end}
    end
    local function fixture(studio)
        local pending={}
        local methods={}
        local function instance(class)
            return setmetatable({_class=class,_children={},_attrs={}}, {
                __index=function(self,k) if k=="Parent" then return rawget(self,"_parent") end return methods[k] end,
                __newindex=function(self,k,v)
                    if k=="Parent" then
                        local old=rawget(self,"_parent");if old then old._children[self.Name]=nil end
                        rawset(self,"_parent",v);if v then v._children[self.Name]=self end
                    else rawset(self,k,v) end
                end,
            })
        end
        function methods:IsA(class) return self._class==class end
        function methods:FindFirstChild(name) return self._children[name] end
        function methods:SetAttribute(name,v) self._attrs[name]=v end
        function methods:GetAttribute(name) return self._attrs[name] end
        function methods:Destroy() self.Parent=nil;self.dead=true end
        local players=instance("Players");players.PlayerRemoving=event();players.PlayerAdded=event()
        local storage=instance("ReplicatedStorage")
        storage.Shared={VerityCompanionConfig={}}
        function players:GetPlayers() return {} end
        local config={StudioPreview=true,Textures={Joy="uri",Love="uri",Playful="uri",Wink="uri",Laugh="uri",Surprise="uri",Confident="uri",Stars="uri"}}
        local services={Players=players,ReplicatedStorage=storage,RunService={IsServer=function() return true end,IsStudio=function() return studio end}}
        local service=loadService({GetService=function(_,name) return assert(services[name]) end},
            {new=instance},{delay=function(_,fn) pending[#pending+1]=fn end},function() return config end)
        local p=instance("Player");p.Name="Owner";p.UserId=123;p.Parent=players
        return service,p,storage,players,pending
    end
    local s,p,storage,players,pending=fixture(false)
    s.Initialize();assert(storage:FindFirstChild("VerityCompanions"),"Root must precede delayed unlock")
    local first=s.Attach(p);assert(s.Attach(p)==first,"Duplicate Attach")
    assert(first:GetAttribute("OwnerUserId")==123 and first:GetAttribute("Emotion")=="Joy")
    assert(s.SetEmotion(p,"Love",3));s.SetEmotion(p,"Playful",2)
    pending[1]();assert(first:GetAttribute("Emotion")=="Playful","Old timer overwrote newer reaction")
    pending[2]();assert(first:GetAttribute("Emotion")=="Joy")
    s.SetEmotion(p,"Stars");assert(first:GetAttribute("Emotion")=="Stars")
    for _,bad in {"Unknown",false,math.huge} do assert(not pcall(function() s.SetEmotion(p,bad) end)) end
    for _,bad in {-1,11,math.huge,0/0} do assert(not pcall(function() s.SetEmotion(p,"Joy",bad) end)) end
    s.SetEmotion(p,"Love",1);s.Detach(p);assert(first.dead)
    local second=s.Attach(p);s.SetEmotion(p,"Stars");pending[3]()
    assert(second:GetAttribute("Emotion")=="Stars","Detached timer affected new descriptor")
    players.PlayerRemoving:Fire(p);assert(second.dead)
    assert(s.SetEmotion(p,"Love")==false,"Detached owner accepted state update")
    s.StartStudioPreview();assert(not storage.VerityCompanions and not storage:FindFirstChild("VerityCompanions"):FindFirstChild("StudioEmotionRequest"))
    print("PASS companion ownership, idempotency, delayed unlock root, 8-emotion validation, timer races, removal, live preview guard")
end
