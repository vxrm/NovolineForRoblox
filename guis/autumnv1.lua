shared.Config = 'Default'

local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local TextService = game:GetService('TextService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')

local LocalEntity = Players.LocalPlayer

local GuiLibrary = {}
GuiLibrary.Name = 'Autumn V3'
GuiLibrary.Windows = {}
GuiLibrary.Connections = {}

local CFile = 'Novoline/Configs/'..shared.Config..'/'..game.PlaceId..'.json'
local Config = {}

local cansave = true
local function save()
	if RunService:IsStudio() or not cansave then
		return
	end
	
	writefile(CFile, game:GetService('HttpService'):JSONEncode(Config))
end

if not RunService:IsStudio() then
	if isfile(CFile) then
		Config = game:GetService('HttpService'):JSONDecode(readfile(CFile))
	end
end

local ScreenGui = Instance.new('ScreenGui')
ScreenGui.Parent = game:GetService('CoreGui')
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
local UIBlur = Instance.new('BlurEffect')
UIBlur.Parent = Lighting
UIBlur.Enabled = false
local UIScale = Instance.new('UIScale')
UIScale.Parent = ScreenGui
UIScale.Scale = math.max(ScreenGui.AbsoluteSize.X / 1920, 0.8)
local ArrayFrame = Instance.new('Frame')
ArrayFrame.Parent = ScreenGui
ArrayFrame.Position = UDim2.fromScale(0.69, 0.1)
ArrayFrame.Size = UDim2.fromScale(0.3, 0.7)
ArrayFrame.BackgroundTransparency = 1
ArrayFrame.Visible = false
local ArraySort = Instance.new('UIListLayout')
ArraySort.Parent = ArrayFrame
ArraySort.SortOrder = Enum.SortOrder.LayoutOrder
ArraySort.VerticalAlignment = Enum.VerticalAlignment.Top
ArraySort.HorizontalAlignment = Enum.HorizontalAlignment.Right
local TargetHUDFrame = Instance.new('Frame')
TargetHUDFrame.Parent = ScreenGui
TargetHUDFrame.Position = UDim2.fromScale(0.5, 0.5)
TargetHUDFrame.Size = UDim2.fromScale(0.3, 0.45)
TargetHUDFrame.BackgroundTransparency = 1
local TargetHudSort = Instance.new('UIListLayout')
TargetHudSort.Parent = TargetHUDFrame
TargetHudSort.SortOrder = Enum.SortOrder.LayoutOrder
TargetHudSort.FillDirection = Enum.FillDirection.Horizontal
TargetHudSort.Padding = UDim.new(0, 7)
TargetHudSort.Wraps = true

local function getTextSize(Item)
	return TextService:GetTextSize(Item.Text, Item.TextSize, Item.Font, Vector2.zero)
end

