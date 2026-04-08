local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local TextChatService = game:GetService('TextChatService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local LocalEntity = Players.LocalPlayer
local GuiLibrary = shared.GuiLibrary
local EntityLib = loadfile('Novoline/libraries/Entity.lua')()

local InstanceFolder = Instance.new('Folder')
InstanceFolder.Name = 'Instances Folder'
InstanceFolder.Parent = workspace

local Combat = GuiLibrary:GetWindow("Combat")
local Movement = GuiLibrary:GetWindow("Movement")
local Visuals = GuiLibrary:GetWindow("Visuals")
local Utility = GuiLibrary:GetWindow("Utility")

local function changeClr(clr: Color3, Changed: number)
	local R = math.round((clr.R * 255) * Changed)
	local G = math.round((clr.G * 255) * Changed)
	local B = math.round((clr.B * 255) * Changed)

	return Color3.fromRGB(R,G,B)
end

local function brickToColor3(Color: BrickColor)
	local R = math.round(Color.r * 255)
	local G = math.round(Color.g * 255)
	local B = math.round(Color.b * 255)

	return Color3.fromRGB(R, G, B)
end

local ESPinsts = {}
local function createESP(Player: Player)
	if not Player.Character then
		Player.CharacterAdded:Wait()
	end

	if not ESPMode then
		repeat task.wait() until ESPMode ~= nil
	end

	if not SelfCheck then
		repeat task.wait() until SelfCheck ~= nil
	end

	if Player.Character:FindFirstChild('ESP') then
		Player.Character:FindFirstChild('ESP'):Destroy()
	end

	if Player == LocalEntity and SelfCheck.Enabled then
		return
	end

	local newESP = Instance.new('BillboardGui')
	newESP.Adornee = Player.Character
	newESP.Size = UDim2.fromScale(3.5, 5.5)
	newESP.AlwaysOnTop = true
	newESP.MaxDistance = 999999
	newESP.Parent = InstanceFolder
	table.insert(ESPinsts, newESP)

	local ColorSeq = ColorSequence.new({
		ColorSequenceKeypoint.new(0, brickToColor3(Player.TeamColor)),
		ColorSequenceKeypoint.new(1, changeClr(brickToColor3(Player.TeamColor), 0.65))
	})

	if ESPMode.Value == 'Box' then
		local size = 1
		
		local Side1 = Instance.new('Frame')
		Side1.Parent = newESP
		Side1.Size = UDim2.new(0, size, 1, 0)
		Side1.BorderSizePixel = 0
		Side1.BackgroundColor3 = brickToColor3(Player.TeamColor)
		local Side2 = Instance.new('Frame')
		Side2.Parent = newESP
		Side2.Position = UDim2.new(1, -size, 0, 0)
		Side2.Size = UDim2.new(0, size, 1, 0)
		Side2.BorderSizePixel = 0
		Side2.BackgroundColor3 = changeClr(brickToColor3(Player.TeamColor), 0.65)
		local Top = Instance.new('Frame')
		Top.Parent = newESP
		Top.Position = UDim2.fromScale(0, 0)
		Top.Size = UDim2.new(1, 0, 0, size)
		Top.BorderSizePixel = 0
		Top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		local Bottom = Instance.new('Frame')
		Bottom.Parent = newESP
		Bottom.Position = UDim2.new(0, 0, 1, -size)
		Bottom.Size = UDim2.new(1, 0, 0, size)
		Bottom.BorderSizePixel = 0
		Bottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

		local UIGradient = Instance.new('UIGradient')
		UIGradient.Parent = Top
		UIGradient.Color = ColorSeq

		local UIGradient2 = Instance.new('UIGradient')
		UIGradient2.Parent = Bottom
		UIGradient2.Color = ColorSeq
	elseif ESPMode.Value == 'Highlight' then
		local HighlightInst = Instance.new('Highlight')
		HighlightInst.Adornee = Player.Character
		HighlightInst.FillColor = brickToColor3(Player.TeamColor)
		HighlightInst.FillTransparency = 0.5
		HighlightInst.OutlineColor = brickToColor3(Player.TeamColor)
		HighlightInst.OutlineTransparency = 0
		HighlightInst.Parent = InstanceFolder

		table.insert(ESPinsts, HighlightInst)
	end
end

local ESPConnections = {}
local ESP = Visuals:CreateModule({
	['Name'] = 'ESP',
	['Function'] = function(callback)
		if callback then
			for _, v in Players:GetPlayers() do
				if SelfCheck.Enabled and v == LocalEntity then
					continue
				end

				createESP(v)

				table.insert(ESPConnections, v.CharacterAdded:Connect(function()
					task.wait(1)
					createESP(v)
				end))
			end

			table.insert(ESPConnections, Players.PlayerAdded:Connect(function(plr)
				table.insert(ESPConnections, plr.CharacterAdded:Connect(function()
					task.wait(1)
					createESP(plr)
				end))
			end))
		else
			for _,v in ESPConnections do
				v:Disconnect()
			end

			for _, v in ESPinsts do
				v:Destroy()
			end
		end
	end
})
SelfCheck = ESP.CreateToggle({
	['Name'] = 'Self Check'
})
ESPMode = ESP.CreatePicker({
	['Name'] = 'Mode',
	['Options'] = {'None', 'Box', 'Highlight'},
	['Function'] = function(Value)
		if not ESP.Enabled then
			return
		end

		for _, v in ESPinsts do
			v:Destroy()
		end
		for _, v in Players:GetPlayers() do
			createESP(v)
		end
	end
})

SessionInfo = Visuals:CreateModule({
	['Name'] = 'SessionInfo',
	['Function'] = function(callback)
		if callback then
			GuiLibrary.SessionInfo:Create()

			if ShowTime.Enabled then
				GuiLibrary.SessionInfo:AddItem('Time', ' seconds')

				task.spawn(function()
					repeat
						task.wait(1)
						GuiLibrary.SessionInfo:IncreaseItem('Time', 1)
					until not SessionInfo.Enabled
				end)
			end
		else
			GuiLibrary.SessionInfo.CurrentInfo:Destroy();
		end
	end
})
ShowTime = SessionInfo.CreateToggle({
	['Name'] = 'Show Time',
})

local wmInst
Watermark = Visuals:CreateModule({
	['Name'] = 'Watermark',
	['Function'] = function(callback)
		if callback then

			wmInst = Instance.new('TextLabel')
			wmInst.Parent = GuiLibrary.ScreenGui
			wmInst.Position = UDim2.fromOffset(70, 80)
			wmInst.Size = UDim2.fromOffset(200, 40)
			wmInst.BackgroundTransparency = 1
			wmInst.TextColor3 = Color3.fromRGB(255, 255, 255)
			wmInst.TextSize = 22
			wmInst.Text = 'Novoline'
			wmInst.ZIndex = -1
			local Shadow = Instance.new('TextLabel')
			Shadow.BackgroundTransparency = 1
			Shadow.Size = UDim2.fromOffset(200, 40)
			Shadow.Parent = GuiLibrary.ScreenGui
			Shadow.Position = UDim2.fromOffset(72, 82)
			Shadow.TextColor3 = Color3.fromRGB(30, 30, 30)
			Shadow.ZIndex = -2
			Shadow.TextSize = 22
			Shadow.Text = 'Novoline'

			local UIGradient = Instance.new('UIGradient')
			UIGradient.Parent = wmInst
			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(121, 0, 0))
			})

			local lastRot = tick();
			repeat
				task.wait()
				UIGradient.Rotation += (50 * (tick() - lastRot))

				lastRot = tick();
			until not Watermark.Enabled
			Shadow:Destroy();
		else
			wmInst:Destroy();
		end
	end
})


