-- Explicit texture swap only. Upload the eight PNGs once and pass their real URIs.
local allowed = { Joy=true, Love=true, Playful=true, Wink=true, Laugh=true,
    Surprise=true, Confident=true, Stars=true }
return function(mesh, emotion, textureIds)
    assert(mesh:IsA("MeshPart"), "Pass the imported MeshPart")
    assert(allowed[emotion], "Unknown Verity emotion")
    local uri = textureIds[emotion]
    assert(type(uri) == "string" and string.match(uri, "^rbxassetid://%d+$"),
        "Upload this expression PNG and configure its real Roblox asset URI")
    local surface = mesh:FindFirstChildOfClass("SurfaceAppearance")
    if surface then
        surface.ColorMap = uri
    else
        mesh.TextureID = uri
    end
    mesh:SetAttribute("CurrentEmotion", emotion)
end
