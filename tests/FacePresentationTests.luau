return function(load,check)
 local Layout=load("src/shared/VerityFaceLayout")
 local Face=load("src/world/VerityFaceUI")
 -- A downloaded 1024x512 image has its Joy pixels around (430..592,188..336).
 -- The old 768px crop missed them. Normalized placement must survive resizing.
 for _,width in {2048,1024,512,256} do
  local x,y=.5*width,.45*(width/2)
  check(x>=Layout.X*width and x<(Layout.X+Layout.Width)*width)
  check(y>=Layout.Y*(width/2) and y<(Layout.Y+Layout.Height)*(width/2))
 end
 local image={IsLoaded=false}
 local stroke={IsA=function(_,class) return class=="Frame" end}
 local fallback={GetChildren=function() return {stroke} end}
 local gui={FindFirstChild=function(_,name) return if name=="Expression" then image elseif name=="LoadingFace" then fallback else nil end}
 check(Face.Refresh(gui,0)==false and gui.Enabled and fallback.Visible,"Loading must show a face, not disable the GUI")
 image.IsLoaded=true
 check(Face.Refresh(gui,0)==true and gui.Enabled and not fallback.Visible,"Loaded art must replace fallback")
 Face.Refresh(gui,1)
 check(not gui.Enabled and image.ImageTransparency==1 and stroke.BackgroundTransparency==1,"Hidden companion leaked a floating face")
 image.IsLoaded=false
 check(Face.Refresh(gui,0)==false and fallback.Visible,"An unloaded replacement emotion must restore fallback")
end
