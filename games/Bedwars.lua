local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')
local TextChatService = game:GetService('TextChatService')
local UserInputService = game:GetService('UserInputService')
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local LocalEntity = Players.LocalPlayer
local GuiLibrary = shared.GuiLibrary
local EntityLib = loadfile('Novoline/libraries/Entity.lua')()

local Combat = GuiLibrary:GetWindow('Combat')
local Player = GuiLibrary:GetWindow('Player')
local Movement = GuiLibrary:GetWindow('Movement')
local Visuals = GuiLibrary:GetWindow('Visuals')
local Utility = GuiLibrary:GetWindow('Utility')
local Exploit = GuiLibrary:GetWindow('Exploit')

-- this is absolutely terrible im gonna fix it when I get home.
if not LocalEntity.Character then
    LocalEntity.CharacterAdded:Wait()
    repeat task.wait() until workspace.CurrentCamera ~= nil
    local parts = 0
    LocalEntity.Character.ChildAdded:Connect(function(child)
        parts += 1
    end)

    repeat task.wait() until parts > 8
end

local NetManaged = ReplicatedStorage:WaitForChild('rbxts_include').node_modules["@easy-games"]["block-engine"].node_modules["@rbxts"].net.out._NetManaged

local f = {}
local function getRemotes()
    for i,v in NetManaged:GetChildren() do
        table.insert(f, v)
    end
    for i,v in ReplicatedStorage:WaitForChild('rbxts_include').node_modules["@rbxts"].net.out._NetManaged:GetChildren() do
        table.insert(f, v)
    end
    for i,v in ReplicatedStorage['events-@easy-games/game-core:shared/game-core-networking@getEvents.Events']:GetChildren() do
        table.insert(f, v)
    end

    return f
end

local Remotes = getRemotes()
local function getRemote(Name: string, Type: string) -- this is just so peak right
    for i,v in Remotes do
        if v.Name:lower():find(Name:lower()) then
            if Type and not v:IsA(Type) then
                continue
            end

            if v:IsA('RemoteEvent') then
                return {
                    inst = v,
                    SendToServer = function(self, ...)
                        v:FireServer(...)
                    end,
                    OnClientEvent = function(self, func)
                        v.OnClientEvent:Connect(func)
                    end
                }
            elseif v:IsA('RemoteFunction') then
                return {
                    inst = v,
                    CallServerAsync = function(self, ...)
                        local funny = v:InvokeServer(...)

                        return {
                            andThen = function(self, func)
                                func(funny)
                            end
                        }
                    end
                }
            end
        end
    end

    return Instance.new('RemoteEvent')
end

local Bedwars = {
    Remotes = {
        GroundHit = getRemote('GroundHit'),
        SwordHit = getRemote('SwordHit'),
        DropItem = getRemote('DropItem'),
        SetInvItem = getRemote('SetInvItem'),
        PlaceBlock = getRemote('PlaceBlock', 'RemoteFunction'),
        DamageBlock = getRemote('DamageBlock'),
        ConsumeItem = getRemote('ConsumeItem'),
        PickupItemDrop = getRemote('PickupItemDrop'),
        StepOnSnapTrap = getRemote('StepOnSnapTrap'),
        ChestGetItem = getRemote('Inventory/ChestGetItem'),
        SetObservedChest = getRemote('Inventory/SetObservedChest'),
        TriggerInvisibleLandmine = getRemote('TriggerInvisibleLandmine'),
        
    },
    Events = {
        EntityDeathEvent = getRemote('EntityDeathEvent'),
    },
    Animations = loadfile('Novoline/libraries/Animations.lua')(),
    Index = {
        Pickaxes = {
            wood_pickaxe = {Damage = 1},
            stone_pickaxe = {Damage = 2},
            iron_pickaxe = {Damage = 3},
            diamond_pickaxe = {Damage = 4},
        },
        Axes = {
            wood_axe = {Damage = 1},
            stone_axe = {Damage = 2},
            iron_axe = {Damage = 3},
            diamond_axe = {Damage = 4},
        },
        Blocks = {
            wool = {Priority = 1},
            plank = {Priority = 2},
            stone = {Priority = 3},
            blastproof = {Priority = 4},
        }
    }
}

local Chests = {}

task.delay(2, function()
    for i,v in workspace:GetChildren() do
        if v.name == 'chest' then
            table.insert(Chests, v)
        end
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == 'chest' then
        table.insert(Chests, child)
    end
end)

local function getItem(Name: string)
    for i,v in ReplicatedStorage.Inventories[LocalEntity.Name]:GetChildren() do
        if v.Name:lower():find(Name:lower()) then
            return {
                itemType = v,
                name = v.Name,
            }
        end
    end

    return nil
