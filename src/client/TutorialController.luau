--!nonstrict
local Tutorial={}
Tutorial.__index=Tutorial
local Steps={
	"1 / 6 • Your Verity is arriving! Find the delivery box near your home.",
	"2 / 6 • Open your delivery box using its world prompt.",
	"3 / 6 • Your flying Verity follows you and earns while you play. Your confirmed income is at the top.",
	"4 / 6 • Open PHONE to explore the Verity Feed.",
	"5 / 6 • Swipe up or press NEXT POST. Earn after the server confirms.",
	"6 / 6 • Open VERITY and buy your first level when you have enough Cash.",
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
