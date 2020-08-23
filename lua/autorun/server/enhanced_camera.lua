AddCSLuaFile("../client/enhanced_camera.lua")

local cvarHeightEnabled = CreateConVar("sv_ec_dynamicheight", "1",
                              {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
local cvarTrueCrouch =
    CreateConVar("sv_ec_truecrouch", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
local cvarHeightMin = CreateConVar("sv_ec_dynamicheight_min", "16", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
local cvarHeightMax = CreateConVar("sv_ec_dynamicheight_max", "64", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})

local function UpdateView(ply)
    if cvarHeightEnabled:GetBool() then
        -- Find the max and min height by spawning a dummy entity
        local height_max = 64
        local height_min = 16

        -- Finds model's height
        local entity = ents.Create("base_anim")
        local entity2 = ents.Create("base_anim")

        entity:SetModel(ply:GetModel())
        entity:ResetSequence(entity:LookupSequence("idle_all_01"))
        local bone = entity:LookupBone("ValveBiped.Bip01_Neck1")
        if bone then
            height_max = entity:GetBonePosition(bone).z + 5
        end

        -- Finds model's crouch height
        entity2:SetModel(ply:GetModel())
        entity2:ResetSequence(entity2:LookupSequence("cidle_all"))
        local bone2 = entity2:LookupBone("ValveBiped.Bip01_Neck1")
        if bone2 then
            height_min = entity2:GetBonePosition(bone2).z + 5
        end

        -- Removes test entities
        entity:Remove()
        entity2:Remove()
        print("[Enhanced Camera] ", height_max, " ", height_min)

        -- Update player height
        local min = cvarHeightMin:GetInt()
        local max = cvarHeightMax:GetInt()
        ply:SetViewOffset(Vector(0, 0, math.Clamp(height_max, min, max)))
        ply:SetViewOffsetDucked(Vector(0, 0, math.Clamp(height_min, min, max)))
        ply.ec_ViewChanged = true
    else
        if ply.ec_ViewChanged then
            ply:SetViewOffset(Vector(0, 0, 64))
            ply:SetViewOffsetDucked(Vector(0, 0, 28))
            ply.ec_ViewChanged = nil
        end
    end
end

local function UpdateTrueModel(ply)
    if ply:GetNWString("EnhancedCamera:TrueModel") ~= ply:GetModel() then
        ply:SetNWString("EnhancedCamera:TrueModel", ply:GetModel())
        UpdateView(ply)
    end
end

hook.Add("PlayerSpawn", "EnhancedCamera:PlayerSpawn", function(ply)
    UpdateTrueModel(ply)
end)

hook.Add("PlayerTick", "EnhancedCamera:PlayerTick", function(ply)
    UpdateTrueModel(ply)
end)

local function ConVarChanged(name, oldVal, newVal)
    for _, ply in pairs(player.GetAll()) do
        UpdateView(ply)
    end
end

cvars.AddChangeCallback("sv_ec_dynamicheight", ConVarChanged)
cvars.AddChangeCallback("sv_ec_dynamicheight_min", ConVarChanged)
cvars.AddChangeCallback("sv_ec_dynamicheight_max", ConVarChanged)