local ArrayList = Visuals:CreateModule({
	['Name'] = 'ArrayList',
	['Function'] = function(callback)
		GuiLibrary.ArrayManager.Enabled = callback
	end
})

local obrightness = Lighting.Brightness
local oTOD = Lighting.TimeOfDay
local Ambience = Visuals:CreateModule({
	['Name'] = 'Ambience',
	['Function'] = function(callback)
		if callback then
			Lighting.Brightness = Brightness.Value
			Lighting.TimeOfDay = TimeOfDay.Value
		else
			Lighting.Brightness = obrightness
			Lighting.TimeOfDay = oTOD
		end
	end
})
TimeOfDay = Ambience.CreateSlider({
	['Name'] = 'Time of Day',
	['Minimum'] = 0,
	['Maximum'] = 24,
	['Default'] = 1,
	['Function'] = function(val)
		Lighting.TimeOfDay = tostring(val)..':00:00'
	end
})
Brightness = Ambience.CreateSlider({
	['Name'] = 'Brightness',
	['Minimum'] = 0,
	['Maximum'] = 10,
	['Default'] = 1,
	['Function'] = function(val)
		Lighting.Brightness = val
	end
})

-- I think im getting aids
local CapePart
local function GetMotor(Part)
	local motor = Instance.new("Motor6D", Part)
	motor.MaxVelocity = 8/100
	motor.Part0 = Part
	motor.Part1 = LocalEntity.Character.UpperTorso
	motor.C0 = CFrame.new(0, 2, 0) * CFrame.Angles(0, math.rad(-90), 0)
	motor.C1 = CFrame.new(0, LocalEntity.Character.UpperTorso.Size.Y / 2, 0.5) * CFrame.Angles(0, math.rad(90), 0)
	return motor
