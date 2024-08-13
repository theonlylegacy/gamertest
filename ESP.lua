local Workspace, RunService, Players, CoreGui, Lighting = cloneref(game:GetService("Workspace")), cloneref(game:GetService("RunService")), cloneref(game:GetService("Players")), game:GetService("CoreGui"), cloneref(game:GetService("Lighting"))

local Floor = math.floor
local RGB = Color3.fromRGB
local TSpawn, TCancel = task.spawn, task.cancel
local TInsert = table.insert

local RequireFunc = nil do
	for _, Object in getnilinstances() do
		if string.find(Object.Name, "ClientLoader") then
			RequireFunc = getsenv(Object).shared.require
			break
		end
	end
end

local CharacterInterface = RequireFunc("CharacterInterface")
local ReplicationInterface = RequireFunc("ReplicationInterface")
local WeaponControllerInterface = RequireFunc("WeaponControllerInterface")
local RoundSystemClientInterface = RequireFunc("RoundSystemClientInterface")

local Threads = {}
local Connections = {}

local ESP = {
	Enabled = false,
	TeamCheck = true,
	MaxDistance = 1000,
	FontSize = 11,

	FadeOut = {
		OnDistance = true,
		OnDeath = false,
		OnLeave = false,
	},

	Options = { 
		Teamcheck = false, TeamcheckRGB = RGB(0, 255, 0),
		Friendcheck = true, FriendcheckRGB = RGB(0, 255, 0),
		Highlight = false, HighlightRGB = RGB(255, 0, 0),
	},

	Drawing = {
		Chams = {
			Enabled = false,
			Thermal = true,
			FillRGB = RGB(119, 120, 255),
			Fill_Transparency = 100,
			OutlineRGB = RGB(119, 120, 255),
			Outline_Transparency = 100,
			VisibleCheck = true,
		},

		Names = {
			Enabled = true,
			RGB = RGB(255, 255, 255),
		},

		Distances = {
			Enabled = false, 
			Position = "Text",
			RGB = RGB(255, 255, 255),
		},

		Weapons = {
			Enabled = false, WeaponTextRGB = RGB(119, 120, 255),
			Outlined = false,
			Gradient = false,
			GradientRGB1 = RGB(255, 255, 255), GradientRGB2 = RGB(119, 120, 255),
		},

		Healthbar = {
			Enabled = false,  
			HealthText = true, Lerp = false, HealthTextRGB = RGB(119, 120, 255),
			Width = 2.5,
			Gradient = true, GradientRGB1 = RGB(200, 0, 0), GradientRGB2 = RGB(60, 60, 125), GradientRGB3 = RGB(119, 120, 255), 
		},

		Boxes = {
			Animate = true,
			RotationSpeed = 300,
			Gradient = false, GradientRGB1 = RGB(119, 120, 255), GradientRGB2 = RGB(0, 0, 0), 
			GradientFill = true, GradientFillRGB1 = RGB(119, 120, 255), GradientFillRGB2 = RGB(0, 0, 0), 
			Filled = {
				Enabled = true,
				Transparency = 0.75,
				RGB = RGB(0, 0, 0),
			},

			Full = {
				Enabled = true,
				RGB = RGB(255, 255, 255),
			},

			Corner = {
				Enabled = true,
				RGB = RGB(255, 255, 255),
			},
		},
	},

	Connections = {
		RunService = RunService;
	},

	Fonts = {},
}

local Euphoria = ESP.Connections;
local Client = Players.LocalPlayer;
local camera = Workspace.CurrentCamera;
local Cam = Workspace.CurrentCamera;
local RotationAngle, Tick = -45, tick();