end

local function switchItem(Name: string)
    local Item = getItem(Name).itemType

    if not Item then
        return
    end

    return Bedwars.Remotes.SetInvItem:CallServerAsync({hand = Item})
end

local function getPlaceableBlock()
    local Block, Max = nil, 0

    for i,v in Bedwars.Index.Blocks do
        if getItem(i) and Max < v.Priority then
            Block = getItem(i)
            Max = v.Priority
        end
    end

    return Block
end

local function hasAxe()
    for i,v in Bedwars.Index.Axes do
        if getItem(i) then
            return true
        end
    end
    return false
end

local function getBestAxe()
    local Tool, Damage = nil, 0

    for i,v in Bedwars.Index.Axes do
        if getItem(i) and v.Damage > Damage then
            Tool = getItem(i).itemType
            Damage = v.Damage
        end
    end

    return Tool
end

local function getBestPickaxe()
    local Tool, Damage = nil, 0

    for i,v in Bedwars.Index.Pickaxes do
        if getItem(i) and v.Damage > Damage then
            Tool = getItem(i).itemType
            Damage = v.Damage
        end
    end

    return Tool
end

local function getFixedPosition(Pos: Vector3)
    return Vector3.new(math.round(Pos.X / 3), math.round(Pos.Y / 3), math.round(Pos.Z / 3))
end

EntityLib.getNearestEntity = function(Range: number)
    local Dist, User, EType = math.huge, nil, 'None'

    if not EntityLib.isAlive(LocalEntity) then
        return User
    end

    if AttackOtherEntities.Enabled or false then
        for _, v in CollectionService:GetTagged('DiamondGuardian') do
            if not v.PrimaryPart then continue end

            local Distance = LocalEntity:DistanceFromCharacter(v.PrimaryPart.CFrame.Position)

            if Distance <= Range and Distance < Dist then
                Dist = Distance
                User = v
                EType = 'Extra_Entity'
            end
        end

        for _, v in CollectionService:GetTagged('GolemBoss') do
            local Distance = LocalEntity:DistanceFromCharacter(v.PrimaryPart.CFrame.Position)

            if not v.PrimaryPart then continue end

            if Distance <= Range and Distance < Dist then
                Dist = Distance
                User = v
                EType = 'Extra_Entity'
            end
        end
    end

    for _, v in Players:GetPlayers() do
        if v == LocalEntity or v.Team == LocalEntity.Team then continue end
        if not EntityLib.isAlive(v) then continue end
        if not v.Character or not v.Character.PrimaryPart then continue end

        local Distance = LocalEntity:DistanceFromCharacter(v.Character.PrimaryPart.Position)

        if Distance <= Range and Distance < Dist then
            Dist = Distance
            User = v
            EType = 'Player'
        end
    end

    return User, EType, Dist
end

function getcloserpos(pos1, pos2, amount)
	local newPos = (pos2 - pos1).Unit * math.min(amount, (pos2 - pos1).Magnitude) + pos1
	return newPos
end

local function getLowestPartOfMap()
    local lowestPartPosY = math.huge

    for i,v in workspace:GetDescendants() do
        if v:IsA('Part') then
            if v.CFrame.Position.Y < lowestPartPosY and v.CanCollide and v.Transparency ~= 1 then
                lowestPartPosY = v.CFrame.Position.Y
            end
        end
    end

    return lowestPartPosY
end

-- thank you dev forums
local function worldCFrameToC0ObjectSpace(motor6DJoint,worldCFrame)
	local part1CF = motor6DJoint.Part1.CFrame
	local c1Store = motor6DJoint.C1
	local c0Store = motor6DJoint.C0
	local relativeToPart1 =c0Store*c1Store:Inverse()*part1CF:Inverse()*worldCFrame*c1Store
	relativeToPart1 -= relativeToPart1.Position
	
	local goalC0CFrame = relativeToPart1+c0Store.Position--New orientation but keep old C0 joint position
	return goalC0CFrame
end

