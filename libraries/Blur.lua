--[[
   Credits to the devforum (@BestTime101) for making such a plugin;
   https://create.roblox.com/store/asset/15903056350/User-Interface-Blur;
]]


local Config = {}

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local objects = game:GetObjects('rbxassetid://15903056350')[1];
objects.Parent = game;
Config.BlurPlane = objects:FindFirstChild('Plane');
Config.BlurCircle = objects:FindFirstChild('Circle');

Config.BlurObjectFolder = Instance.new('Folder', workspace) -- Feel free to change

Config.DefaultIntensity = 0.75 -- Intensity of blur (Does not effect pdbding) (Default 0.75)
Config.DefaultPadding = -6 -- Used to compensate for blur overlapping around the UI's edges (Default -6)
Config.DistanceFromHead = 0.2 -- Set to a higher value if you start to experience graphical floating point precision artifacts. (Default 0.2)

Config.TopbarInset = 0 -- Don't know if its consistant across all platforms

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local BlurObject = {}

function BlurObject.new(Adornee: GuiObject, Padding: number, CornerRadius: UDim, Rotation: number): BlurObject
	if not Config.BlurPlane then 
        repeat task.wait() until Config.BlurPlane;
    end;
	local MainAxis: BasePart = Config.BlurPlane:Clone()
	local SecondaryAxis: BasePart
	local BottomLeft: BasePart
	local BottomRight: BasePart
	local TopLeft: BasePart
	local TopRight: BasePart
	
	if CornerRadius.Offset > 0 or CornerRadius.Scale > 0 or math.abs(Padding) > 0 then
		SecondaryAxis = Config.BlurPlane:Clone()
		BottomLeft = Config.BlurCircle:Clone()
		BottomRight = Config.BlurCircle:Clone()
		TopLeft = Config.BlurCircle:Clone()
		TopRight = Config.BlurCircle:Clone()
	end
	
	local self = {}
	
	self.Visible = true
	
	self.Adornee = Adornee
	
	self.Padding = Padding+Config.DefaultPadding
	self.CornerRadius = CornerRadius
	self.Rotation = Rotation
	
	self.Screen = nil
	self.BaseParts = table.pack(MainAxis, SecondaryAxis, BottomLeft, BottomRight, TopLeft, TopRight)
	self.IndexRender = nil
	
	function self:Render()
		
		local IndexRender = {}
		
		local Rotation = Rotation
		local PixelSize = Adornee.AbsoluteSize + (Vector2.one*self.Padding*2)
		local PixelPosition = Adornee.AbsolutePosition+Vector2.new(0, game:GetService('GuiService'):GetGuiInset().Y + Config.TopbarInset) - (Vector2.one*self.Padding)
		
		local Radius = math.clamp((self.CornerRadius.Scale + (self.CornerRadius.Offset+self.Padding)/math.min(PixelSize.X, PixelSize.Y))*2, 0, 1)

		local Bounds = workspace.CurrentCamera.ViewportSize
		
		local Aspect = Vector3.new(Bounds.X / Bounds.Y, 1, 1)

		local ScaledSize = Vector3.new(PixelSize.X/Bounds.X, PixelSize.Y/Bounds.Y, 0)
		local ScaledPosition = Vector3.new(PixelPosition.X/Bounds.X+ScaledSize.X/2, -(PixelPosition.Y/Bounds.Y+ScaledSize.Y/2), 0)*Aspect
		
		local CornerX = (Radius/math.max(PixelSize.X, PixelSize.Y)*PixelSize.Y)
		local CornerY = (Radius/math.max(PixelSize.X, PixelSize.Y)*PixelSize.X)
		
		table.insert(IndexRender, ScaledPosition-Vector3.new(0.5, -0.5, 0)*Aspect)
		table.insert(IndexRender, ScaledSize*Vector3.new(1-CornerX, 1, 1)*Aspect)
		
		table.insert(IndexRender, ScaledPosition-Vector3.new(0.5, -0.5, 0)*Aspect)
		table.insert(IndexRender, ScaledSize*Vector3.new(1, 1-CornerY, 1)*Aspect)
		
		local CornerOffset = Vector3.new(ScaledSize.X/2, ScaledSize.Y/2, 0) * Aspect - (ScaledSize*Vector3.new(CornerX, CornerY, 1)*Aspect/2)
		
		local TopLeft = Vector3.new(CornerOffset.X, CornerOffset.Y)
		local TopRight = Vector3.new(CornerOffset.X, -CornerOffset.Y)
		local BottomLeft = Vector3.new(-CornerOffset.X, CornerOffset.Y)
		local BottomRight = Vector3.new(-CornerOffset.X, -CornerOffset.Y)
		
		table.insert(IndexRender, (ScaledPosition+TopLeft)-Vector3.new(0.5, -0.5, 0)*Aspect)
		table.insert(IndexRender, ScaledSize*Vector3.new(CornerX, CornerY, 1)*Aspect)
		
		table.insert(IndexRender, (ScaledPosition+TopRight)-Vector3.new(0.5, -0.5, 0)*Aspect)
		table.insert(IndexRender, ScaledSize*Vector3.new(CornerX, CornerY, 1)*Aspect)
		
		table.insert(IndexRender, (ScaledPosition+BottomLeft)-Vector3.new(0.5, -0.5, 0)*Aspect)
		table.insert(IndexRender, ScaledSize*Vector3.new(CornerX, CornerY, 1)*Aspect)
		
		table.insert(IndexRender, (ScaledPosition+BottomRight)-Vector3.new(0.5, -0.5, 0)*Aspect)
		table.insert(IndexRender, ScaledSize*Vector3.new(CornerX, CornerY, 1)*Aspect)

		self.IndexRender = IndexRender

		return
	end
	
	function self:Step()
		if not self.Visible then
			return
		end
		local CameraCFrame = workspace.CurrentCamera.CFrame
		local SolvedFov = math.tan(math.rad(workspace.CurrentCamera.FieldOfView/2))*2
		for i, v in ipairs(self.BaseParts) do
			if not v then
				continue
			end
			v.Size = self.IndexRender[i*2]*(Config.DistanceFromHead*SolvedFov)
			v.CFrame = CameraCFrame*CFrame.new(self.IndexRender[i*2-1]*Config.DistanceFromHead*SolvedFov)*CFrame.new(0, 0, -Config.DistanceFromHead)
		end
	end	
	
	function self:SetVisible(Bool: boolean)
		if Bool == nil then
			Bool = true
		end
		self.Visible = Bool
		for _, v in ipairs(self.BaseParts) do
			if not v then
				continue
			end
			v.Parent = Bool and Config.BlurObjectFolder or nil
		end
		return
	end
	
	function self:SetInvisible(Bool: boolean)
		if Bool == nil then
			Bool = true
		end
		return self:SetVisible(not Bool)
	end
	
	function self:Destroy()
		for _, v in ipairs(self.BaseParts) do
			if not v then
				continue
			end
			v:Remove()
		end
		return
	end
	
	self.Adornee.Destroying:Connect(function()
		self:Destroy()
	end)
	
	Adornee:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
		self:Render()
	end)
	Adornee:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		self:Render()
	end)
	
	local function AdorneeWithin(Ins)
		if Ins == self.Adornee then
			return true
		end
		for _, v: Instance in pairs(Ins:GetDescendants()) do
			if v == self.Adornee then
				return true
			end
		end
		return
	end
	
	local function CheckForBaseGui(Location)
		if Location:IsA('GuiObject') then
			local Connection: RBXScriptConnection
			Connection = Location:GetPropertyChangedSignal('Visible'):Connect(function()
				if not AdorneeWithin(Location) then
					Connection:Disconnect()
					return
				end
				self:SetVisible(Location.Visible)
				return
			end)
			elseif Location:IsA('ScreenGui') then
			return
		end
		return CheckForBaseGui(Location.Parent)
	end
	
	CheckForBaseGui(Adornee)
	
	self.Screen = Adornee:FindFirstAncestorOfClass('ScreenGui')
	
	self.Screen:GetPropertyChangedSignal('Enabled'):Connect(function()
		self:SetVisible(self.Screen.Enabled)
	end)
	
	self.Screen:GetPropertyChangedSignal('Parent'):Connect(function()
		self:SetVisible(self.Screen:FindFirstAncestorOfClass('PlayerGui') ~= nil)
	end)
	
	self.Adornee:GetPropertyChangedSignal('Parent'):Connect(function()
		if not self.Adornee.Parent then
			return
		end
		CheckForBaseGui(Adornee)
	end)
	
	self:SetVisible()
	self:Render()
	
	return setmetatable(self, {__newindex = {}})
