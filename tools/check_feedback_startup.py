"""Execute the real feedback module/constructor with fake engine services. No Studio."""
from pathlib import Path
import subprocess,sys,tempfile
root=Path(__file__).resolve().parents[1]
source=(root/'src/client/GameplayFeedbackController.luau').read_text()
cleanup=(root/'src/client/Cleanup.luau').read_text()
profile=(root/'src/shared/GameplayFeedbackProfile.luau').read_text()
harness='''
local objects={}
local connections={}
local function signal()
 local e={}
 function e:Connect(callback)
  local c={kind='connection',callback=callback}
  function c:Disconnect() self.disconnected=true end
  table.insert(connections,c);return c
 end
 return e
end
local Color3={fromHex=function(hex) return hex end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Enum={Material={Neon='Neon'}}
local Instance={new=function(kind)
 local o={kind='instance',ClassName=kind}
 function o:Destroy() self.destroyed=true;self.Parent=nil end
 table.insert(objects,o);return o
end}
local workspace={}
local player={Character=nil,CharacterRemoving=signal()}
local services={Players={LocalPlayer=player},RunService={RenderStepped=signal()},ReplicatedStorage={Shared={GameplayFeedbackProfile='profile'}}}
local game={GetService=function(_,name) return assert(services[name],name) end}
local script={Parent={Cleanup='cleanup'}}
local function typeof(o)
 if type(o)=='table' and o.kind=='instance' then return 'Instance' end
 if type(o)=='table' and o.kind=='connection' then return 'RBXScriptConnection' end
 return type(o)
end
local Cleanup=(function() CLEANUP_SOURCE end)()
local Profile=(function() PROFILE_SOURCE end)()
local require=function(key) return if key=='cleanup' then Cleanup elseif key=='profile' then Profile else error('unknown module') end
local exports=table.pack((function() FEEDBACK_SOURCE end)())
assert(exports.n==1 and type(exports[1])=='table','Feedback must return exactly one module table')
local Feedback=exports[1]
assert(type(Feedback.new)=='function','Feedback constructor missing')
local function bindable() return {Event=signal()} end
local ctx={net={StateChanged=bindable(),Notification=bindable(),World=bindable()},settings={values={ReducedMotion=false,ReducedEffects=false},Changed=bindable()},sound={IsCelebrating=function() return false end}}
local controller=Feedback.new(ctx)
assert(type(controller)=='table' and controller.folder.Parent==workspace)
assert(#controller.bursts==2)
assert(#objects==65,'bounded pool allocation changed')
assert(#connections==6,'event startup did not complete')
controller:Reset()
controller:Destroy()
for _,c in connections do assert(c.disconnected,'connection leaked') end
assert(controller.folder.destroyed,'temporary folder survived teardown')
print('Feedback startup: exactly one module export, real constructor, bounded pool, subscriptions, reset and teardown passed')
'''.replace('CLEANUP_SOURCE',cleanup).replace('PROFILE_SOURCE',profile).replace('FEEDBACK_SOURCE',source)
with tempfile.TemporaryDirectory(prefix='verity-feedback-startup-') as temp:
 p=Path(temp)/'startup.luau';p.write_text(harness)
 subprocess.run([sys.argv[1],str(p)],check=True)