local lastThingy = Vector3.zero
local oldC0 = LocalEntity.Character.Head.Neck.C0
local function attackEntity(Entity: any, Sword: any, EType: string, Dist: number)
    if EType == 'None' then
        return
    end

    local Root
    local Char
    if EType == 'Extra_Entity' then
        Char = Entity.PrimaryPart
        Root = Entity.PrimaryPart
    elseif EType == 'Player' then
        Char = Entity.Character
        Root = Entity.Character.PrimaryPart
    end

    task.spawn(function()
        if Rotations.Enabled then
            local targetthing = Vector3.new(Root.CFrame.Position:Lerp(Root.CFrame.Position, 0.3).X, LocalEntity.Character.PrimaryPart.CFrame.Position.Y, Root.CFrame.Position:Lerp(Root.CFrame.Position, 0.3).Z)

            local rot1 = CFrame.lookAt(LocalEntity.Character.PrimaryPart.CFrame.Position, Root.CFrame.Position)
            local rot2 = CFrame.lookAt(LocalEntity.Character.PrimaryPart.CFrame.Position, targetthing)

            LocalEntity.Character.Head.Neck.C0 = worldCFrameToC0ObjectSpace(LocalEntity.Character.Head.Neck, rot1)
            LocalEntity.Character.PrimaryPart.CFrame = rot2

            lastThingy = targetthing
        end
    end)

    local Dir = (LocalEntity.Character.PrimaryPart.CFrame.Position - Root.CFrame.Position).Unit

    Bedwars.Remotes.SwordHit:SendToServer({
        weapon = Sword,
        entityInstance = Char,
        chargedAttack = {chargeRatio = 0},
        validate = {
            selfPosition = {value = getcloserpos(LocalEntity.Character.PrimaryPart.CFrame.Position, Root.Position, 5)},
            targetPosition = {value = Root.CFrame.Position},
            raycast = {
				cameraPosition = {value = LocalEntity.Character.PrimaryPart.CFrame.Position},
				cursorDirection = {value = Dir}
			},
        }
    })
end

local function getBlockInRange(Range: number, Blocks: table)
    for i,v in workspace:GetChildren() do
        if v:GetAttribute('NoBreak') then continue end
        if v:IsA('Part') or v:IsA('BasePart') then
            local Dist = LocalEntity:DistanceFromCharacter(v.CFrame.Position)

            if Dist <= Range then
                for _, bName in Blocks do
                    if v.Name:lower():find(bName) then
                        return v
                    end
                end
            end
        end
    end
    return nil
end

local SAnim = Instance.new('Animation')
SAnim.AnimationId = Bedwars.Animations.SWORD_SWING
local FPSAnim = Instance.new('Animation')
FPSAnim.AnimationId = Bedwars.Animations.FP_SWING_SWORD
local EatAnim = Instance.new('Animation')
EatAnim.AnimationId = Bedwars.Animations.EAT
local PlaceBlockAnim = Instance.new('Animation')
PlaceBlockAnim.AnimationId = Bedwars.Animations.PLACE_BLOCK
local BreakBlockAnim = Instance.new('Animation')
BreakBlockAnim.AnimationId = Bedwars.Animations.BREAK_BLOCK
local FP_UseItem = Instance.new('Animation')
FP_UseItem.AnimationId = Bedwars.Animations.FP_USE_ITEM

local HitSound1 = Instance.new('Sound')
HitSound1.Parent = workspace
HitSound1.SoundId = 'rbxassetid://6760544639'
HitSound1.Volume = 0.15
local HitSound2 = Instance.new('Sound')
HitSound2.Parent = workspace
HitSound2.SoundId = 'rbxassetid://6760544595'
HitSound2.Volume = 0.15
local PickupSound = Instance.new('Sound')
PickupSound.Parent = workspace
PickupSound.SoundId = 'rbxassetid://6768578304'

local SLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(SAnim)
local EatLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(EatAnim)
local PlaceLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(PlaceBlockAnim)
local BreakLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(BreakBlockAnim)

local FPSLoaded = workspace.CurrentCamera.Viewmodel.Humanoid:LoadAnimation(FPSAnim)
local UseLoaded = workspace.CurrentCamera.Viewmodel.Humanoid:LoadAnimation(FP_UseItem)

LocalEntity.CharacterAdded:Connect(function()
    task.wait(1)
    SLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(SAnim)
    EatLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(EatAnim)
    PlaceLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(PlaceBlockAnim)
    BreakLoaded = LocalEntity.Character.Humanoid.Animator:LoadAnimation(BreakBlockAnim)
end)

local isDropping = false
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Q then
        isDropping = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Q then
        isDropping = false
    end
end)

local lastDropped = tick()
FastDrop = Utility:CreateModule({
    ['Name'] = 'FastDrop',
    ['Function'] = function(callback)
        if callback then
            repeat
                task.wait()
                local resource = getItem('iron') or getItem('diamond') or getItem('emerald')

                if isDropping and resource and (tick() - lastDropped) > (DropDelay.Value / 1000) and tostring(LocalEntity.Character.HandInvItem.Value) == resource.name then
                    lastDropped = tick()
                    Bedwars.Remotes.DropItem:CallServerAsync({item = resource.itemType})
                end
            until not FastDrop.Enabled
        end
    end
})
DropDelay = FastDrop.CreateSlider({
    ['Name'] = 'Drop Delay (ms)',
    ['Minimum'] = 0,
    ['Maximum'] = 1000,
    ['Default'] = 10,
})