local Weapon_Icons = {
	["Wooden Bow"] = "http://www.roblox.com/asset/?id=17677465400",
	["Crossbow"] = "http://www.roblox.com/asset/?id=17677473017",
	["Salvaged SMG"] = "http://www.roblox.com/asset/?id=17677463033",
	["Salvaged AK47"] = "http://www.roblox.com/asset/?id=17677455113",
	["Salvaged AK74u"] = "http://www.roblox.com/asset/?id=17677442346",
	["Salvaged M14"] = "http://www.roblox.com/asset/?id=17677444642",
	["Salvaged Python"] = "http://www.roblox.com/asset/?id=17677451737",
	["Military PKM"] = "http://www.roblox.com/asset/?id=17677449448",
	["Military M4A1"] = "http://www.roblox.com/asset/?id=17677479536",
	["Bruno's M4A1"] = "http://www.roblox.com/asset/?id=17677471185",
	["Military Barrett"] = "http://www.roblox.com/asset/?id=17677482998",
	["Salvaged Skorpion"] = "http://www.roblox.com/asset/?id=17677459658",
	["Salvaged Pump Action"] = "http://www.roblox.com/asset/?id=17677457186",
	["Military AA12"] = "http://www.roblox.com/asset/?id=17677475227",
	["Salvaged Break Action"] = "http://www.roblox.com/asset/?id=17677468751",
	["Salvaged Pipe Rifle"] = "http://www.roblox.com/asset/?id=17677468751",
	["Salvaged P250"] = "http://www.roblox.com/asset/?id=17677447257",
	["Nail Gun"] = "http://www.roblox.com/asset/?id=17677484756"
};

local Functions = {}
do
	function Functions:Create(Class, Properties)
		local _Instance = typeof(Class) == 'string' and Instance.new(Class) or Class
		for Property, Value in pairs(Properties) do
			_Instance[Property] = Value
		end
		return _Instance;
	end
	--
	function Functions:FadeOutOnDist(element, distance)
		local transparency = math.max(0.1, 1 - (distance / ESP.MaxDistance))
		if element:IsA("TextLabel") then
			element.TextTransparency = 1 - transparency
		elseif element:IsA("ImageLabel") then
			element.ImageTransparency = 1 - transparency
		elseif element:IsA("UIStroke") then
			element.Transparency = 1 - transparency
		elseif element:IsA("Frame") and (element == nil or element == nil) then
			element.BackgroundTransparency = 1 - transparency
		elseif element:IsA("Frame") then
			element.BackgroundTransparency = 1 - transparency
		elseif element:IsA("Highlight") then
			element.FillTransparency = 1 - transparency
			element.OutlineTransparency = 1 - transparency
		end
	end
end

