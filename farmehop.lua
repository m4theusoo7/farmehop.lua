local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local WEBHOOK_URL = "COLE_SEU_WEBHOOK_AQUI" -- ⚠️ COLOQUE SEU LINK AQUI

local player = Players.LocalPlayer
repeat task.wait() until game:IsLoaded()

local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request
local noclipConnection

local fruitRarities = {
	["🔴 Mítica (Mythical)"] = {"Kitsune", "Leopard", "Dragon", "Spirit", "Control", "Venom", "Shadow", "Dough", "T-Rex", "Mammoth", "Gravity"},
	["🟣 Lendária (Legendary)"] = {"Blizzard", "Pain", "Rumble", "Portal", "Phoenix", "Sound", "Spider", "Love", "Buddha", "Quake"},
	["🔵 Rara (Rare)"] = {"Magma", "Ghost", "Barrier", "Rubber", "Light"},
	["🟢 Incomum (Uncommon)"] = {"Diamond", "Dark", "Sand", "Ice", "Falcon", "Flame"},
	["⚪ Comum (Common)"] = {"Spike", "Smoke", "Bomb", "Spring", "Chop", "Spin", "Rocket"}
}

local rarityColors = {
	["🔴 Mítica (Mythical)"] = 16711680, ["🟣 Lendária (Legendary)"] = 16711935,
	["🔵 Rara (Rare)"] = 3329330, ["🟢 Incomum (Uncommon)"] = 65280, ["⚪ Comum (Common)"] = 12632256
}

local function getFruitInfo(fruitName)
	for rarity, fruits in pairs(fruitRarities) do
		for _, fName in ipairs(fruits) do
			if string.find(string.lower(fruitName), string.lower(fName)) then
				return rarity, rarityColors[rarity]
			end
		end
	end
	return "Desconhecida", 16777215
end

local function criarESP(fruta, part)
	if part:FindFirstChild("FruitESP") then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FruitESP"
	billboard.Parent = part
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true

	local text = Instance.new("TextLabel")
	text.Parent = billboard
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Font = Enum.Font.Code
	text.TextSize = 18
	text.TextColor3 = Color3.fromRGB(0, 255, 0)
	text.TextStrokeTransparency = 0

	task.spawn(function()
		while part and part.Parent do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - part.Position).Magnitude
				text.Text = string.format("%s\n[ %d m ]", fruta.Name, math.floor(dist))
			end
			task.wait(0.5)
		end
		if billboard then billboard:Destroy() end
	end)
end

local function sendDiscordNotification(fruitName)
	if not requestFunc or WEBHOOK_URL == "COLE_SEU_WEBHOOK_AQUI" then return end
	local rarityName, embedColor = getFruitInfo(fruitName)
	local joinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game:GetService('Players').LocalPlayer)", game.PlaceId, game.JobId)

	local data = {
		["content"] = "||@everyone|| 🍎 **Fruta Encontrada no Mapa!**",
		["embeds"] = {{
			["title"] = "Fruit Sniper",
			["color"] = embedColor,
			["fields"] = {
				{["name"] = "Fruta:", ["value"] = "**" .. fruitName .. "**", ["inline"] = true},
				{["name"] = "Raridade:", ["value"] = "**" .. rarityName .. "**", ["inline"] = true},
				{["name"] = "Entrar neste servidor:", ["value"] = "```lua\n" .. joinScript .. "\n```", ["inline"] = false}
			}
		}}
	}
	requestFunc({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)})
end

local function tweenTo(targetPos)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local root = char.HumanoidRootPart
	
	local distance = (root.Position - targetPos).Magnitude
	local speed = 250 -- Velocidade segura contra Anti-Cheat
	local timeToTravel = distance / speed
	
	-- Anti-gravidade para o voo ser suave
	local antiGravity = Instance.new("BodyVelocity")
	antiGravity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	antiGravity.Velocity = Vector3.zero
	antiGravity.Parent = root
	
	local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
	
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
	
	tween:Play()
	tween.Completed:Wait()
	
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	if antiGravity then
		antiGravity:Destroy()
	end
end

local function serverHop()
	print("Procurando um novo servidor...")
	if not requestFunc then return end
	local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
	local success, response = pcall(function() return requestFunc({Url = url, Method = "GET"}) end)
	
	if success and response and response.Body then
		local dataSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
		if dataSuccess and data and data.data then
			for _, server in ipairs(data.data) do
				if type(server) == "table" and server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 12) then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
					return
				end
			end
		end
	end
	task.wait(5)
	serverHop()
end

local function autoSniper()
	local encontrouFruta = false
	for _, v in ipairs(Workspace:GetDescendants()) do
		if (v:IsA("Model") or v:IsA("Tool")) and string.find(v.Name, "Fruit") then
			if not v:FindFirstChildOfClass("Humanoid") and not string.find(string.lower(v.Name), "dealer") then
				local part = v:FindFirstChild("Handle") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
				if part then
					criarESP(v, part)
					sendDiscordNotification(v.Name)
					
					print("A voar até a fruta: " .. v.Name)
					-- Voa até a posição da fruta, ficando ligeiramente acima para coletar com segurança
					tweenTo(part.Position + Vector3.new(0, 2, 0))
					task.wait(2) -- Aguarda para confirmar a coleta
					
					encontrouFruta = true
				end
			end
		end
	end
	
	if encontrouFruta then
		print("Fruta recolhida! A reiniciar varredura...")
		task.wait(1)
		autoSniper() -- Procura novamente para ver se há mais frutas no mesmo servidor ou muda de server
	else
		print("Nenhuma fruta no chão. Pulando de servidor em 3 segundos...")
		task.wait(3)
		serverHop()
	end
end

-- Inicia o processo
autoSniper()
