local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local TextChatService = game:GetService('TextChatService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local LocalEntity = Players.LocalPlayer
local GuiLibrary = shared.GuiLibrary
local EntityLib = loadfile('Novoline/libraries/Entity.lua')()

local BedFight = {
    Combat = {
        Sword = ReplicatedStorage.ToolHandlers.Sword,
        SwordHit = ReplicatedStorage.Remotes.ItemsRemotes.SwordHit,
        EquipTool = ReplicatedStorage.Remotes.ItemsRemotes.EquipTool,
        VelocityHandler = ReplicatedStorage.Modules.VelocityUtils,
    },
    ClientEvents = {
        KillLog = ReplicatedStorage.Remotes.KillLog,
    },
    DropItem = ReplicatedStorage.Remotes.ItemsRemotes.DropItem,
}

local Inventory = {
    getItem = function(self, Item: string)
        for _ ,v in LocalEntity.Backpack:GetChildren() and LocalEntity.Character:GetChildren() do
            if v.Name:lower():find(Item:lower()) then
                return v
            end
        end
    end
}

local Combat = GuiLibrary:GetWindow("Combat")
local Movement = GuiLibrary:GetWindow("Movement")
local Visuals = GuiLibrary:GetWindow("Visuals")
local Utility = GuiLibrary:GetWindow("Utility")

local SwingSoundInst = Instance.new('Sound')
SwingSoundInst.Parent = workspace
SwingSoundInst.SoundId = 'rbxassetid://104766549106531'
local SwingSwordID = Instance.new('Animation')
SwingSwordID.AnimationId = 'rbxassetid://123800159244236'
local SwingSwordInst = LocalEntity.Character.Humanoid.Animator:LoadAnimation(SwingSwordID)

LocalEntity.CharacterAdded:Connect(function(character)
    task.delay(1, function()
        SwingSwordInst = LocalEntity.Character.Humanoid.Animator:LoadAnimation(SwingSwordID)
    end)
end)

EntityLib.getNearestEntity = function(Range: number)
    local Dist, User = math.huge, nil

    for i,v in Players:GetPlayers() do
        if v == LocalEntity then
            continue
        end

        local canHit = true

        if LocalEntity:GetAttribute('PVP') and v:GetAttribute('PVP') then
            canHit = true
        end

        if v.Team == LocalEntity.Team then
            canHit = false
        end

        if LocalEntity.Team == game.Teams.Spectators and LocalEntity:GetAttribute('PVP') and v:GetAttribute('PVP') then
            canHit = true
        end

        if not EntityLib.isAlive(v) or not canHit then continue end
        if not v.Character or not v.Character.PrimaryPart then continue end

        local Distance = Players.LocalPlayer:DistanceFromCharacter(v.Character.PrimaryPart.Position)

        if Distance <= Range and Distance < Dist then
            Dist = Distance
            User = v
        end
    end

    return User
end

local function worldCFrameToC0ObjectSpace(motor6DJoint,worldCFrame)
	local part1CF = motor6DJoint.Part1.CFrame
	local c1Store = motor6DJoint.C1
	local c0Store = motor6DJoint.C0
	local relativeToPart1 =c0Store*c1Store:Inverse()*part1CF:Inverse()*worldCFrame*c1Store
	relativeToPart1 -= relativeToPart1.Position
	
	local goalC0CFrame = relativeToPart1+c0Store.Position--New orientation but keep old C0 joint position
	return goalC0CFrame
end

local oldC0 = LocalEntity.Character.Head.Neck.C0

local lastHit = tick()
KillAura = Combat:CreateModule({
    ['Name'] = 'KillAura',
    ['Function'] = function(callback)
        if callback then
            KillAura:Start(function()
                if EntityLib.isAlive(LocalEntity) then
                    local Entity = EntityLib.getNearestEntity(KARange.Value)
                    local Weapon = Inventory:getItem('sword')

                    if Entity then
                        if TargetHud.Enabled then
                            GuiLibrary.TargetHud:AddTarget(Entity)
                        end

                        if AutoSwitch.Enabled and Weapon then
                            BedFight.Combat.EquipTool:FireServer(Weapon.Name)
                        end

                        if Rotations.Enabled then
                            local targetthing = Vector3.new(Entity.Character.PrimaryPart.CFrame.Position:Lerp(Entity.Character.PrimaryPart.CFrame.Position, 0.3).X, LocalEntity.Character.PrimaryPart.CFrame.Position.Y, Entity.Character.PrimaryPart.CFrame.Position:Lerp(Entity.Character.PrimaryPart.CFrame.Position, 0.3).Z)
                            local rot1 = CFrame.lookAt(LocalEntity.Character.PrimaryPart.CFrame.Position, Entity.Character.PrimaryPart)
                            local rot2 = CFrame.lookAt(LocalEntity.Character.PrimaryPart.CFrame.Position, targetthing)
                                    
                            local pos = CFrame.lookAt(LocalEntity.Character.PrimaryPart.Position, Vector3.new(Entity.Character.PrimaryPart.Position.X, LocalEntity.Character.PrimaryPart.Position.Y, Entity.Character.PrimaryPart.Position.Z))
                            LocalEntity.Character.PrimaryPart.CFrame = rot2
                            LocalEntity.Character.Head.Neck.C0 = rot1
                        else
                            LocalEntity.Character.Head.Neck.C0 = oldC0
                        end

                        if Weapon then
                            BedFight.Combat.SwordHit:FireServer(Entity.Character, Weapon.Name)
                        end
                        
                        local hDelay = 0.01
                        if AttackSpeed.Value == 'Respect Delay' then
                            hDelay = 0.11112
                        elseif AttackSpeed.Value == 'Timed Hits' then
                            hDelay = 0.3
                        end

                        if (tick() - lastHit) < hDelay then
                            return
                        end

                        if SwingSword.Enabled then
                            SwingSwordInst:Play()
                        end
                        if SwingSound.Enabled then
                            SwingSoundInst:Play()
                        end

                        lastHit = tick()
                    else
                        GuiLibrary.TargetHud:ClearTargets()
                        LocalEntity.Character.Head.Neck.C0 = oldC0
                    end
                end
            end)
        else
            LocalEntity.Character.Head.Neck.C0 = oldC0
        end
    end
})
KARange = KillAura.CreateSlider({
    ['Name'] = 'Range',
    ['Minimum'] = 0,
    ['Maximum'] = 18,
    ['Default'] = 18,
})
TargetHud = KillAura.CreateToggle({
    ['Name'] = 'Target HUD'
})
AutoSwitch = KillAura.CreateToggle({
    ['Name'] = 'Auto Switch'
})
Rotations = KillAura.CreateToggle({
    ['Name'] = 'Rotations'
})
SwingSword = KillAura.CreateToggle({
    ['Name'] = 'Swing Sword'
})
SwingSound = KillAura.CreateToggle({
    ['Name'] = 'Swing Sound'
})
AttackSpeed = KillAura.CreatePicker({
    ['Name'] = 'Attack Speed',
    ['Options'] = {'No Delay', 'Respect Delay', 'Timed Hits'}
})

--[[ patched rn bruh im too lazy to find new method

local AKBConn
AntiKB = Combat:CreateModule({
    ['Name'] = 'AntiKB',
    ['Function'] = function(callback)
        if callback then
            for _, v in BedFight.Combat.VelocityHandler:GetChildren() do
                v:Destroy()
            end
            AKBConn = BedFight.Combat.VelocityHandler.ChildAdded:Connect(function(v)
                v:Destroy()
            end)
        else
            AKBConn:Disconnect()
        end
    end
})]]

Speed = Movement:CreateModule({
    ['Name'] = 'Speed',
    ['Function'] = function(callback)
        if callback then
            local boostDir, lastBoost = 0, tick()
            Speed:Start(function(deltaTime: number)
                if EntityLib.isAlive(LocalEntity) then
                    local MoveDir = LocalEntity.Character.Humanoid.MoveDirection
                    local SpeedExp = (SpeedAmount.Value - LocalEntity.Character.Humanoid.WalkSpeed)

                    if (tick() - lastBoost) > 1.1 then
                        boostDir = 30
                        lastBoost = tick()
                    end

                    if boostDir > 4 then
                        boostDir -= (45 * deltaTime)
                    end

                    LocalEntity.Character.Humanoid.WalkSpeed = 16
                    if SpeedMode.Value == 'CFrame' then
                       LocalEntity.Character.PrimaryPart.CFrame += (MoveDir * SpeedExp * deltaTime)
                    elseif SpeedMode.Value == 'WalkSpeed' then
                        LocalEntity.Character.Humanoid.WalkSpeed = SpeedAmount.Value
                    elseif SpeedMode.Value == 'BedFight' then
                        LocalEntity.Character.PrimaryPart.CFrame += (MoveDir * boostDir * deltaTime)
                    end
                end
            end)
        end
    end
})
SpeedMode = Speed.CreatePicker({
    ['Name'] = 'Mode',
    ['Options'] = {'CFrame', 'WalkSpeed', 'BedFight'}
})
SpeedAmount = Speed.CreateSlider({
    ['Name'] = 'Value',
    ['Minimum'] = 0,
    ['Maximum'] = 35,
    ['Default'] = 35,
})

Flight = Movement:CreateModule({
    ['Name'] = 'Flight',
    ['Function'] = function(callback)
        if callback then
            Flight:Start(function(deltaTime: number)
                if EntityLib.isAlive(LocalEntity) then
                    local Velocity = LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity
                    local ExpY = 0.8 + deltaTime

                    if Vertical.Enabled then
                        if UserInputService:IsKeyDown('Space') then
                            ExpY += 44
                        elseif UserInputService:IsKeyDown('LeftShift') then
                            ExpY -= 44
                        end
                    end

                    LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(Velocity.X, ExpY, Velocity.Z)
                end
            end)
        end
    end
})
Vertical = Flight.CreateToggle({
    ['Name'] = 'Vertical',
})

local spidering = false
Longjump = Movement:CreateModule({
    ['Name'] = 'Longjump',
    ['Function'] = function(callback)
        if callback then
            local startY = 26

            Longjump:Start(function(deltaTime: number)
                if EntityLib.isAlive(LocalEntity) then
                    local Velocity = LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity
                    startY -= (35 * deltaTime)

                    if spidering then
                        return
                    end

                    LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(Velocity.X, startY, Velocity.Z)
                end
            end)
        end
    end
})

NoFall = Utility:CreateModule({
    ['Name'] = 'NoFall',
    ['Function'] = function(callback)
        if callback then
            local startY = 0
            NoFall:Start(function(deltaTime: number)
                if EntityLib.isAlive(LocalEntity) then
                    local Velocity = LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity
                    if Velocity.Y < -44 then
                        LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(Velocity.X, -45, Velocity.Z)
                        LocalEntity.Character.PrimaryPart.CFrame -= Vector3.new(0, startY * deltaTime, 0)

                        startY += (workspace.Gravity * deltaTime)
                    else
                        startY = 0
                    end
                end
            end)
        end
    end
})

local Blacklist = RaycastParams.new()
Blacklist.FilterType = Enum.RaycastFilterType.Exclude
Blacklist.FilterDescendantsInstances = {workspace.PlayersContainer:GetChildren(), workspace.DroppedItemsContainer:GetChildren(), workspace.BedsContainer}

Spider = Movement:CreateModule({
    ['Name'] = 'Spider',
    ['Function'] = function(callback)
        if callback then
            Spider:Start(function()
                if EntityLib.isAlive(LocalEntity) then
                    local Thingy = workspace:Raycast(LocalEntity.Character.PrimaryPart.Position, LocalEntity.Character.Head.CFrame.LookVector * 1)
                    local Velocity = LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity

                    if Thingy and UserInputService:IsKeyDown('W') then
                        spidering = true
                        LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(Velocity.X, 50, Velocity.Z)
                    else
                        spidering = false
                    end
                end
            end)
        end
    end
})

local aids = {}
FastDrop = Utility:CreateModule({
    ['Name'] = 'FastDrop',
    ['Function'] = function(callback)
        if callback then
            local IsDropping = false
            table.insert(aids, UserInputService.InputBegan:Connect(function(Key, Gpe)
                if not Gpe and Key.KeyCode == Enum.KeyCode.Q then
                    IsDropping = true
                end
            end))
            table.insert(aids, UserInputService.InputEnded:Connect(function(Key, Gpe)
                if not Gpe and Key.KeyCode == Enum.KeyCode.Q then
                    IsDropping = false
                end
            end))

            FastDrop:Start(function()
                if EntityLib.isAlive(LocalEntity) then
                    local ItemToDrop = Inventory:getItem('iron') or Inventory:getItem('diamond') or Inventory:getItem('emerald')

                    if IsDropping and ItemToDrop then
                        BedFight.DropItem:FireServer(ItemToDrop.Name, 'Single')
                    end
                end
            end)
        end
    end
})

local ATStrings = {
    Kill = {
        'get good get autumn PLR',
        'when life gives you lemons, get autumn PLR',
        'ez PLR | autumn on top'
    }
}

local function getPlayerFromName(Name: string)
    for i,v in Players:GetPlayers() do
        if v.Name:lower():find(Name:lower()) or v.DisplayName:lower():find(Name:lower()) then
            return v
        end
    end
end

local aitems = {}
AutoToxic = Utility:CreateModule({
    ['Name'] = 'AutoToxic',
    ['Function'] = function(callback)
        if not callback then
            for i,v in aitems do
                v:Disconnect()
            end
        end
    end
})

task.delay(0.1, function()
    GuiLibrary.SessionInfo:AddItem('Beds')
    task.wait(0.01)
    GuiLibrary.SessionInfo:AddItem('Wins')
    task.wait(0.01)
    GuiLibrary.SessionInfo:AddItem('Kills')

    table.insert(aitems, LocalEntity.Stats["Total Beds Broken"]:GetPropertyChangedSignal('Value'):Connect(function()
        GuiLibrary.SessionInfo:IncreaseItem('Beds', 1)
    end))

    table.insert(aitems, LocalEntity.Stats.Wins:GetPropertyChangedSignal('Value'):Connect(function()
        GuiLibrary.SessionInfo:IncreaseItem('Wins', 1)
    end))

    table.insert(aitems, BedFight.ClientEvents.KillLog.OnClientEvent:Connect(function(p1: string, p2: string)
        if not p1 or not p2 then
            return
        end

        local user = getPlayerFromName(p2)

        if p1 == LocalEntity.Name then
            GuiLibrary.SessionInfo:IncreaseItem('Kills', 1)
        end

        if p1 == LocalEntity.Name and user.leaderstats.Bed.Value ~= '✅' then
            local String = ATStrings.Kill[math.random(1, #ATStrings.Kill)]:gsub('PLR', p2)

            if AutoToxic.Enabled then
                TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(String)
            end
        end
    end))

end)
