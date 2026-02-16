local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local Auto = syn and syn.queue_on_teleport or fluxus and fluxus.queue_on_teleport or queue_on_teleport
local inv = workspace:WaitForChild(LocalPlayer.Name.."SpawnedInToys", 5)

--[[
0: User
1: Mod
2: Admin
3: HeadAdmin
4: CoOwner
5: Overseer
6: Owner
]]--

local Owner = {"mirimirimirihyuk"}
local Overseer = {"reolisheee"}
local CoOwner = {"reolisheeee"}
local HeadAdmin = {""}
local Admin = {""}
local Mod = {""}

local function NormalizeName(name)
    return string.lower(tostring(name or ""))
end

local function GetRank(player)
    if not player then return 0 end
    local pName = NormalizeName(player.Name)

    local rankGroups = {Mod, Admin, HeadAdmin, CoOwner, Overseer, Owner}
    for i, list in ipairs(rankGroups) do
        for _, name in ipairs(list) do
            if pName == NormalizeName(name) then return i end
        end
    end
    return 0
end

local function GetRankName(rankId)
    local names = {"[ User ]", "[ Mod ]", "[ Admin ]", "[ HeadAdmin ]", "[ CoOwner ]", "[ Overseer ]", "[ Owner ]"}
    return names[rankId + 1] or "[ User ]"
end

local function ReplySmartWhisper(targetPlayer, messageContent)
    local myId = LocalPlayer.UserId
    local targetId = targetPlayer.UserId

    local smallId = (myId < targetId) and myId or targetId
    local bigId = (myId > targetId) and myId or targetId
    local whisperChannelName = "RBXWhisper:" .. smallId .. "_" .. bigId

    local textChannels = TextChatService:FindFirstChild("TextChannels")
    if not textChannels then return end

    local targetChannel = textChannels:FindFirstChild(whisperChannelName)

    if targetChannel then
        task.spawn(function()
            pcall(function() targetChannel:SendAsync(messageContent) end)
        end)
    else
        local generalChannel = textChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            pcall(function() 
                generalChannel:SendAsync("/w " .. targetPlayer.Name .. " " .. messageContent)
            end)
        end
    end
end

