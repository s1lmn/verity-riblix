--!nonstrict
local Tutorial={}
Tutorial.__index=Tutorial
local Steps={
 "1/6 · Your delivery is on its way",
 "2/6 · E: open your delivery box",
 "3/6 · Verity follows you & earns Cash",
 "4/6 · Open PHONE",
 "5/6 · Swipe up to earn Cash",
 "6/6 · VERITY: buy your first level",
}

function Tutorial.new(ctx) return setmetatable({ctx=ctx},Tutorial) end
function Tutorial:Render()
	local ctx=self.ctx
	local state=ctx.net.state
	ctx.refs.Tutorial.Visible=state~=nil and not state.TutorialCompleted and state.TutorialStep~=nil and ctx.active==nil
	if not state then return end
	ctx.refs.TutorialText.Text=Steps[state.TutorialStep] or "Keep growing your Verity!"
	-- Server owns advancement and persistence. No local step skipping.
	for name,button in ctx.refs.Nav do
		local highlighted=(name=="PHONE" and (state.TutorialStep==4 or state.TutorialStep==5)) or (name=="VERITY" and state.TutorialStep==6)
		local stroke=button:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Transparency=if highlighted then 0.15 else 0.88;stroke.Thickness=if highlighted then 3 else 2 end
	end
end
function Tutorial:Destroy() end
return Tutorial