local lastPickedUp = tick()
FastPickup = Utility:CreateModule({
    ['Name'] = 'FastPickup',
    ['Function'] = function(callback)
        if callback then
            repeat
                task.wait(0.01)

                if not EntityLib.isAlive(LocalEntity) then
                    continue
                end

                for i,v in workspace.ItemDrops:GetChildren() do
                    local Dist = LocalEntity:DistanceFromCharacter(v.CFrame.Position)

                    if Dist <= 10 then
                        if TeleportToPlayer.Enabled then
                            v.CFrame = LocalEntity.Character.PrimaryPart.CFrame - Vector3.new(0, 3.5, 0)
                        end

                        Bedwars.Remotes.PickupItemDrop:CallServerAsync({itemDrop = v}):andThen(function()
                            if (tick() - lastPickedUp) < 0.3 then
                                return
                            end
                            
                            lastPickedUp = tick()
                            PickupSound:Play()
                        end)
                    end
                end
            until not FastPickup.Enabled
        end
    end
})
TeleportToPlayer = FastPickup.CreateToggle({
    ['Name'] = 'Teleport To Player',
})

local Viewmodel = workspace.Camera.Viewmodel
local Wrist = Viewmodel.RightHand.RightWrist
local oldViewC0 = Wrist.C0

local BlockAnimations = {
	["Old"] = {
		{CFrame = CFrame.new(1.29, -0.86, 0.06) * CFrame.Angles(math.rad(-30), math.rad(130), math.rad(60)), Timer = 0.12},
		{CFrame = CFrame.new(1.39, -0.86, 0.26) * CFrame.Angles(math.rad(-10), math.rad(50), math.rad(80)), Timer = 0.12},
	},
    ['Astral'] = {
        {CFrame = CFrame.new(0.7, -0.7, 0.8) * CFrame.Angles(math.rad(-16), math.rad(60), math.rad(-80)), Timer = 0.2},
        {CFrame = CFrame.new(0.95, -1.06, -2.25) * CFrame.Angles(math.rad(-179), math.rad(61), math.rad(80)),Timer = 0.2}
    },
    ['Zyla'] = {
        {CFrame = CFrame.new(0.3, -1.5, 1.5) * CFrame.Angles(math.rad(120), math.rad(140), math.rad(320)), Timer = 0.1},
        {CFrame = CFrame.new(0.3, -2, 0.5) * CFrame.Angles(-math.rad(190), math.rad(110), -math.rad(90)), Timer = 0.3},
    },
}

local lastAttacked = tick()
Aura = Combat:CreateModule({
    ['Name'] = 'Aura',
    ['Function'] = function(callback)
        if callback then
            Aura:Start(function()
                if not EntityLib.isAlive(LocalEntity) then
                    FPSLoaded:Stop()
                    return
                end

                local Target, EType, Dist = EntityLib.getNearestEntity(AuraRange.Value or 18)
                local Sword = getItem('Sword') or getItem('Dao') or getItem('rageblade')

                if Target then
                    if Sword then
                        attackEntity(Target, Sword.itemType, EType, Dist)
                    end
                    if TargetHUD.Enabled then
                        GuiLibrary.TargetHud:AddTarget(Target)
                    end

                    if (tick() - lastAttacked) < (SwingSpeed.Value / 1000 or 0.2) then
                        return
                    end

                    if SwingSword.Enabled then
                        SLoaded:Play()
                        if not FPSLoaded.IsPlaying and Animations.Value == 'None' then
                            FPSLoaded:Play()
                        else
                            FPSLoaded:Stop()
                        end
                    else
                        FPSLoaded:Stop()
                    end

                    if SwingSound.Enabled then
                        if math.random(1, 2) == 1 then
                            HitSound1:Play()
                        else
                            HitSound2:Play()
                        end
                    end

                    if AutoSwitch.Enabled and Sword then
                        task.spawn(switchItem, Sword.name)
                    end

                    lastAttacked = tick()
                else
                    FPSLoaded:Stop()
                    LocalEntity.Character.Head.Neck.C0 = oldC0
                    GuiLibrary.TargetHud:ClearTargets()
                end
            end)

            repeat
                task.wait()
                local Target = EntityLib.getNearestEntity(AuraRange.Value or 18)

                if Target then
                    if Animations.Value ~= 'None' then
                        for i,v in BlockAnimations[Animations.Value] do
                            TweenService:Create(Wrist, TweenInfo.new(v.Timer), {
                                C0 = oldViewC0 * v.CFrame
                            }):Play()
                            task.wait(v.Timer)
                        end
                    end
                else
                    TweenService:Create(Wrist, TweenInfo.new(0.5), {
                        C0 = oldViewC0
                    }):Play()
                end
            until not Aura.Enabled
        else
            LocalEntity.Character.Head.Neck.C0 = oldC0
        end
    end
})
AuraRange = Aura.CreateSlider({
    ['Name'] = 'Range',
    ['Minimum'] = 0,
    ['Maximum'] = 18,
    ['Default'] = 18,
})
SwingSpeed = Aura.CreateSlider({
    ['Name'] = 'Swing Speed (MS)',
    ['Minimum'] = 0,
    ['Maximum'] = 1000,
    ['Default'] = 100,
})
Animations = Aura.CreatePicker({
    ['Name'] = 'Animations',
    ['Options'] = {'None', 'Old', 'Astral', 'Zyla'}
})
AutoSwitch = Aura.CreateToggle({
    ['Name'] = 'Auto Switch'
})
AttackOtherEntities = Aura.CreateToggle({
    ['Name'] = 'Other Entites'
})
SwingSword = Aura.CreateToggle({
    ['Name'] = 'Swing Sword'
})
SwingSound = Aura.CreateToggle({
    ['Name'] = 'Swing Sound'
})
Rotations = Aura.CreateToggle({
    ['Name'] = 'Rotations',
})
TargetHUD = Aura.CreateToggle({
    ['Name'] = 'Target HUD'
})