local function IsTargetMe(targetName)
    if not targetName then return false end
    targetName = targetName:lower()
    if targetName == "all" or targetName == "everyone" then return true end
    
    local myName = LocalPlayer.Name:lower()
    local myDisplay = LocalPlayer.DisplayName:lower()
    return myName:sub(1, #targetName) == targetName or myDisplay:sub(1, #targetName) == targetName
end

TextChatService.MessageReceived:Connect(function(textChatMessage)
    task.spawn(function()
        local success, err = pcall(function()
            local textSource = textChatMessage.TextSource
            if not textSource then return end

            local senderPlayer = Players:GetPlayerByUserId(textSource.UserId)
            if not senderPlayer or senderPlayer == LocalPlayer then return end

            local message = textChatMessage.Text
            if not message:match("^-") then return end

            local args = {}
            for arg in message:gmatch("%S+") do
                table.insert(args, arg)
            end

            if #args < 1 then return end

            local cmd = args[1]:lower()
            local targetArg = args[2]
            local valueArg = args[3]

            local senderRank = GetRank(senderPlayer)
            local myRank = GetRank(LocalPlayer)

            if cmd == "-ds" then
                local statusMsg = "FN - " .. GetRankName(myRank)
                ReplySmartWhisper(senderPlayer, statusMsg)
                return
            end

            if senderRank == 0 or myRank >= senderRank then return end

            if #args < 2 then return end

            if IsTargetMe(targetArg) then
                local char = LocalPlayer.Character
                if not char then return end

                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")

                if not humanoid or not hrp then return end

                if senderRank >= 1 then
                    local tf = tostring(valueArg or ""):lower()

                    if cmd == "-sit" and humanoid then
                        humanoid.Sit = (tf == "t" or tf == "true" or tf == "1")

                    elseif (cmd == "-ws" or cmd == "-walkspeed") and humanoid then
                        local speed = tonumber(valueArg)
                        if speed then humanoid.WalkSpeed = speed end

                    elseif (cmd == "-jp" or cmd == "-jumppower") and humanoid then
                        local jump = tonumber(valueArg)
                        if jump then humanoid.JumpPower = jump end

                    elseif (cmd == "-anchored" or cmd == "-freeze" or cmd == "-ice") and hrp then
                        hrp.Anchored = (tf == "t" or tf == "true" or tf == "1")

                    elseif (cmd == "-platformstand" or cmd == "-stun") and humanoid then
                        humanoid.PlatformStand = (tf == "t" or tf == "true" or tf == "1")

                    elseif (cmd == "-evaluatestateMachine" or cmd == "-state") and humanoid then
                        humanoid.EvaluateStateMachine = (tf == "t" or tf == "true" or tf == "1")
                    end
                end

                if senderRank >= 2 then
                    if cmd == "-ragdoll" and hrp then
                        local timeVal = tonumber(valueArg) or 1
                        pcall(function()
                            ReplicatedStorage.CharacterEvents.RagdollRemote:FireServer(hrp, timeVal)
                        end)

                    elseif cmd == "-bring" or cmd == "-tp" then
                        local sChar = senderPlayer.Character
                        local sHrp = sChar and (sChar:FindFirstChild("HumanoidRootPart") or sChar:FindFirstChild("Torso"))
                        if sHrp then hrp.CFrame = sHrp.CFrame end

                    elseif cmd == "-rj" or cmd == "-rejoin" then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)

                    elseif (cmd == "-autorj" or cmd == "-autorejoin") and Auto then
                        Auto([[game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)]])
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
heaven = false
                    elseif cmd == "-hell" and hrp then
                        heaven =  true
                        while heaven do
                        task.wait(0.4)
                        humanoid.EvaluateStateMachine = false
                        humanoid.PlatformStand = true
                        hrp.CFrame = CFrame.new(hrp.CFrame.X, 999999, hrp.CFrame.Z)
                        end

                    elseif cmd == "-human" and hrp then
                        heaven =  false
                        humanoid.EvaluateStateMachine = true
                        humanoid.PlatformStand = false
                        hrp.CFrame = CFrame.new(0,0,0)

                    elseif cmd == "-boom" or cmd == "-explode" or cmd == "-bomb" or cmd == "-Missile" or cmd == "-BombMissile" then
                        pcall(function()
                            ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("BombMissile", hrp.CFrame, Vector3.new(0,0,0))
                            task.wait(0.3)
                            if inv and inv:FindFirstChild("BombMissile") then
                                ReplicatedStorage.BombEvents.BombExplode:FireServer({
                                    Radius = 0, TimeLength = 0, Hitbox = inv.BombMissile.PartHitDetector, 
                                    ExplodesByFire = true, Model = inv.BombMissile, DestroysModel = true, 
                                    PositionPart = inv.BombMissile.PartHitDetector
                                }, Vector3.new(0, 0, 0))
                            end
                        end)
                    end
                end

                if senderRank >= 3 then
                    if (cmd == "-kill" or cmd == "-die" or cmd == "-oof" or cmd == "-death") and humanoid then
                        humanoid.Health = 0
                        humanoid:ChangeState(Enum.HumanoidStateType.Dead)

                    elseif cmd == "-permadeath" or cmd == "-infdeath" or cmd == "-sleep" then
                        hrp:Destroy()
                        pcall(function()
                            ReplicatedStorage.CharacterEvents.RagdollRemote:FireServer(hrp, 3)
                        end)
                        task.wawit(0.2)
                        humanoid.Health = 0
                        humanoid:ChangeState(Enum.HumanoidStateType.Dead)

                    elseif cmd == "-ckick" or cmd == "-clientkick" then
                        LocalPlayer:Kick("by " .. senderPlayer.Name)

                    elseif (cmd == "-skick" or cmd == "-serverkick") and hrp then
                        hrp.CFrame = CFrame.new(999999, 999999, 999999)
                        task.wait(0.1)
                        char:Destroy()
                        while true do end
                    end
                end
            end
        end)

        if not success then
            warn("Command Execution Error: " .. tostring(err))
        end
    end)
end)