GuiLibrary.ScreenGui = ScreenGui
GuiLibrary.TargetHud = {
	Targets = {},
	AddTarget = function(self, Entity: Player)
		local Found = false
		for i,v in self.Targets do
			if v.User == Entity then
				Found = true
			end
		end
		
		if not Found then
			table.insert(self.Targets, {
				User = Entity,
				Inst = nil,
			})
		end
	end,
	RemoveTarget = function(self, Entity: Player)
		for i,v in self.Targets do
			if v.User == Entity then
				table.remove(self.Targets, i)
			end
		end
	end,
	ClearTargets = function(self)
		for i,_ in self.Targets do
			table.remove(self.Targets, i)
		end
	end,
	Create = function(Entity: Player)
		local TargetHUD = Instance.new('Frame')
		TargetHUD.Parent = TargetHUDFrame
		TargetHUD.Position = UDim2.fromScale(0.5, 0.5)
		TargetHUD.BorderSizePixel = 0
		TargetHUD.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		local UserProfile = Instance.new('ImageLabel')
		UserProfile.Parent = TargetHUD
		UserProfile.Size = UDim2.fromOffset(45, 45)
		UserProfile.Position = UDim2.fromOffset(5, 5)
		UserProfile.BackgroundTransparency = 1
		UserProfile.Image = Players:GetUserThumbnailAsync(Entity.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		local UserName = Instance.new('TextLabel')
		UserName.Parent = TargetHUD
		UserName.Position = UDim2.fromOffset(58, 20)
		UserName.TextXAlignment = Enum.TextXAlignment.Left
		UserName.TextColor3 = Color3.fromRGB(255, 255, 255)
		UserName.TextSize = 8
		UserName.Text = Entity.DisplayName
		local HealthBar = Instance.new('Frame')
		HealthBar.Parent = TargetHUD
		HealthBar.Position = UDim2.fromOffset(58, 36)
		HealthBar.Size = UDim2.fromOffset(80, 8)
		HealthBar.BorderSizePixel = 0
		HealthBar.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		HealthBar.Name = 'HealthBar'
		local HealthBarOverlay = Instance.new('Frame')
		HealthBarOverlay.Parent = HealthBar
		HealthBarOverlay.Size = UDim2.fromScale(0.5, 1)
		HealthBarOverlay.BorderSizePixel = 0
		HealthBarOverlay.BackgroundColor3 = Color3.fromRGB(161, 0, 0)
		HealthBarOverlay.Name = 'Overlay1'
		local HealthBarOverlay2 = Instance.new('Frame')
		HealthBarOverlay2.Parent = HealthBar
		HealthBarOverlay2.Size = UDim2.fromScale(0.5, 1)
		HealthBarOverlay2.BorderSizePixel = 0
		HealthBarOverlay2.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		HealthBarOverlay2.Name = 'Overlay2'
		
		local HPOverName = (HealthBar.Size.X.Offset > getTextSize(UserName).X)
				
		if not HPOverName then
			HealthBar.Size = UDim2.fromOffset(getTextSize(UserName).X, 8)
		end
		TargetHUD.Size = UDim2.fromOffset(56  + (HPOverName and 80 or getTextSize(UserName).X) + 10, 56)
		
		task.spawn(function()
			repeat
				task.wait()
				
				TweenService:Create(HealthBarOverlay, TweenInfo.new(1), {
					Size = UDim2.fromScale(Entity.Character.Humanoid.Health / Entity.Character.Humanoid.MaxHealth, 1)
				}):Play()
				TweenService:Create(HealthBarOverlay2, TweenInfo.new(0.25), {
					Size = UDim2.fromScale(Entity.Character.Humanoid.Health / Entity.Character.Humanoid.MaxHealth, 1)
				}):Play()
			until not TargetHUD
		end)
		
		return TargetHUD
	end,
}

GuiLibrary.SessionInfo = {
	CurrentInfo = nil,
	Items = {},
	Create = function(self)
		local Frame = Instance.new('Frame')
		Frame.Parent = ScreenGui
		Frame.Position = UDim2.fromScale(0.01, 0.5)
		Frame.AnchorPoint = Vector2.new(0, 0.5)
		Frame.Size = UDim2.fromOffset(230, 45)
		Frame.AutomaticSize = Enum.AutomaticSize.Y
		Frame.BackgroundTransparency = 0.35
		Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Frame.BorderSizePixel = 0
		local FrameCorner = Instance.new('UICorner')
		FrameCorner.Parent = Frame
		FrameCorner.CornerRadius = UDim.new(0.1, 0)
		local Name = Instance.new('TextLabel')
		Name.Parent = Frame
		Name.Position = UDim2.new(0.5, 0, 0, 5)
		Name.AnchorPoint = Vector2.new(0.5, 0)
		Name.Size = UDim2.new(1, 0, 0, 20)
		Name.BackgroundTransparency = 1
		Name.TextColor3 = Color3.fromRGB(255, 255, 255)
		Name.TextSize = 10
		Name.Text = 'Session Info'
		local SeperatorFrame = Instance.new('Frame')
		SeperatorFrame.Parent = Frame
		SeperatorFrame.Position = UDim2.new(0.5, 0, 0, 28)
		SeperatorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		SeperatorFrame.Size = UDim2.new(0.7, 0, 0, 2)
		SeperatorFrame.BorderSizePixel = 0
		SeperatorFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		local UIGradient = Instance.new('UIGradient')
        UIGradient.Parent = SeperatorFrame
        UIGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 155, 0))
        })
		local UIGradient2 = Instance.new('UIGradient')
        UIGradient2.Parent = Name
        UIGradient2.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 155, 0))
        })

		local lastRot = tick()
		local curPos = 0
		local funny = 1
		local Items = {}
		task.spawn(function()
			repeat
				task.wait()
				UIGradient.Offset += Vector2.new((1.5 * (tick() - lastRot)) * funny, 0)
				UIGradient2.Offset += Vector2.new((1.5 * (tick() - lastRot)) * funny, 0)

				if UIGradient2.Offset.X > 1 then
					funny = -1
				elseif UIGradient2.Offset.X < -1 then
					funny = 1
				end

				lastRot = tick()

				for i,v in self.Items do
					if not Items[i] then
						Items[i] = Instance.new('TextLabel')
						Items[i].Parent = Frame
						Items[i].Position = UDim2.fromOffset(20, 31 + (curPos * 22))
						Items[i].Size = UDim2.new(1, 0, 0, 21)
						Items[i].BackgroundTransparency = 1
						Items[i].TextXAlignment = Enum.TextXAlignment.Left
						Items[i].TextColor3 = Color3.fromRGB(255, 255, 255)
						Items[i].TextSize = 9
						Items[i].Text = i .. ': ' .. v.val .. v.goesby

						curPos += 1
					end

					Items[i].Text = i .. ': ' .. v.val .. v.goesby
				end
			until not Frame
		end)
	
		self.CurrentInfo = Frame

		return Frame
	end,
	AddItem = function(self, Name: string, goesby: string)
		self.Items[Name] = {
			val = 0,
			goesby = (goesby or '')
		};
	end,
	IncreaseItem = function(self, Name: string, Value: number)
		self.Items[Name].val += Value;
	end,
}

