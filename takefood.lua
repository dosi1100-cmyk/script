--[[
    Script Version: v2.0
    Description: Instant Grab (Heartbeat Spam & Zero Delay)
    Target Executor: Volt (and standard executors)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- [상수] 좌표값
local VoidCFrame = CFrame.new(0, -30000, 0)
local ZeroVector = Vector3.new(0, 0, 0)

-- 캐릭터 리스폰 시 갱신
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

-- [화이트리스트]
local MySpawnFolderName = LocalPlayer.Name .. "SpawnedInToys"

-- 감지할 아이템 리스트
local TargetItems = {
    ["InstrumentBrassBugle"] = true, ["InstrumentBrassTrumpet"] = true, ["InstrumentBrassVuvuzela"] = true,
    ["InstrumentDrumBongos"] = true, ["InstrumentDrumSnare"] = true, ["InstrumentGuitarAcoustic"] = true,
    ["InstrumentGuitarBanjo"] = true, ["InstrumentGuitarLyre"] = true, ["InstrumentGuitarUkulele"] = true,
    ["InstrumentGuitarViolin"] = true, ["InstrumentPianoKeyboard"] = true, ["InstrumentPianoMelodica"] = true,
    ["InstrumentVoiceMicrophone"] = true, ["InstrumentWoodwindOcarina"] = true, ["InstrumentWoodwindSaxophone"] = true,
    ["PoopPileSparkle"] = true, ["PoopPile"] = true, ["FoodSodaCan"] = true, ["FoodPizzaPepperoni"] = true,
    ["FoodPizzaCheese"] = true, ["FoodMushroomPoison"] = true, ["FoodMeatStick"] = true, ["FoodMayonnaise"] = true,
    ["FoodHotdog"] = true, ["FoodHamburger"] = true, ["FoodFrenchFries"] = true, ["FoodDonut"] = true,
    ["FoodDippyEgg"] = true, ["FoodCoconut"] = true, ["FoodCakePink"] = true, ["FoodBroccoli"] = true,
    ["FoodBread"] = true, ["FoodBanana"] = true, ["CupMugWhite"] = true, ["CupMugBrown"] = true
}

-- [중복 실행 방지]
local ActiveTargets = {}

-- [초고속 제거 함수] Heartbeat를 이용한 프레임 단위 실행
local function AggressiveRemove(item)
    if not item then return end
    
    -- 1. 중복 체크
    if ActiveTargets[item] then return end

    -- 2. 이름 체크
    if not TargetItems[item.Name] then return end

    -- 3. 화이트리스트 체크 (이미 내꺼면 무시)
    if item:IsDescendantOf(Workspace) then
        local myFolder = Workspace:FindFirstChild(MySpawnFolderName)
        if myFolder and item:IsDescendantOf(myFolder) then
            return
        end
    end

    ActiveTargets[item] = true

    -- 비동기 처리 시작
    task.spawn(function()
        -- 리모트가 로딩될 때까지 아주 짧게 대기 (최대 3초)
        local holdPart = item:WaitForChild("HoldPart", 3)
        if not holdPart then 
            ActiveTargets[item] = nil 
            return 
        end
        
        local holdRemote = holdPart:WaitForChild("HoldItemRemoteFunction", 3)
        local dropRemote = holdPart:WaitForChild("DropItemRemoteFunction", 3)

        if holdRemote and dropRemote then
            -- [핵심 변경] Heartbeat에 연결하여 딜레이 0초로 무한 난사
            -- wait()를 쓰지 않고 게임 프레임마다 실행됨 (가장 빠른 속도)
            local connection
            connection = RunService.Heartbeat:Connect(function()
                -- 아이템이 사라지거나 내 폴더로 들어오면 연결 해제
                if not item or not item.Parent or not item:IsDescendantOf(Workspace) then
                    if connection then connection:Disconnect() end
                    ActiveTargets[item] = nil
                    return
                end

                local myFolder = Workspace:FindFirstChild(MySpawnFolderName)
                if myFolder and item:IsDescendantOf(myFolder) then
                    if connection then connection:Disconnect() end
                    ActiveTargets[item] = nil
                    return
                end

                -- 병렬로 잡기 요청 전송
                task.spawn(function()
                    pcall(function() holdRemote:InvokeServer(item, Character) end)
                end)
                
                task.spawn(function()
                    pcall(function() dropRemote:InvokeServer(item, VoidCFrame, ZeroVector) end)
                end)
            end)
        else
            ActiveTargets[item] = nil
        end
    end)
end

-- [깊은 감시 연결 함수]
local function AttachDeepWatch(folder)
    if folder then
        for _, descendant in pairs(folder:GetDescendants()) do
            AggressiveRemove(descendant)
        end
        folder.DescendantAdded:Connect(AggressiveRemove)
    end
end

-- 폴더 감시 시작
local foodFolder = Workspace:FindFirstChild("Food")
if foodFolder then AttachDeepWatch(foodFolder) end

local plotFolder = Workspace:FindFirstChild("PlotItems")
if plotFolder then AttachDeepWatch(plotFolder) end

-- 다른 플레이어 폴더 감시
local function CheckAndAttach(child)
    if child:IsA("Folder") or child:IsA("Model") then
        if string.match(child.Name, "SpawnedInToys$") and child.Name ~= MySpawnFolderName then
            AttachDeepWatch(child)
        end
    end
end

for _, child in pairs(Workspace:GetChildren()) do
    CheckAndAttach(child)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Food" or child.Name == "PlotItems" then
        AttachDeepWatch(child)
    else
        CheckAndAttach(child)
    end
end)

-- [지속적 경로 스캔] (놓친 아이템 재확인)
task.spawn(function()
    while true do
        if foodFolder then
            for _, item in pairs(foodFolder:GetDescendants()) do
                if TargetItems[item.Name] and not ActiveTargets[item] then
                    AggressiveRemove(item)
                end
            end
        end
        if plotFolder then
            for _, item in pairs(plotFolder:GetDescendants()) do
                if TargetItems[item.Name] and not ActiveTargets[item] then
                    AggressiveRemove(item)
                end
            end
        end
        for _, child in pairs(Workspace:GetChildren()) do
            if string.match(child.Name, "SpawnedInToys$") and child.Name ~= MySpawnFolderName then
                for _, item in pairs(child:GetDescendants()) do
                    if TargetItems[item.Name] and not ActiveTargets[item] then
                        AggressiveRemove(item)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)


print("음식 뺏어가기 활성화됨")
