--!strict
-- Full ceremony WAV is 5.03 s; its spawn layer starts at ~2.31 s.
local Spawn={Duration=5.03,Reveal=2.31,Join=3.05,MaxPieces=72}
local function smooth(t: number): number
 t=math.clamp(t,0,1);return t*t*(3-2*t)
end
function Spawn.Sample(age: number, reduced: boolean)
 local reveal=smooth((age-Spawn.Reveal)/.32)
 local opening=smooth((age-1.95)/.55)
 local tail=1-smooth((age-3.65)/(Spawn.Duration-3.65))
 local charge=smooth((age-.55)/1.7)*(1-smooth((age-Spawn.Reveal)/.65))
 return {
  cover=1-reveal, open=if reduced then (if age>=Spawn.Reveal then 1 else 0) else opening, charge=charge, tail=tail,
  shake=if reduced or age>=Spawn.Reveal then 0 else math.sin(age*(19+age*9))*(.025+.075*charge),
  join=smooth((age-Spawn.Join)/1.45),
  scale=if reduced then 1 else 1+.12*math.sin(math.pi*reveal)*(1-smooth((age-3.1)/.7)),
  burst=math.clamp((age-Spawn.Reveal)/1.8,0,1),
 }
end
return table.freeze(Spawn)