local velo = ReplicatedStorage.TS.damage["knockback-util"]

local oldvelo = {
    dirStr = 11750,
    upStr = 10000,
    nGroundHorR = 0.6,
    nGVertR = 0.75,
}
AntiKB = Combat:CreateModule({
    ['Name'] = 'AntiKB',
    ['Function'] = function(callback)
        if callback then
            velo:SetAttribute('ConstantManager_kbDirectionStrength', 0)
            velo:SetAttribute('ConstantManager_kbUpwardStrength', -5)
            velo:SetAttribute('ConstantManager_nonGroundedHorizontalResistance', 0)
            velo:SetAttribute('ConstantManager_nonGroundedVerticalResistance', 0)
        else
            velo:SetAttribute('ConstantManager_kbDirectionStrength', oldvelo.dirStr)
            velo:SetAttribute('ConstantManager_kbUpwardStrength', oldvelo.upStr)
            velo:SetAttribute('ConstantManager_nonGroundedHorizontalResistance', oldvelo.nGroundHorR)
            velo:SetAttribute('ConstantManager_nonGroundedVerticalResistance', oldvelo.nGVertR)
        end
    end
})

Breaker = Player:CreateModule({
    ['Name'] = 'Breaker',
    ['Function'] = function(callback)
        if callback then
            repeat
                task.wait(0.23)
                local Extra = getBlockInRange(BreakerRange.Value, {'iron_ore'})
                local Bed = getBlockInRange(BreakerRange.Value, {'bed'})

                local isBreaking = false

                local BrokeFunny
                if Bed and BreakBeds.Enabled then
                    local Block = workspace:Raycast(Bed.CFrame.Position + Vector3.new(0, 25, 0), Vector3.new(0, -26, 0))

                    if AutoSwitchBlocks.Enabled then
                        if (Block.Instance.Name == 'bed' or Block.Instance.Name:lower():find('wood')) and hasAxe() then
                            switchItem(getBestAxe().name)
                        elseif (Block.Instance.Name:lower():find('stone') or Block.Instance.Name:lower():find('blastproof')) and getItem('pickaxe') then
                            switchItem(getBestPickaxe().name)
                        elseif Block.Instance.Name:lower():find('wool') and getItem('shears') then
                            switchItem(getItem('shears').name)
                        end
                    end

                    if Block and Block.Instance then
                        isBreaking = true
                        BrokeFunny = true

                        Bedwars.Remotes.DamageBlock:CallServerAsync({
                            hitNormal = Vector3.zero,
                            hitPosition = Block.Instance.Position,
                            blockRef = {
                                blockPosition = getFixedPosition(Block.Position) - Vector3.new(0, 1, 0)
                            }
                        })
                    end
                end

                task.spawn(function()
                    if BrokeFunny and FixTimingBreaker.Enabled then
                        return
                    end

                    if Extra and ExtraBlocks.Enabled then
                        if AutoSwitchBlocks.Enabled or true then
                            switchItem(getBestPickaxe().name)
                        end

                        isBreaking = true
                        Bedwars.Remotes.DamageBlock:CallServerAsync({
                            hitNormal = Vector3.zero,
                            hitPosition = Extra.CFrame.Position,
                            blockRef = {
                                blockPosition = getFixedPosition(Extra.CFrame.Position)
                            }
                        })
                    end
                end)

                if isBreaking and not BreakLoaded.IsPlaying and BreakAnim.Enabled then
                    BreakLoaded:Play()
                else
                    BreakLoaded:Stop()
                end
            until not Breaker.Enabled
        end
    end
})
BreakerRange = Breaker.CreateSlider({
    ['Name'] = 'Range',
    ['Minimum'] = 0,
    ['Maximum'] = 30,
    ['Default'] = 30,
})
AutoSwitchBlocks = Breaker.CreateToggle({
    ['Name'] = 'Auto Switch',
})
BreakBeds = Breaker.CreateToggle({
    ['Name'] = 'Beds',
})
ExtraBlocks = Breaker.CreateToggle({
    ['Name'] = 'Extra Blocks',
})
FixTimingBreaker = Breaker.CreateToggle({
    ['Name'] = 'Fix Timing',
})
BreakAnim = Breaker.CreateToggle({
    ['Name'] = 'Animation'
})