end

export type BlurObject = typeof(BlurObject.new(...))

local InterfaceBlur = {}

InterfaceBlur.BlurObjects = {}

function InterfaceBlur:AddBlur(UI: GuiObject, Padding: number): BlurObject
	
	local CornerRadius: UDim = UDim.new(0, 0)
	
	local UICorner = UI:FindFirstChildOfClass('UICorner')
	if UICorner then
		CornerRadius = UICorner.CornerRadius
	end

	UI.Destroying:Once(function()
		self:RemoveBlur(UI);
	end);

	local BlurObject = BlurObject.new(UI, Padding, CornerRadius, 0)
	
	self.BlurObjects[UI] = BlurObject
	
	return BlurObject
end

function InterfaceBlur:AddBlurToInstance(Screen: Instance, Padding: number, NamePattern: string, Consistent: boolean): nil
	
	local function Check(Ins)
		if not Ins:IsA('GuiObject') then
			return
		end
		if not string.find(Ins.Name, NamePattern) then
			return
		end
		return self:AddBlur(Ins, Padding)
	end
	
	for _, Ins in pairs(Screen:GetDescendants()) do
		Check(Ins)
	end
	
	if not Consistent then
		return
	end
	
	Screen.DescendantAdded:Connect(function(Ins)
		Check(Ins)
	end)
	return