task.spawn(function()
	repeat
		task.wait(0.3)
		
		if not GuiLibrary then
			break
		end
		
		for i,v in GuiLibrary.TargetHud.Targets do
			if not v.Inst then
				v.Inst = GuiLibrary.TargetHud.Create(v.User)
			end
		end
		
		for i,v in TargetHUDFrame:GetChildren() do
			if v:IsA('UIListLayout') then continue end
			local found = false
			
			for _, item in GuiLibrary.TargetHud.Targets do
				if v == item.Inst then
					found = true
				end
			end
			
			if not found then
				v:Destroy()
			end
		end
	until false
end)

GuiLibrary.ArrayManager = {
    Enabled = false,
    Table = {},
    Create = function(self, Name)
        local Item = Instance.new('TextLabel')
        Item.Parent = ArrayFrame
        Item.BorderSizePixel = 0
        Item.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        Item.BackgroundTransparency = 0.4
        Item.TextColor3 = Color3.fromRGB(255, 70, 70)
        Item.TextSize = 15
        Item.Font = Enum.Font.FredokaOne
        Item.Text = '  ' .. Name .. '  '
        Item.Name = Name
        Item.Size = UDim2.new(0, getTextSize(Item).X + 6, 0, 24)
        Item.ZIndex = 3
        local Shadow = Instance.new('ImageLabel')
        Shadow.Parent = Item
        Shadow.BackgroundTransparency = 1
        Shadow.Image = 'rbxassetid://1316045217'
        Shadow.ScaleType = Enum.ScaleType.Slice
        Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
        Shadow.Size = UDim2.new(1, 12, 1, 12)
        Shadow.Position = UDim2.fromOffset(-10, -3)
        Shadow.ImageTransparency = 0.5
        Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        local SideFrame = Instance.new('Frame')
        SideFrame.Parent = Item
        SideFrame.Position = UDim2.fromScale(1, 0)
        SideFrame.Size = UDim2.new(0, 4, 1, 0)
        SideFrame.BorderSizePixel = 0
        SideFrame.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
        SideFrame.Name = 'SideFrame'

        ArrayFrame.Visible = self.Enabled

        table.insert(self.Table, Item)
        table.sort(self.Table, function(a, b)
            return getTextSize(a).X > getTextSize(b).X
        end)

        for i, v in self.Table do
            v.LayoutOrder = i
        end
    end,

    Remove = function(self, Name)
        for i, v in self.Table do
            if v.Name == Name then
                table.remove(self.Table, i)
                v:Destroy()
            end
        end

        ArrayFrame.Visible = self.Enabled
    end,
}