local Items = {
    'speed_potion',
    'pie'
}
local ItemToggles = {}
AutoConsume = Combat:CreateModule({
    ['Name'] = 'AutoConsume',
    ['Function'] = function(callback)
        if callback then
            repeat
                if not EntityLib.isAlive(LocalEntity) then
                    continue
                end

                for _, v in Items do
                    if v == 'speed_potion' and LocalEntity.Character:GetAttribute('SpeedBoost') or not ItemToggles[v].Enabled then continue end
                    if v == 'pie' and LocalEntity.Character:GetAttribute('SpeedPieBuff') or not ItemToggles[v].Enabled then continue end

                    if getItem(v) then
                        Bedwars.Remotes.ConsumeItem:CallServerAsync({item = getItem(v).itemType})
                    end
                end

                task.wait(0.1)
            until not AutoConsume.Enabled
        end
    end
})
for _,v in Items do
    ItemToggles[v] = AutoConsume.CreateToggle({
        ['Name'] = v:gsub('_', ' ')
    })
end

local function getRoundedPos(pos: Vector3)
    return Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
end

local tempBlocks = {}
local createTempBlock = function(pos)
    if #tempBlocks > 1 then
        return
    end

    local Block = Instance.new('Part')
    Block.Parent = workspace
    Block.Position = getRoundedPos(pos)
    Block.Transparency = 0.8
    Block.Color = Color3.fromRGB(200, 0, 0)
    Block.Material = Enum.Material.Neon
    Block.Size = Vector3.new(3, 3, 3)
    Block.Anchored = true

    table.insert(tempBlocks, Block)

    return Block
end

local Positions = {}
Scaffold = Player:CreateModule({
    ['Name'] = 'Scaffold',
    ['Function'] = function(callback)
        if callback then
            repeat
                task.wait(0.01)
                if not EntityLib.isAlive(LocalEntity) then
                    continue
                end

                local Block = getPlaceableBlock()

                if Block then
                    if LocalEntity.Character.Humanoid.MoveDirection ~= Vector3.zero and PlaceAnim.Enabled then
                        if not UseLoaded.IsPlaying then
                            UseLoaded:Play()
                            PlaceLoaded:Play()
                        end
                    else
                        if UseLoaded.IsPlaying then
                            UseLoaded:Stop()
                            PlaceLoaded:Stop()
                        end
                    end

                    local ExpPos = LocalEntity.Character.PrimaryPart.CFrame.Position - Vector3.new(0, 4, 0) + LocalEntity.Character.Humanoid.MoveDirection * 3
                    local Fixed = getFixedPosition(ExpPos)

                    local CheckRay = workspace:Raycast(Fixed + Vector3.new(0, 1, 0), Vector3.new(0, -3, 0))

                    if not table.find(Positions, Fixed) and not CheckRay then
                        local funny = createTempBlock(ExpPos)

                        Bedwars.Remotes.PlaceBlock:CallServerAsync({
                            position = Fixed,
                            blockType = Block.name,
                            blockData = 0,
                        })
                        table.insert(Positions, Fixed)

                        table.remove(tempBlocks, 1)
                        funny:Destroy()
                    end
                else
                    if UseLoaded.IsPlaying then
                        UseLoaded:Stop()
                        PlaceLoaded:Stop()
                    end
                end
            until not Scaffold.Enabled

            if UseLoaded.IsPlaying then
                UseLoaded:Stop()
                PlaceLoaded:Stop()
            end
        end
    end
})
PlaceAnim = Scaffold.CreateToggle({
    ['Name'] = 'Animation'
})