end

function InterfaceBlur:AddBlurToScreenGui(ScreenName: string, Padding: number, NamePattern: string, Consistent: boolean): nil
	local Core: PlayerGui = game.Players.LocalPlayer:WaitForChild'PlayerGui'
	local function TestForScreen(Ins)
		if not Ins:IsA('ScreenGui') then
			return
		end
		if not (Ins.Name == ScreenName) then
			return
		end
		return self:AddBlurToInstance(Ins, Padding, NamePattern, Consistent)
	end
	for _, Ins in pairs(Core:GetChildren()) do
		TestForScreen(Ins)
	end
	Core.ChildAdded:Connect(function(Ins)
		TestForScreen(Ins)
	end)
end

function InterfaceBlur:RemoveBlur(UI: GuiBase)
	
	if not self.BlurObjects[UI] then
		return
	end
	
	self.BlurObjects[UI]:Destroy()
	self.BlurObjects[UI] = nil
	
	return
end

local function CreateDepth(): DepthOfFieldEffect
	local Depth: DepthOfFieldEffect = Instance.new('DepthOfFieldEffect', game.Lighting)
	
	Depth.Name = 'InterfaceBlurEffect'
	
	Depth.Enabled = true
	
	Depth.FarIntensity = 0
	Depth.NearIntensity = 0
	
	Depth.FocusDistance = 0
	Depth.InFocusRadius = 0
	
	return Depth
end

local PreusedDepth: DepthOfFieldEffect = game.Lighting:FindFirstChildOfClass('DepthOfFieldEffect')

local Depth: DepthOfFieldEffect

if not PreusedDepth then
	Depth = CreateDepth()
end

game:GetService('Lighting').ChildAdded:Connect(function(Ins)
	if not Ins:IsA('DepthOfFieldEffect') then
		return
	end
	if not Depth then
		return
	end
	Depth:Remove()
	
	PreusedDepth = Ins
end)

function InterfaceBlur:SetBlurIntensity(Intensity: number)
	Intensity = Intensity or Config.DefaultIntensity
	
	local Depth = Depth or PreusedDepth
	
	Depth.Enabled = true
	Depth.FocusDistance = math.max(Config.DistanceFromHead+0.1, Depth.FocusDistance)
	Depth.NearIntensity = Intensity
	return
end

function InterfaceBlur:EnableBlurs(Bool: boolean)
	if Bool == nil then
		Bool = true
	end
	for _, v: BlurObject in pairs(InterfaceBlur.BlurObjects) do
		if not v then
			continue
		end
		v:SetVisible(Bool)
	end
end
function InterfaceBlur:DisableBlurs(Bool: boolean)
	if Bool == nil then
		Bool = true
	end
	self:EnableBlurs(not Bool)
end

local Camera = workspace.CurrentCamera

game:GetService('RunService'):BindToRenderStep('InterfaceBlur', Enum.RenderPriority.Camera.Value+1, function()
	for Adornee: GuiObject, v: BlurObject in pairs(InterfaceBlur.BlurObjects) do
		if not v then
			continue
		end
		if not Adornee.Parent then
			InterfaceBlur.BlurObjects[Adornee] = nil
			continue
		end
		v:Step()
	end
end)

return InterfaceBlur