do
	local ScreenGui = Functions:Create("ScreenGui", {
		Parent = CoreGui,
		DisplayOrder = 2,
		Name = "ESPHolder",
	});

	function ESP:Unload()
		for _, v in Connections do
			v:Disconnect()
		end

		ScreenGui:Destroy()
	end

	local DupeCheck = function(Player)
		if ScreenGui:FindFirstChild(Player.Name) then
			ScreenGui[Player.Name]:Destroy()
		end
	end

	local ESP = function(Player)
		local Drawings = ESP.Drawing

		DupeCheck(Player)
		local Name = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, -11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = RGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = RGB(0, 0, 0), RichText = true})
		local Distance = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = RGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = RGB(0, 0, 0), RichText = true})
		local Weapon = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = RGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = RGB(0, 0, 0), RichText = true})
		local Box = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = RGB(0, 0, 0), BackgroundTransparency = 0.75, BorderSizePixel = 0})
		local Gradient1 = Functions:Create("UIGradient", {Parent = Box, Enabled = Drawings.Boxes.GradientFill, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Drawings.Boxes.GradientFillRGB1), ColorSequenceKeypoint.new(1, Drawings.Boxes.GradientFillRGB2)}})
		local Outline = Functions:Create("UIStroke", {Parent = Box, Enabled = Drawings.Boxes.Gradient, Transparency = 0, Color = RGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter})
		local Gradient2 = Functions:Create("UIGradient", {Parent = Outline, Enabled = Drawings.Boxes.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Drawings.Boxes.GradientRGB1), ColorSequenceKeypoint.new(1, Drawings.Boxes.GradientRGB2)}})
		local Healthbar = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = RGB(255, 255, 255), BackgroundTransparency = 0})
		local BehindHealthbar = Functions:Create("Frame", {Parent = ScreenGui, ZIndex = -1, BackgroundColor3 = RGB(0, 0, 0), BackgroundTransparency = 0})
		local HealthbarGradient = Functions:Create("UIGradient", {Parent = Healthbar, Enabled = Drawings.Healthbar.Gradient, Rotation = -90, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Drawings.Healthbar.GradientRGB1), ColorSequenceKeypoint.new(0.5, Drawings.Healthbar.GradientRGB2), ColorSequenceKeypoint.new(1, Drawings.Healthbar.GradientRGB3)}})
		local HealthText = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = RGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = RGB(0, 0, 0)})
		local Chams = Functions:Create("Highlight", {Parent = ScreenGui, FillTransparency = 1, OutlineTransparency = 0, OutlineColor = RGB(119, 120, 255), DepthMode = "AlwaysOnTop"})
		local WeaponIcon = Functions:Create("ImageLabel", {Parent = ScreenGui, BackgroundTransparency = 1, BorderColor3 = RGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 40, 0, 40)})
		local Gradient3 = Functions:Create("UIGradient", {Parent = WeaponIcon, Rotation = -90, Enabled = Drawings.Weapons.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Drawings.Weapons.GradientRGB1), ColorSequenceKeypoint.new(1, Drawings.Weapons.GradientRGB2)}})
		local LeftTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local LeftSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local RightTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local RightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local BottomSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local BottomDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local BottomRightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local BottomRightDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Drawings.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
		local Flag1 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = RGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = RGB(0, 0, 0)})
		local Flag2 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = RGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = RGB(0, 0, 0)})


		local Updater = function()
			local Connection
			local function HideESP()
				Box.Visible = false;
				Name.Visible = false;
				Distance.Visible = false;
				Weapon.Visible = false;
				Healthbar.Visible = false;
				BehindHealthbar.Visible = false;
				HealthText.Visible = false;
				WeaponIcon.Visible = false;
				LeftTop.Visible = false;
				LeftSide.Visible = false;
				BottomSide.Visible = false;
				BottomDown.Visible = false;
				RightTop.Visible = false;
				RightSide.Visible = false;
				BottomRightSide.Visible = false;
				BottomRightDown.Visible = false;
				Flag1.Visible = false;
				Chams.Enabled = false;
				Flag2.Visible = false;
				if not Player then
					ScreenGui:Destroy()
					Connection:Disconnect()
				end
			end

			Connection = TInsert(Connections, Euphoria.RunService.RenderStepped:Connect(function()
				local Entry = ReplicationInterface.getEntry(Player)
				local ThirdPersonObject = Entry and Entry:getThirdPersonObject()
				local Root = ThirdPersonObject and ThirdPersonObject._root
				local Character = Root and Root.Parent
				local EntityHealth = Entry and Entry:getHealth()
				local PName = Player.Name
				local Drawings = ESP.Drawing

				if Character and Root and EntityHealth and EntityHealth > 0 and WeaponControllerInterface:getActiveWeaponController() and not RoundSystemClientInterface.roundLock ESP.Enabled then
					local Pos, OnScreen = Cam:WorldToScreenPoint(Root.Position)
					local Dist = (Cam.CFrame.Position - Root.Position).Magnitude / 3.5714285714

					if OnScreen and Dist <= ESP.MaxDistance then
						local Size = Root.Size.Y
						local scaleFactor = (Size * Cam.ViewportSize.Y) / (Pos.Z * 2)
						local w, h = 3 * scaleFactor, 4.5 * scaleFactor

						if ESP.FadeOut.OnDistance then
							Functions:FadeOutOnDist(Box, Dist)
							Functions:FadeOutOnDist(Outline, Dist)
							Functions:FadeOutOnDist(Name, Dist)
							Functions:FadeOutOnDist(Distance, Dist)
							Functions:FadeOutOnDist(Weapon, Dist)
							Functions:FadeOutOnDist(Healthbar, Dist)
							Functions:FadeOutOnDist(BehindHealthbar, Dist)
							Functions:FadeOutOnDist(HealthText, Dist)
							Functions:FadeOutOnDist(WeaponIcon, Dist)
							Functions:FadeOutOnDist(LeftTop, Dist)
							Functions:FadeOutOnDist(LeftSide, Dist)
							Functions:FadeOutOnDist(BottomSide, Dist)
							Functions:FadeOutOnDist(BottomDown, Dist)
							Functions:FadeOutOnDist(RightTop, Dist)
							Functions:FadeOutOnDist(RightSide, Dist)
							Functions:FadeOutOnDist(BottomRightSide, Dist)
							Functions:FadeOutOnDist(BottomRightDown, Dist)
							Functions:FadeOutOnDist(Chams, Dist)
							Functions:FadeOutOnDist(Flag1, Dist)
							Functions:FadeOutOnDist(Flag2, Dist)
						end

						if ESP.TeamCheck and Player ~= Client and ((Client.Team ~= Player.Team and Player.Team) or (not Client.Team and not Player.Team)) then

							do 
								Chams.Adornee = Character
								Chams.Enabled = Drawings.Chams.Enabled
								Chams.FillColor = Drawings.Chams.FillRGB
								Chams.OutlineColor = Drawings.Chams.OutlineRGB
								do
									if Drawings.Chams.Thermal then
										local breathe_effect = math.atan(math.sin(tick() * 2)) * 2 / math.pi
										Chams.FillTransparency = Drawings.Chams.Fill_Transparency * breathe_effect * 0.01
										Chams.OutlineTransparency = Drawings.Chams.Outline_Transparency * breathe_effect * 0.01
									end
								end
								if Drawings.Chams.VisibleCheck then
									Chams.DepthMode = "Occluded"
								else
									Chams.DepthMode = "AlwaysOnTop"
								end
							end

							do
								LeftTop.Visible = Drawings.Boxes.Corner.Enabled
								LeftTop.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
								LeftTop.Size = UDim2.new(0, w / 5, 0, 1)

								LeftSide.Visible = Drawings.Boxes.Corner.Enabled
								LeftSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
								LeftSide.Size = UDim2.new(0, 1, 0, h / 5)

								BottomSide.Visible = Drawings.Boxes.Corner.Enabled
								BottomSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2)
								BottomSide.Size = UDim2.new(0, 1, 0, h / 5)
								BottomSide.AnchorPoint = Vector2.new(0, 5)

								BottomDown.Visible = Drawings.Boxes.Corner.Enabled
								BottomDown.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2)
								BottomDown.Size = UDim2.new(0, w / 5, 0, 1)
								BottomDown.AnchorPoint = Vector2.new(0, 1)

								RightTop.Visible = Drawings.Boxes.Corner.Enabled
								RightTop.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y - h / 2)
								RightTop.Size = UDim2.new(0, w / 5, 0, 1)
								RightTop.AnchorPoint = Vector2.new(1, 0)

								RightSide.Visible = Drawings.Boxes.Corner.Enabled
								RightSide.Position = UDim2.new(0, Pos.X + w / 2 - 1, 0, Pos.Y - h / 2)
								RightSide.Size = UDim2.new(0, 1, 0, h / 5)
								RightSide.AnchorPoint = Vector2.new(0, 0)

								BottomRightSide.Visible = Drawings.Boxes.Corner.Enabled
								BottomRightSide.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2)
								BottomRightSide.Size = UDim2.new(0, 1, 0, h / 5)
								BottomRightSide.AnchorPoint = Vector2.new(1, 1)

								BottomRightDown.Visible = Drawings.Boxes.Corner.Enabled
								BottomRightDown.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2)
								BottomRightDown.Size = UDim2.new(0, w / 5, 0, 1)
								BottomRightDown.AnchorPoint = Vector2.new(1, 1)                                                            
							end

							do
								Box.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
								Box.Size = UDim2.new(0, w, 0, h)
								Box.Visible = Drawings.Boxes.Full.Enabled;

								if Drawings.Boxes.Filled.Enabled then
									Box.BackgroundColor3 = RGB(255, 255, 255)
									if Drawings.Boxes.GradientFill then
										Box.BackgroundTransparency = Drawings.Boxes.Filled.Transparency;
									else
										Box.BackgroundTransparency = 1
									end
									Box.BorderSizePixel = 1
								else
									Box.BackgroundTransparency = 1
								end

								RotationAngle = RotationAngle + (tick() - Tick) * Drawings.Boxes.RotationSpeed * math.cos(math.pi / 4 * tick() - math.pi / 2)

								if Drawings.Boxes.Animate then
									Gradient1.Rotation = RotationAngle
									Gradient2.Rotation = RotationAngle
								else
									Gradient1.Rotation = -45
									Gradient2.Rotation = -45
								end

								Tick = tick()
							end

							do  
								local Health = EntityHealth / 100;
								Healthbar.Visible = Drawings.Healthbar.Enabled;
								Healthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - Health))  
								Healthbar.Size = UDim2.new(0, Drawings.Healthbar.Width, 0, h * Health)  

								BehindHealthbar.Visible = Drawings.Healthbar.Enabled;
								BehindHealthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2)  
								BehindHealthbar.Size = UDim2.new(0, Drawings.Healthbar.Width, 0, h)
								do
									if Drawings.Healthbar.HealthText then
										local HealthPercentage = Floor(Health / 100 * 100)
										HealthText.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - HealthPercentage / 100) + 3)
										HealthText.Text = tostring(HealthPercentage)
										HealthText.Visible = Health < 100

										if Drawings.Healthbar.Lerp then
											local Color = Health >= 0.75 and RGB(0, 255, 0) or Health >= 0.5 and RGB(255, 255, 0) or Health >= 0.25 and RGB(255, 170, 0) or RGB(255, 0, 0)
											HealthText.TextColor3 = Color
										else
											HealthText.TextColor3 = Drawings.Healthbar.HealthTextRGB
										end
									end                        
								end
							end

							do
								Name.Visible = Drawings.Names.Enabled
								if ESP.Options.Friendcheck and Client:IsFriendsWith(Player.UserId) then
									Name.Text = string.format("(<font color=\"rgb(%d, %d, %d)\">F</font>) %s", 0, 255, 0, PName)
								else
									Name.Text = string.format("(<font color=\"rgb(%d, %d, %d)\">E</font>) %s", 255, 0, 0, PName)
								end
								Name.Position = UDim2.new(0, Pos.X, 0, Pos.Y - h / 2 - 9)
							end

							do
								if Drawings.Distances.Enabled then
									if Drawings.Distances.Position == "Bottom" then
										Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 18)
										WeaponIcon.Position = UDim2.new(0, Pos.X - 21, 0, Pos.Y + h / 2 + 15);
										Distance.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 7)
										Distance.Text = string.format("%d meters", Floor(Dist))
										Distance.Visible = true
									elseif Drawings.Distances.Position == "Text" then
										Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 8)
										WeaponIcon.Position = UDim2.new(0, Pos.X - 21, 0, Pos.Y + h / 2 + 5);
										Distance.Visible = false

										if ESP.Options.Friendcheck and Client:IsFriendsWith(Player.UserId) then
											Name.Text = string.format("(<font color=\"rgb(%d, %d, %d)\">F</font>) %s [%d]", 0, 255, 0, PName, Floor(Dist))
										else
											Name.Text = string.format("(<font color=\"rgb(%d, %d, %d)\">E</font>) %s [%d]", 255, 0, 0, PName, Floor(Dist))
										end

										Name.Visible = Drawings.Names.Enabled
									end
								end
							end

							do
								Weapon.Text = string.format("[<font color=\"rgb(%d, %d, %d)\">%s</font>]", 119, 120, 255, ThirdPersonObject._weaponname or "None")
								Weapon.Visible = Drawings.Weapons.Enabled
							end                            
						else
							HideESP()
						end
					else
						HideESP()
					end
				else
					HideESP()
				end
			end))
		end

		Updater()
	end

	do
		for _, v in pairs(game:GetService("Players"):GetPlayers()) do
			if v.Name ~= Client.Name then
				ESP(v)
			end      
		end

		game:GetService("Players").PlayerAdded:Connect(function(v)
			ESP(v)
		end)
	end
end

return ESP