local function getSpeedMulti(Value: number, FixSpeed: boolean)
    if FixSpeed then
        Value -= LocalEntity.Character.Humanoid.WalkSpeed
    end

    if LocalEntity.Character:GetAttribute('SpeedBoost') then
        Value += 7
    end
    if LocalEntity.Character:GetAttribute('SpeedPieBuff') then
        Value += 7
    end

    if LocalEntity.Character:FindFirstChild('dodo_bird') then
        Value += 15
    end

    if DamageBoost.Enabled and (workspace:GetServerTimeNow() - LocalEntity.Character:GetAttribute('LastDamageTakenTime')) < 0.5 then
        Value += 15
    end
   
    return Value
end

Flight = Movement:CreateModule({
    ['Name'] = 'Flight',
    ['Function'] = function(callback)
        if callback then
            local startTick = tick()
            Flight:Start(function(deltaTime: number)
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                local Velocity = LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity
                local ExpY = 0.8 + deltaTime

                if FlightMode.Value == 'Vanilla' then
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
        else
            LocalEntity.Character.Humanoid:ChangeState(Enum.HumanoidStateType.None)
            LocalEntity.Character.PrimaryPart.Anchored = false
        end
    end
})
FlightMode = Flight.CreatePicker({
    ['Name'] = 'Mode',
    ['Options'] = {'Vanilla'}
})
Vertical = Flight.CreateToggle({
    ['Name'] = 'Vertical',
})

Speed = Movement:CreateModule({
    ['Name'] = 'Speed',
    ['Function'] = function(callback)
        if callback then
            Speed:Start(function(deltaTime: number)
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                local MoveDir = LocalEntity.Character.Humanoid.MoveDirection
                local SpeedExp = getSpeedMulti(SpeedAmount.Value, SpeedMode.Value == 'CFrame')

                if SpeedMode.Value == 'CFrame' then
                    LocalEntity.Character.PrimaryPart.CFrame += (MoveDir * SpeedExp * deltaTime)
                elseif SpeedMode.Value == 'Velocity' then
                    LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity = MoveDir * SpeedExp + Vector3.new(0, LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity.Y, 0)
                end
            end)
        end
    end
})
SpeedMode = Speed.CreatePicker({
    ['Name'] = 'Mode',
    ['Options'] = {'CFrame', 'Velocity'}
})
SpeedAmount = Speed.CreateSlider({
    ['Name'] = 'Value',
    ['Minimum'] = 0,
    ['Maximum'] = 23,
    ['Default'] = 23,
})
DamageBoost = Speed.CreateToggle({
    ['Name'] = 'Damage Boost',
})

local AVPart
AntiVoid = Player:CreateModule({
    ['Name'] = 'AntiVoid',
    ['Function'] = function(callback)
        if callback then
            local Lowest = getLowestPartOfMap()

            AVPart = Instance.new('Part')
            AVPart.Parent = workspace
            AVPart.Position = Vector3.new(0, Lowest, 0)
            AVPart.Size = Vector3.new(10000, 1, 10000)
            AVPart.Anchored = true
            AVPart.CanQuery = false
            AVPart.CanTouch = false
            AVPart.CanCollide = false
            AVPart.Material = Enum.Material.Neon
            AVPart.Transparency = 0.9
            AVPart.Color = Color3.fromRGB(255, 0, 0)

            AntiVoid:Start(function(dt)
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                if LocalEntity.Character.PrimaryPart.CFrame.Position.Y < Lowest then
                    LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity += Vector3.new(0, (1200 / 2) * dt, 0)
                end
            end)
        else
            AVPart:Destroy()
        end
    end
})

local Blacklisted = RaycastParams.new()
Blacklisted.FilterType = Enum.RaycastFilterType.Exclude
Blacklisted.FilterDescendantsInstances = {LocalEntity.Character, workspace.CurrentCamera}

Step = Movement:CreateModule({
    ['Name'] = 'Step',
    ['Function'] = function(callback)
        if callback then
            Step:Start(function(dt)
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                local RayC = workspace:Raycast(LocalEntity.Character.PrimaryPart.CFrame.Position, LocalEntity.Character.PrimaryPart.CFrame.LookVector * 1, Blacklisted)

                if RayC and RayC.Instance and RayC.Instance.CanCollide then
                    if StepMethod.Value == 'Velocity' then
                        LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(NoMove.Enabled and 0 or LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity.X, 44, NoMove.Enabled and 0 or LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity.Z)
                    elseif StepMethod.Value == 'Teleport' then
                        LocalEntity.Character.PrimaryPart.CFrame += Vector3.new(0, RayC.Instance.Size.Y, 0)
                    end
                end
            end)
        end
    end
})
StepMethod = Step.CreatePicker({
    ['Name'] = 'Method',
    ['Options'] = {'Velocity', 'Teleport'}
})
NoMove = Step.CreateToggle({
    ['Name'] = 'No Move'
})

NoFall = Player:CreateModule({
    ['Name'] = 'NoFall',
    ['Function'] = function(callback)
        if callback then
            local yvelo = 0
            NoFall:Start(function(deltaTime)
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                if LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity.Y > -80 then
                    yvelo = 0
                    return
                end

                yvelo += workspace.Gravity * deltaTime
                LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity.X, -80, LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity.Z)
                LocalEntity.Character.PrimaryPart.CFrame -= Vector3.new(0, yvelo * deltaTime, 0)
            end)
        end
    end
})