end

Cape = Visuals:CreateModule({
	['Name'] = 'Cape',
	['Function'] = function(callback)
		if callback then
			Mimic = Instance.new("Part")
			Mimic.Anchored = true
			Mimic.CanCollide = false
			Mimic.CanQuery = false
			Mimic.Massless = true
			Mimic.Transparency = 1
			Mimic.Size = Vector3.new(1,1,1)
			Mimic.Parent = workspace

			local lastRot = LocalEntity.Character.UpperTorso.CFrame - LocalEntity.Character.UpperTorso.Position

			CapePart = Instance.new("Part", workspace)
			CapePart.Size = Vector3.new(2, 4, 0.1)
			CapePart.CanCollide = false
			CapePart.CanQuery = false
			CapePart.Massless = true
			CapePart.CastShadow = false
			CapePart.Color = Color3.fromRGB(219, 80, 0)

			local SurfaceGui = Instance.new("SurfaceGui", CapePart)
			SurfaceGui.ResetOnSpawn = false
			SurfaceGui.AlwaysOnTop = false

			local Image = Instance.new("ImageLabel", SurfaceGui)
			Image.Size = UDim2.fromScale(1, 1)
			Image.Image = getcustomasset('Novoline/assets/cape.png')
			Image.ScaleType = Enum.ScaleType.Tile

			local Motor = GetMotor(CapePart, Mimic)

			Cape:Start(function(dt)
				local torso = LocalEntity.Character.UpperTorso
				local pos = torso.Position
				local rot = torso.CFrame - torso.Position
				local alpha = dt and math.clamp(dt * 5, 0, 1) or 0.1
				local rotationLerpSpeed = 8

				lastRot = lastRot:Lerp(rot, alpha)
				Mimic.CFrame = CFrame.new(pos) * lastRot

				local Expected = math.min(LocalEntity.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude, 90) * 2.2
				local visible = (workspace.CurrentCamera.CFrame.Position - LocalEntity.Character.Head.Position).Magnitude > 2

				CapePart.Transparency = visible and 0 or 1
				SurfaceGui.Enabled = visible

				Motor.DesiredAngle = math.rad(10) + math.rad(Expected) + (Expected > 2 and math.abs(math.cos(time() * 5)) / 2.5 or 0)
			end)
		else
			if Mimic then Mimic:Destroy() end
			if CapePart then CapePart:Destroy() end
		end
	end

})