task.spawn(function()
	repeat
		task.wait()
		for i = 1, #GuiLibrary.ArrayManager.Table, 10 do
			local endIndex = math.min(i + 9, #GuiLibrary.ArrayManager.Table)
			for j = i, endIndex do
				local v = GuiLibrary.ArrayManager.Table[j]

				local red = math.floor(math.sin(j / 10) * 127 + 128)
				v.TextColor3 = Color3.fromRGB(red, 0, 0)
				v.SideFrame.BackgroundColor3 = v.TextColor3
			end
		end
	until not GuiLibrary.ScreenGui
end)

local WCount = 0
function GuiLibrary:GetWindow(Name: string)
	return GuiLibrary.Windows[Name]
end
function GuiLibrary:CreateWindow(Name: string)
	local MainLabel = Instance.new('TextLabel')
	MainLabel.Parent = ScreenGui
	MainLabel.Size = UDim2.fromOffset(200, 35)
	MainLabel.BorderSizePixel = 0
	MainLabel.Position = UDim2.fromOffset(50 + (WCount * 210), 75)
	MainLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
	MainLabel.Text = "  "..Name
	MainLabel.TextColor3 = Color3.fromRGB(255,0,0)
	MainLabel.TextXAlignment = Enum.TextXAlignment.Left
	MainLabel.TextSize = 10
	MainLabel.Visible = false
	local Modules = Instance.new('Frame')
	Modules.Parent = MainLabel
	Modules.Position = UDim2.fromScale(0, 1)
	Modules.Size = UDim2.fromScale(1, 0)
	Modules.AutomaticSize = Enum.AutomaticSize.Y
	Modules.BackgroundTransparency = 1
	local ModulesSort = Instance.new('UIListLayout')
	ModulesSort.Parent = Modules
	ModulesSort.SortOrder = Enum.SortOrder.LayoutOrder
	
	table.insert(GuiLibrary.Connections, UserInputService.InputBegan:Connect(function(Key, Gpe)
		if not UserInputService:GetFocusedTextBox() and Key.KeyCode == Enum.KeyCode.RightShift then
			MainLabel.Visible = not MainLabel.Visible
			UIBlur.Enabled = MainLabel.Visible
		end
	end))
	
	GuiLibrary.Windows[Name] = {
		Modules = {},
		CreateModule = function(self, Table)
			if not Config[Table.Name] then
				Config[Table.Name] = {
					Enabled = false,
					Keybind = 'Unknown',
					Toggles = {},
					Pickers = {},
					Sliders = {},
					Textboxes = {},
				}
			end
			
			local ModuleButton = Instance.new('TextButton')
			ModuleButton.Parent = Modules
			ModuleButton.Size = UDim2.new(1, 0, 0, 35)
			ModuleButton.BorderSizePixel = 0
			ModuleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			ModuleButton.TextXAlignment = Enum.TextXAlignment.Left
			ModuleButton.TextColor3 = Color3.fromRGB(150, 150, 150)
			ModuleButton.TextSize = 10
			ModuleButton.Text = '  ' .. Table.Name
			ModuleButton.AutoButtonColor = false
			local DropdownFrame = Instance.new('Frame')
			DropdownFrame.Parent = Modules
			DropdownFrame.Size = UDim2.fromScale(1, 0)
			DropdownFrame.AutomaticSize = Enum.AutomaticSize.Y
			DropdownFrame.BackgroundTransparency = 1
			DropdownFrame.Visible = false
			local DropdownSort = Instance.new('UIListLayout')
			DropdownSort.Parent = DropdownFrame
			DropdownSort.SortOrder = Enum.SortOrder.LayoutOrder
			local KeybindButton = Instance.new('TextButton')
			KeybindButton.Parent = DropdownFrame
			KeybindButton.Size = UDim2.new(1, 0, 0, 35)
			KeybindButton.BorderSizePixel = 0
			KeybindButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			KeybindButton.TextXAlignment = Enum.TextXAlignment.Left
			KeybindButton.TextColor3 = Color3.fromRGB(125, 125, 125)
			KeybindButton.TextSize = 10
			KeybindButton.Text = '  Keybind: <font color="rgb(125, 125, 125)">' .. Config[Table.Name].Keybind .. '</font>'
			KeybindButton.RichText = true
			KeybindButton.AutoButtonColor = false
			
			table.insert(GuiLibrary.Connections, KeybindButton.MouseEnter:Connect(function()
				TweenService:Create(KeybindButton, TweenInfo.new(0.1), {
					TextColor3 = Color3.fromRGB(200, 200, 200)
				}):Play()
			end))
			table.insert(GuiLibrary.Connections, KeybindButton.MouseLeave:Connect(function()
				TweenService:Create(KeybindButton, TweenInfo.new(0.1), {
					TextColor3 = Color3.fromRGB(125, 125, 125)
				}):Play()
			end))
			table.insert(GuiLibrary.Connections, KeybindButton.MouseButton1Down:Connect(function()
				local conn; conn = UserInputService.InputBegan:Connect(function(Key, Gpe)
					if not UserInputService:GetFocusedTextBox() and Key.KeyCode ~= Enum.KeyCode.Unknown then
						task.delay(0.01, function()
							local Str = tostring(Key.KeyCode):gsub('Enum.KeyCode.', '')

							if Str == Config[Table.Name].Keybind then
								Config[Table.Name].Keybind = 'Unknown'
							else
								Config[Table.Name].Keybind = Str
							end

							KeybindButton.Text = '  Keybind: <font color="rgb(125, 125, 125)">' .. Config[Table.Name].Keybind .. '</font>'
							save()
							conn:Disconnect();
						end)
					end
				end)
			end))
			
			local IsHovering = false
			local ModuleReturn = {Enabled = false, Connections = {}}
            function ModuleReturn:Start(thingy, func)
				if typeof(thingy) == "function" then
					table.insert(self.Connections, RunService.Heartbeat:Connect(thingy))
				elseif thingy and func and typeof(func) == "function" then
					table.insert(self.Connections, thingy:Connect(func))
				end
            end
            function ModuleReturn:End(func)
                for i,v in self.Connections do
                    v:Disconnect()
                end

                if func then
                    func()
                end
            end
			function ModuleReturn:Toggle(Silent: boolean)
				self.Enabled = not self.Enabled
				Config[Table.Name].Enabled = self.Enabled
				
				TweenService:Create(ModuleButton, TweenInfo.new(0.1), {
					TextColor3 = (self.Enabled and Color3.fromRGB(255,0,0) or (IsHovering and Color3.fromRGB(255,255,255) or Color3.fromRGB(150, 150, 150)))
				}):Play()

				if not ModuleReturn.Enabled then
					self:End()
				end
				
				if Table.Function then
					task.spawn(Table.Function, self.Enabled)
				end
				
				if self.Enabled then
					GuiLibrary.ArrayManager:Create(Table.Name)
				else
					GuiLibrary.ArrayManager:Remove(Table.Name)
				end
				
				save()
			end
			
			function ModuleReturn.CreateToggle(Tab)
				if not Config[Table.Name].Toggles[Tab.Name] then
					Config[Table.Name].Toggles[Tab.Name] = {Enabled = false}
				end
				
				local ToggleButton = Instance.new('TextButton')
				ToggleButton.Parent = DropdownFrame
				ToggleButton.Size = UDim2.new(1, 0, 0, 35)
				ToggleButton.BorderSizePixel = 0
				ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				ToggleButton.TextXAlignment = Enum.TextXAlignment.Left
				ToggleButton.TextColor3 = Color3.fromRGB(125, 125, 125)
				ToggleButton.TextSize = 10
				ToggleButton.Text = '  ' .. Tab.Name
				ToggleButton.AutoButtonColor = false
				
				local IsHovering = false
				
				local ToggleReturn = {Enabled = false}
				function ToggleReturn:Toggle()
					self.Enabled = not self.Enabled
					Config[Table.Name].Toggles[Tab.Name].Enabled = self.Enabled
					
					TweenService:Create(ToggleButton, TweenInfo.new(0.1), {
						TextColor3 = (self.Enabled and Color3.fromRGB(255, 255, 0) or (IsHovering and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(125, 125, 125)))
					}):Play()
					
					if Tab.Function then
						task.spawn(Tab.Function, self.Enabled)
					end
					
					save()
				end
				
				table.insert(GuiLibrary.Connections, ToggleButton.MouseEnter:Connect(function()
					IsHovering = true
					
					if not ToggleReturn.Enabled then
						TweenService:Create(ToggleButton, TweenInfo.new(0.1), {
							TextColor3 = Color3.fromRGB(200, 200, 200)
						}):Play()
					end
				end))
				table.insert(GuiLibrary.Connections, ToggleButton.MouseLeave:Connect(function()
					IsHovering = false
					
					if not ToggleReturn.Enabled then
						TweenService:Create(ToggleButton, TweenInfo.new(0.1), {
							TextColor3 = Color3.fromRGB(125, 125, 125)
						}):Play()
					end
				end))
				table.insert(GuiLibrary.Connections, ToggleButton.MouseButton1Down:Connect(function()
					ToggleReturn:Toggle()
				end))
				
				if Config[Table.Name].Toggles[Tab.Name].Enabled then
					ToggleReturn:Toggle()
				end
				
				return ToggleReturn
			end
			
			function ModuleReturn.CreatePicker(Tab)
				if not Config[Table.Name].Pickers[Tab.Name] then
					Config[Table.Name].Pickers[Tab.Name] = {Value = Tab.Default or Tab.Options[1]}
				end
				
				local PickerButton = Instance.new('TextButton')
				PickerButton.Parent = DropdownFrame
				PickerButton.Size = UDim2.new(1, 0, 0, 35)
				PickerButton.BorderSizePixel = 0
				PickerButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				PickerButton.TextXAlignment = Enum.TextXAlignment.Left
				PickerButton.TextColor3 = Color3.fromRGB(125, 125, 125)
				PickerButton.TextSize = 10
				PickerButton.Text = '  ' .. Tab.Name .. ': <font color="rgb(125,125,125)">' .. Config[Table.Name].Pickers[Tab.Name].Value..'</font>'
				PickerButton.RichText = true
				PickerButton.AutoButtonColor = false
				
				local PickerReturn = {Value = Config[Table.Name].Pickers[Tab.Name].Value}
				function PickerReturn:Set(Value: number)
					self.Value = Value
					Config[Table.Name].Pickers[Tab.Name].Value = self.Value
					
					PickerButton.Text = '  ' .. Tab.Name .. ': <font color="rgb(125,125,125)">' .. Config[Table.Name].Pickers[Tab.Name].Value.."</font>"

					if Tab.Function then
						task.spawn(Tab.Function, self.Value)
					end
					
					save()
				end
				
				local Index = 1
				for i,v in Tab.Options do
					if v == PickerReturn.Value then
						Index = i
						break
					end
				end
				
				table.insert(GuiLibrary.Connections, PickerButton.MouseButton1Down:Connect(function()
					Index += 1

					if Index > #Tab.Options then
						Index = 1
					end

					PickerReturn:Set(Tab.Options[Index])
				end))
				table.insert(GuiLibrary.Connections, PickerButton.MouseButton2Down:Connect(function()
					Index -= 1

					if Index < 1 then
						Index = #Tab.Options
					end

					PickerReturn:Set(Tab.Options[Index])
				end))
				table.insert(GuiLibrary.Connections, PickerButton.MouseEnter:Connect(function()
					TweenService:Create(PickerButton, TweenInfo.new(0.1), {
						TextColor3 = Color3.fromRGB(200, 200, 200)
					}):Play()
				end))
				table.insert(GuiLibrary.Connections, PickerButton.MouseLeave:Connect(function()
					TweenService:Create(PickerButton, TweenInfo.new(0.1), {
						TextColor3 = Color3.fromRGB(125, 125, 125)
					}):Play()
				end))

				PickerReturn:Set(Config[Table.Name].Pickers[Tab.Name].Value)
				
				return PickerReturn
			end
			
			function ModuleReturn.CreateSlider(Tab)
				if not Config[Table.Name].Sliders[Tab.Name] then
					Config[Table.Name].Sliders[Tab.Name] = {Value = Tab.Default or Tab.Maximum}
				end
				
				local SliderFrame = Instance.new('Frame')
				SliderFrame.Parent = DropdownFrame
				SliderFrame.Size = UDim2.new(1, 0, 0, 43)
				SliderFrame.BorderSizePixel = 0
				SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				local SliderText = Instance.new('TextLabel')
				SliderText.Parent = SliderFrame
				SliderText.Size = UDim2.new(1, 0, 0, 30)
				SliderText.BackgroundTransparency = 1
				SliderText.TextXAlignment = Enum.TextXAlignment.Left
				SliderText.TextColor3 = Color3.fromRGB(125, 125, 125)
				SliderText.TextSize = 10
				SliderText.Text = '  ' .. Tab.Name
				SliderText.RichText = true
				local DisplayText = Instance.new('TextLabel')
				DisplayText.Parent = SliderFrame
				DisplayText.Size = UDim2.new(1, -7, 0, 30)
				DisplayText.BackgroundTransparency = 1
				DisplayText.TextXAlignment = Enum.TextXAlignment.Right
				DisplayText.TextColor3 = Color3.fromRGB(125, 125, 125)
				DisplayText.TextSize = 10
				DisplayText.Text = Config[Table.Name].Sliders[Tab.Name].Value
				local SliderBGFrame = Instance.new('TextButton')
				SliderBGFrame.Parent = SliderFrame
				SliderBGFrame.Size = UDim2.new(1, -15, 0, 6)
				SliderBGFrame.Position = UDim2.new(0, 8, 0, 28)
				SliderBGFrame.BorderSizePixel = 0
				SliderBGFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				SliderBGFrame.AutoButtonColor = false
				SliderBGFrame.Text = ''
				local SliderOverlay = Instance.new('Frame')
				SliderOverlay.Parent = SliderBGFrame
				SliderOverlay.Size = UDim2.fromScale(0.5, 1)
				SliderOverlay.BorderSizePixel = 0
				SliderOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
				
				local SliderReturn = {Value = Config[Table.Name].Sliders[Tab.Name].Value}
				function SliderReturn:Set(Value: number)
					Value = math.round(math.clamp(Value, Tab.Minimum, Tab.Maximum))
					
					self.Value = Value
					Config[Table.Name].Sliders[Tab.Name].Value = self.Value
					
					DisplayText.Text = self.Value
					TweenService:Create(SliderOverlay, TweenInfo.new(0.25), {Size = UDim2.fromScale((Value - Tab.Minimum) / (Tab.Maximum - Tab.Minimum), 1)}):Play()

					if Tab.Function then
						task.spawn(Tab.Function, Value)
					end
					
					save()
				end
				
				local Dragging = false
				table.insert(GuiLibrary.Connections, SliderBGFrame.MouseButton1Down:Connect(function()
					Dragging = true
				end))
				table.insert(GuiLibrary.Connections, UserInputService.InputEnded:Connect(function(Key, Gpe)
					if Key.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = false
					end
				end))
				table.insert(GuiLibrary.Connections, SliderFrame.MouseEnter:Connect(function()
					TweenService:Create(SliderText, TweenInfo.new(0.1), {
						TextColor3 = Color3.fromRGB(200, 200, 200)
					}):Play()
				end))
				table.insert(GuiLibrary.Connections, SliderFrame.MouseLeave:Connect(function()
					TweenService:Create(SliderText, TweenInfo.new(0.1), {
						TextColor3 = Color3.fromRGB(125, 125, 125)
					}):Play()
				end))
				
				table.insert(GuiLibrary.Connections, RunService.Heartbeat:Connect(function()
					if Dragging then
						local mouse = UserInputService:GetMouseLocation().X
						local absPos = SliderBGFrame.AbsolutePosition.X
						local absSize = SliderBGFrame.AbsoluteSize.X
						
						local Percent = math.clamp((mouse - absPos) / absSize, 0, 1)
						local Value = Tab.Minimum + (Tab.Maximum - Tab.Minimum) * Percent
						
						SliderReturn:Set(Value)
					end
				end))
				
				SliderReturn:Set(Config[Table.Name].Sliders[Tab.Name].Value)
				
				return SliderReturn
			end
			
			table.insert(GuiLibrary.Connections, ModuleButton.MouseEnter:Connect(function()
				IsHovering = true
				WasHovering = true
				
				if not ModuleReturn.Enabled then
					TweenService:Create(ModuleButton, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
				end
			end))
			table.insert(GuiLibrary.Connections, ModuleButton.MouseLeave:Connect(function()
				IsHovering = false
				WasHovering = false
				
				if not ModuleReturn.Enabled then
					TweenService:Create(ModuleButton, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
				end
			end))
			table.insert(GuiLibrary.Connections, ModuleButton.MouseButton1Down:Connect(function()
				ModuleReturn:Toggle(false)
			end))
			table.insert(GuiLibrary.Connections, ModuleButton.MouseButton2Down:Connect(function()
				DropdownFrame.Visible = not DropdownFrame.Visible
			end))
			table.insert(GuiLibrary.Connections, UserInputService.InputBegan:Connect(function(Key, Gpe)
				if not UserInputService:GetFocusedTextBox() and Key.KeyCode ~= Enum.KeyCode.Unknown and Key.KeyCode == Enum.KeyCode[Config[Table.Name].Keybind] then
					ModuleReturn:Toggle(false)
				end
			end))
			
			if Config[Table.Name].Enabled then
				task.delay(0.1, function()
					ModuleReturn:Toggle(true)
				end)
			end
			
			table.insert(self.Modules, ModuleReturn)
			
			return ModuleReturn
		end,
	}
	
	WCount += 1
	
	return GuiLibrary.Windows[Name]
end

local function uninject(reload: boolean)
	cansave = false

	for _, win in GuiLibrary.Windows do
		for _, tab in win.Modules do
			if tab.Enabled then
				tab:Toggle(true)
			end
		end
	end

	for i,v in GuiLibrary.Connections do
		v:Disconnect()
	end

	task.delay(0.1, function()
		ScreenGui:Destroy()
		UIBlur:Destroy()

		GuiLibrary = nil
		shared.GuiLibrary = nil

		workspace:FindFirstChild('Instances Folder'):Destroy()

		if reload then
			loadfile('Novoline/core.lua')()
		end
	end)
end

GuiLibrary.Uninject = uninject

shared.GuiLibrary = GuiLibrary

return GuiLibrary