Stealer = Player:CreateModule({
    ['Name'] = 'Stealer',
    ['Function'] = function(callback)
        if callback then
            repeat
                task.wait(0.1)

                for i,v in Chests do
                    local Dist = LocalEntity:DistanceFromCharacter(v.Position)

                    if Dist <= 18 then
                        if #v.ChestFolderValue.Value:GetChildren() < 1 then
                            continue
                        end

                        Bedwars.Remotes.SetObservedChest:SendToServer(v.ChestFolderValue.Value)

                        for _, item in v.ChestFolderValue.Value:GetChildren() do
                            if not item:IsA('Accessory') then continue end
                            Bedwars.Remotes.ChestGetItem:CallServerAsync(v.ChestFolderValue.Value, item)
                        end

                        Bedwars.Remotes.SetObservedChest:SendToServer(nil)
                    end
                end
            until not Stealer.Enabled
        end
    end
})

AirJump = Movement:CreateModule({
    ['Name'] = 'AirJump',
    ['Function'] = function(callback)
        if callback then
            AirJump:Start(UserInputService.InputBegan, function(Input: InputObject)
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                if not UserInputService:GetFocusedTextBox() and Input.KeyCode == Enum.KeyCode.Space then
                    LocalEntity.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end
})

AutoQueue = Utility:CreateModule({
    ['Name'] = 'AutoQueue',
    ['Function'] = function(callback)
        if callback then
            AutoQueue:Start(LocalEntity.PlayerGui.ChildAdded, function(child)
                if child.Name == 'spectate-selector' or child.Name == 'PostGame' then
                    ReplicatedStorage['events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events'].joinQueue:FireServer{
                        ["queueType"] = game:GetService('TeleportService'):GetLocalPlayerTeleportData().match.queueType
                    }
                end
            end)
        end
    end
})

local currChild = nil
Viewmodel = Visuals:CreateModule({
    ['Name'] = 'Viewmodel',
    ['Function'] = function(callback)
        if callback then
            Viewmodel:Start(workspace.CurrentCamera.Viewmodel.ChildAdded, function(child)
                if child:FindFirstChild('Handle') then
                    child.Handle:SetAttribute('OldSize', child.Handle.Size)
                    currChild = child.Handle
                    child.Handle.Size /= ViewmodelSize.Value
                end
            end)
        end
    end
})
ViewmodelSize = Viewmodel.CreateSlider({
    ['Name'] = 'Size',
    ['Minimum'] = 1,
    ['Maximum'] = 3,
    ['Default'] = 1.5,
    ['Function'] = function(val)
        if currChild then
            currChild.Size = currChild:GetAttribute('OldSize') / val
        end
    end
})
--[[Glint = Viewmodel.CreateToggle({
    ['Name'] = 'Glint',
})]]

Strafe = Movement:CreateModule({
    ['Name'] = 'Strafe',
    ['Function'] = function(callback)
        if callback then
            Strafe:Start(function()
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                local Dir = LocalEntity.Character.Humanoid.MoveDirection
                local WS = LocalEntity.Character.Humanoid.WalkSpeed

                LocalEntity.Character.PrimaryPart.Velocity = Vector3.new(Dir.X * WS, LocalEntity.Character.PrimaryPart.Velocity.Y, Dir.Z * WS)
            end)
        end
    end
})

NoSlow = Player:CreateModule({
    ['Name'] = 'NoSlow',
    ['Function'] = function(callback)
        if callback then
            Bedwars.Remotes.StepOnSnapTrap.inst.Parent = nil
            Bedwars.Remotes.TriggerInvisibleLandmine.inst.Parent = nil

            NoSlow:Start(function(dt)
                if not EntityLib.isAlive(LocalEntity) then
                    return
                end

                local WS = LocalEntity.Character.Humanoid.WalkSpeed
                local Dir = LocalEntity.Character.Humanoid.MoveDirection

                if WS < 20 then
                    LocalEntity.Character.PrimaryPart.CFrame += ((20 - WS) * dt * Dir)
                end
            end)
        else
            Bedwars.Remotes.StepOnSnapTrap.inst.Parent = NetManaged
            Bedwars.Remotes.TriggerInvisibleLandmine.inst.Parent = NetManaged
        end
    end
})

