local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(game.ServerScriptService.FastCastRedux) -- require is how we use the data in module scripts
local partCache = require(game.ServerScriptService.PartCache) -- used to reduce lag. Stores bullets far from the map being played on
local WeaponsMarket = require(game.ReplicatedStorage.Shared.server_modules.WeaponsMarket)

local utilities = require(game.ReplicatedStorage.Shared.utilities)

local RemoteEvent = game.ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = game.ReplicatedStorage:WaitForChild("RemoteFunction")

local Gun = {}
Gun.__index = Gun

-- The model which the bullets will look like:

local function createBulletTemplate(size : Vector3)
	local bulletTemplate = Instance.new("Part") -- what the bullet will look like and the propertys it will have on each of its creations
	bulletTemplate.BrickColor = BrickColor.new("New Yeller")
	bulletTemplate.Material = Enum.Material.Neon
	bulletTemplate.Size = size
	bulletTemplate.CanCollide = false
	bulletTemplate.EnableFluidForces = false
	bulletTemplate.CanQuery = false
	bulletTemplate.CastShadow = false
	bulletTemplate.Anchored = false

	return bulletTemplate
end

local function createChamberTemplate(size : Vector3)
	local chamberTemplate = Instance.new("Part")
	chamberTemplate.BrickColor = BrickColor.new("Fawn brown")
	chamberTemplate.Material = Enum.Material.Salt
	chamberTemplate.Size = size
	chamberTemplate.CanCollide = false
	chamberTemplate.Anchored = false

	return chamberTemplate
end

local function recoverStamina(gun)
	for i = gun.currentSprintStamina.Value, gun.sprintStamina.Value, 1 do
		if gun.currentSprintStamina.Value >= gun.sprintStamina.Value then return end
		
		gun.currentSprintStamina.Value = i
		
		if gun.isSprintPressed then break end
		task.wait(0.1)
		print(gun.currentSprintStamina)
	end
end

local function onCurrentSprintStaminaChanged(plr, currentSprintStaminaValue, sprintStaminaValue)
	RemoteEvent:FireClient(plr, "onCurrentSprintStaminaChanged", {staminaFraction = currentSprintStaminaValue / sprintStaminaValue})
end

-- Creaitng folders to store bullets and it's chambers:

local bulletsFolder = Instance.new("Folder") -- the point of creating a folder via code is so the gun wont have any external dependencies (meaning it relies on other pre-created things to work), which wouln't work if uploaded to workspace. This checks if there already is a BulletsFolder, and if not, it will create its own.
bulletsFolder.Name = "BulletsFolder"
bulletsFolder.Parent = workspace

local chamberFolder = Instance.new("Folder")
chamberFolder.Name = "chamberFolder"
chamberFolder.Parent = workspace

local bulletCache = partCache.new(createBulletTemplate(Vector3.new(0.293, 0.042, 0.043)), 100, bulletsFolder) -- this creates a cache, which will reduce the lag of the game when the server is heavy in players and guns. The first parameter is the template thats being duplicated as bullets to store in the cache, the second is the ammount of bullets or duplicated part, and the third is the location (in the workspace not position) of where its stored
local chamberCache = partCache.new(createChamberTemplate(Vector3.new(0.284, 0.07, 0.056)), 100, chamberFolder)


local GunToolPresets = ReplicatedStorage:WaitForChild("GunToolPresets")

Gun.gunPresets = {
	["AK-15_Preset"] = {
		name = "AK-15",
		tool = GunToolPresets["AK-15"],

		animations = {
			Idle = "rbxassetid://122506501631928",
			Recoil = "rbxassetid://76152974931976",
			Reload = "rbxassetid://118850012077118",
			Tact_Reload = "rbxassetid://124526723005619"
		},

		sounds = {

		},

		cost = 10000,
		killsRequired = 15,
		productId = 3418859869,
		description = "Assault Rifle descended from the legendary AK-47 modernized.",
		
		fireRate = 0.0857, -- bullets per second
		fullAuto = true,
		damage = 34,

		sprintSpeedMultiplier = 1.5, -- May change in the future, especially if attachments cause weigh-down, but not our concern as of now.
		animationSpeedMultiplier = 1, -- Higher numbers increase animation speed, such as for reloading
		reloadDuration = 2.3,
		tacticalReloadDuration = 2.3,
		tacticalReloadSoundStart = 0, -- some guns start later in the sound reload cause of weird thing they do first like MP5

		magCapacity = 30, -- how many bullets can fit in a clip
		magCurrent = 30, -- how many bullets are currently in the clip
		ammoMax = 180, -- the maximum amount of bullets the shooter can hold not in the clip
		ammoCurrent = 90 -- how many bullets the shooter is holding not in the clip
	},

	["MP5_Preset"] = {
		name = "MP5",
		tool = GunToolPresets:WaitForChild("MP5"),

		animations = {
			Idle = "rbxassetid://75699950963041",
			Recoil = "rbxassetid://83708487430497",
			Reload = "rbxassetid://99089822260607",
			Tact_Reload = "rbxassetid://139503615906576"
		},

		sounds = {

		},

		cost = 2000,
		killsRequired = 15,
		productId = 3418859796,
		description = "Accurate military-grade SMG with high firerate.",
		
		fireRate = 0.075,
		fullAuto = true,
		damage = 27,

		sprintSpeedMultiplier = 1.7, -- May change in the future, especially if attachments cause weigh-down, but not our concern as of now.
		animationSpeedMultiplier = 1,
		reloadDuration = 3,
		tacticalReloadDuration = 2,
		tacticalReloadSoundStart = 0.6, -- When the reload animation should start. The MP5 has the weird chamber so its special.

		magCapacity = 30, -- how many bullets can fit in a clip
		magCurrent = 30, -- how many bullets are currently in the clip
		ammoMax = 180, -- the maximum amount of bullets the shooter can hold not in the clip
		ammoCurrent = 90 -- how many bullets the shooter is holding not in the clip
	},

	["Glock 17_Preset"] = {
		name = "Glock 17",
		tool = GunToolPresets:WaitForChild("Glock 17"),

		animations = {
			Idle = "rbxassetid://128097338970357",
			Recoil = "rbxassetid://85190065349279",
			No_Ammo_Effect = "rbxassetid://88886520634588",
			Reload = "rbxassetid://128993757422081",
			Tact_Reload = "rbxassetid://129645969251542"
		},

		sounds = {

		},

		cost = 0,
		killsRequired = 0,
		productId = 0, -- starter weapon dont need to be bought w/ robux
		description = "Reliable 9mm pistol used by law enforcement and military alike.",
		
		fireRate = 0.15,
		fullAuto = false,
		damage = 40,

		sprintSpeedMultiplier = 2, -- May change in the future, especially if attachments cause weigh-down, but not our concern as of now.
		animationSpeedMultiplier = 1,
		reloadDuration = 2.2,
		tacticalReloadDuration = 1.3,
		tacticalReloadSoundStart = 0, -- some guns start later in the sound reload cause of weird thing they do first like MP5

		magCapacity = 17, -- how many bullets can fit in a clip
		magCurrent = 17, -- how many bullets are currently in the clip
		ammoMax = 102, -- the maximum amount of bullets the shooter can hold not in the clip
		ammoCurrent = 51 -- how many bullets the shooter is holding not in the clip
	},
}
Gun.presetProductIds = {}
for i, preset in pairs(Gun.gunPresets) do
	preset.tool:SetAttribute("Gun", true)
	preset.tool:SetAttribute("Description", preset.description)
	preset.tool:SetAttribute("Cost", preset.cost)
	preset.tool:SetAttribute("ProductId", preset.productId)

	Gun.presetProductIds[preset.productId] = i
end

-- raycast params being added to FastCast params
local params = RaycastParams.new() -- we can even add the standard Raycast params to FastCasting
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true -- "because it is a gun; it should be able to go through water" - B Ricey

-- FastCast params
local castBehavior = FastCast.newBehavior() -- very similar to RaycastParams. This allows us to configure behaviors of our FastCast
castBehavior.RaycastParams = params -- basically adding the FastCast parmas to the added Raycast Params
castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0) -- self explanatory, but the .Acceleration property allows us to change the acceleration of the bullets. the second parameter, which we subtracted the bullets acceleration by gravity, would cause the bullet to drop overtime. In other words, it "pulls" our bullet down.
castBehavior.AutoIgnoreContainer = false -- this is redundant because in the onEquipped() function, we are already ignoring the player when they equip the gun
castBehavior.CosmeticBulletContainer = bulletsFolder -- the .CosmeticBulletContainer is what FastCast will use to referance where the gun's bullets will be stored
--castBehavior.CosmeticBulletTemplate = bulletTemplate -- we no longer need this after the cache has been added
castBehavior.CosmeticBulletProvider = bulletCache -- Instead of the CosmeticBulletTemplate (which would of duplicate the bullet), we would have a Provider, which has bullets pre-loaded and recycled

local chamberBehavior = FastCast.newBehavior() -- for bullet chamber
chamberBehavior.RaycastParams = params
chamberBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0)
chamberBehavior.AutoIgnoreContainer = false
chamberBehavior.CosmeticBulletContainer = chamberFolder
chamberBehavior.CosmeticBulletProvider = chamberCache

Gun.activeGuns = {}

function Gun.new(character, config)
	print(config)
	local self = setmetatable({}, Gun)

	self.shooter = character
	self.plr = Players:GetPlayerFromCharacter(self.shooter)

	for i, v in pairs(config) do
		self[i] = v
	end

	self.tool = self.tool:Clone() -- need to clone the config tool so there is not just one
	self.tool.Name = self.name

	-- Parts:

	self.mag = self.tool.Mesh.Mag

	-- Bools:

	self.isReloading = false
	self.isHolding = false -- whether or not the trigger is being held down
	self.isSprintPressed = false
	self.isEquipped = false

	-- Attachments:

	self.firePoint = self.tool.BodyAttach.firePoint
	self.chamberPoint = self.tool.BodyAttach.chamberPoint

	-- Folders:

	self.Gun_Sounds = utilities.makeDictionaryFromFolder(self.tool:WaitForChild("Sounds"))
	self.Animations = utilities.makeAnimationTracksFromAnimations(self.animations, self.shooter:WaitForChild("Humanoid"):WaitForChild("Animator"))
	self.Values = self.tool:FindFirstChild("Values") or utilities.createInstance("Folder", {Name = "Values", Parent = self.tool})

	-- FastCast:
	
	self.bulletCaster = FastCast.new() -- caster is FastCast equivilent of creating a new gun, basically. This only is created once, unlike fireing a raycast every time the player shoots on some gun models. This allows you to fire bullets and connect events to certain bullet actions
	self.chamberCaster = FastCast.new()

	-- Misc:

	self.ogWalkSpeed = self.shooter.Humanoid.WalkSpeed
	self.bulletFlash = self.firePoint.bulletFlash
	self.bulletSmoke = self.firePoint.bulletSmoke

	-- Numbers:

	self.shootDebounce = utilities.createInstance("BoolValue", {Name = "shootDebounce", Value = false, Parent = self.Values})
	self.isFullAuto = utilities.createInstance("BoolValue", {Name = "IsFullAuto", Value = self.fullAuto, Parent = self.Values})
	self.sprintStamina = utilities.createInstance("NumberValue", {Name = "SprintStamina", Value = 100, Parent = self.Values})
	self.currentSprintStamina = utilities.createInstance("NumberValue", {Name = "CurrentSprintStamina", Value = self.sprintStamina.Value, Parent = self.Values})
	

	-- Connections:

	self.connections = {

		self.tool.Equipped:Connect(function()
			self:Equip()
		end),
		self.tool.Unequipped:Connect(function()
			self:Unequip()
		end),
		self.tool.Activated:Connect(function()
			self:Activate()
		end),
		self.tool.Deactivated:Connect(function()
			self:Deactivate()
		end),
	
		self.bulletCaster.LengthChanged:Connect(function(cast, lastPoint, direction, length, velocity, chamber)
			self:ChangeBulletRaycastLength(cast, lastPoint, direction, length, velocity, chamber)
		end),
		self.bulletCaster.RayHit:Connect(function(cast, result, velocity, bullet)
			self:BulletImpact(cast, result, velocity, bullet)
		end),
		
		self.chamberCaster.LengthChanged:Connect(function(cast, lastPoint, direction, length, velocity, chamber)
			self:ChangeChamberRaycastLength(cast, lastPoint, direction, length, velocity, chamber)
		end),
		self.chamberCaster.RayHit:Connect(function(cast, result, velocity, bullet)
			self:ChamberImpact(cast, result, velocity, bullet)
		end),
		self.currentSprintStamina:GetPropertyChangedSignal("Value"):Connect(function()
			onCurrentSprintStaminaChanged(self.plr, self.currentSprintStamina.Value, self.sprintStamina.Value)
		end)

	}


	Gun.activeGuns[self.shooter.Name --[[.. "_" .. self.name]] ] = self
	return self
end

function Gun:Remove()
	self.tool:Destroy()
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
	self.connections = nil

	for i in pairs(self) do
		self[i] = nil
	end
	self = nil
end


function Gun:Fire(ray)
	
	if self.magCurrent <= 0
	or self.isReloading
	or self.shootDebounce.Value
	then
		return false
	end
	
	local endPoint = ray.Origin + ray.Direction * 1000
		
	local startPosition = self.firePoint.WorldPosition -- dont use position on attachments because position is relative. Instead, use WorldPosition (the 3D position)
	local otherStartPosition = self.chamberPoint.WorldPosition
	local direction = (endPoint - startPosition).Unit
	local otherDirection = (self.chamberPoint.WorldCFrame.LookVector).Unit
	
	self.bulletCaster:Fire(startPosition, direction, 1000, castBehavior) -- like a normal raycast, with the startPosition as the first parameter, and the direction as the second. Except the third parameter is a velocity value. It can be a number, or a Vector3 value
	self.chamberCaster:Fire(otherStartPosition, otherDirection, 10, chamberBehavior)
	self.Gun_Sounds.Gunshot:Play()
	self.Animations.Recoil:Play()
	self.bulletFlash.Enabled = true
	delay(0.1, function()
	self.bulletFlash.Enabled = false
	end)
	delay(3, function()
		for i = 0,300,1 do
			if self.isHolding ~= true then
				break			
			elseif i == 300 then
				self.bulletSmoke.Enabled = true
				delay(15,function()
					self.bulletSmoke.Enabled = false
				end)
			end
		end
	end)
-- running this FastCast alone wouldn't do anything visually. This is why we enabled the .VisualizeCasts property so we can see an example of what would happen
	self.magCurrent = self.magCurrent - 1

	if self.magCurrent <= 0 then
		-- some guns, like the Glock, M1 Garand, do something unique on the last round, such as the glock slide not returning, or the M1 Garand clip flying out.
		if self.Animations.No_Ammo_Effect then self.Animations.No_Ammo_Effect:Play() end
	end

	
	if not self.plr then return true end
	RemoteEvent:FireClient(self.plr, "changeUiDisplay", {UIToChange = "Ammo_Display", magCurrent = self.magCurrent, magCapacity = self.magCapacity})
	return true
end

function Gun:Reload()
	if self.ammoCurrent <= 0 or self.isReloading then return end

	if self.magCurrent == 0 then -- Reload when the entire mag is empty
		
		self.isReloading = true

		if self.plr then
			RemoteEvent:FireClient(self.plr, "iconChange", {magCurrent = self.magCurrent, isEquipped = self.isEquipped})
		end

		self.Animations.Reload:Play()
		self.Gun_Sounds.Reload:Play()
		wait(self.reloadDuration * 0.357)
		self.mag.Transparency = 1
		wait(self.reloadDuration * 0.071)
		self.mag.Transparency = 0
		wait(self.reloadDuration * 0.571)
		-- total wait() time should equal: 3.5
		
		if self.ammoCurrent >= self.magCapacity then
			local loss = self.magCapacity - self.magCurrent
			self.magCurrent = self.magCapacity
			self.ammoCurrent = self.ammoCurrent - loss
		elseif self.ammoCurrent < self.magCapacity then
			self.magCurrent = self.ammoCurrent
			self.ammoCurrent = self.ammoCurrent - self.ammoCurrent
		end
		
		if self.plr then
			RemoteEvent:FireClient(self.plr, "reload", {magCurrent = self.magCurrent, magCapacity = self.magCapacity, ammoCurrent = self.ammoCurrent})
		end
		self.isReloading = false
		
	elseif self.magCurrent < self.magCapacity then -- tactical reload for when the mag is only partially empty
		
		local tacticalReloadSFX = self.Gun_Sounds.Reload
		
		if not tacticalReloadSFX.IsLoaded then
			tacticalReloadSFX.Loaded:Wait()
		end
		self.Animations.Tact_Reload:Play()
		tacticalReloadSFX.TimePosition = self.tacticalReloadSoundStart -- some guns get the weird startposition treatment due to the nature of a full reload vs tactical.
		tacticalReloadSFX:Play()
		
		delay(self.tacticalReloadDuration, function()
			tacticalReloadSFX:Stop()
		end)
		
		self.isReloading = true

		if self.plr then
			RemoteEvent:FireClient(self.plr, "iconChange", {magCurrent = self.magCurrent, isEquipped = self.isEquipped})
		end
		
		task.wait(self.tacticalReloadDuration * 0.543)
		self.mag.Transparency = 1
		task.wait(self.tacticalReloadDuration * 0.108)
		self.mag.Transparency = 0
		task.wait(self.tacticalReloadDuration * 0.347)
		-- total wait() time should equal 'tactical reload duration'
		
		if self.ammoCurrent >= 30 then
			local loss = self.magCapacity - self.magCurrent
			self.magCurrent = self.magCapacity
			self.ammoCurrent = self.ammoCurrent - loss
		elseif self.ammoCurrent < 30 then
			self.magCurrent = self.ammoCurrent
			self.ammoCurrent = self.ammoCurrent - self.ammoCurrent
		end
		
		if self.plr then
			RemoteEvent:FireClient(self.plr, "reload", {magCurrent = self.magCurrent, ammoCurrent = self.ammoCurrent, magCapacity = self.magCapacity})
		end

		self.isReloading = false
		
	end
	if self.Animations.No_Ammo_Effect then self.Animations.No_Ammo_Effect:Stop() end
end

function Gun:Sprint()
	if not self.isSprintPressed then
		self.isSprintPressed = true
		self.shooter.Humanoid.WalkSpeed = self.ogWalkSpeed * self.sprintSpeedMultiplier
		-- RemoteFunction:InvokeClient(self.plr, "waitForSprintPressToEnd")
		
		-- Drain:
		while self.isSprintPressed do
			task.wait(0.1)
			if self.shooter.Humanoid.MoveDirection.Magnitude == 0 then 
				if self.currentSprintStamina.Value >= self.sprintStamina.Value then continue end

				self.currentSprintStamina.Value += 1
				print(self.currentSprintStamina.Value)
				continue
			else
				self.currentSprintStamina.Value -= 1
				if not self.isSprintPressed then break end
				print(self.currentSprintStamina.Value)
			end
		end
		self.shooter.Humanoid.WalkSpeed = self.ogWalkSpeed
		self.isSprintPressed = false
		
		-- Recovery:
		recoverStamina(self)
	end
end

function Gun:Equip()
	if self.plr and not self.plr.IsLoaded.Value then
		self.tool.Parent = self.plr.Backpack
		return
	end

	self.Gun_Sounds.Equip:Play()
	self.isEquipped = true
	RemoteEvent:FireClient(self.plr, "onEquipped", {isEquipped = self.isEquipped, magCurrent = self.magCurrent, magCapacity = self.magCapacity, ammoCurrent = self.ammoCurrent})
	self.Animations.Idle:Play()
	params.FilterDescendantsInstances = {self.tool.Parent, bulletsFolder, chamberFolder}
	self.Gun_Sounds.Equip:Play()
end

function Gun:Unequip()
	self.isEquipped = false
	RemoteEvent:FireClient(self.plr, "onUnequipped", {isEquipped = self.isEquipped})
	self.Animations.Idle:Stop()
end

function Gun:Activate()
	self.isHolding = true
	if self.magCurrent == 0 and self.isReloading == false then
		self.Gun_Sounds.EmptyMag:Play()
	
	-- elseif self.magCurrent > 0 and not self.isReloading then

		-- while self.isHolding do
		-- 	self:Fire()
		-- 	task.wait(self.fireRate)
		-- end
	end
end

function Gun:Deactivate()
	self.isHolding = false
end

function Gun:ChangeBulletRaycastLength(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then
		local newAngles =  CFrame.Angles(0,math.rad(90),0)
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0,0,-(length - bulletLength)) -- the length argument is the length of the segment of a Raycast. When the .VisualizeCasts property is enabled, you see a bunch of segments on a raycast. We want to offset our bullet so it doesn't go past each segment. If the bullet hits a wall, for example, we dont want the bullet to phaze through the wall; we want it to stay behind it.
		bullet.CFrame = CFrame.lookAt( lastPoint, lastPoint + direction ):ToWorldSpace(offset) -- Here, we have lastPoint, then we look towards the direction that the bullets going, which is done by adding lastPoint to direction. Then we add our CFrame offset relative to this CFrame by using :ToWorldSpace, which converts our offset to this CFrame
		bullet.CFrame = bullet.CFrame * newAngles
	end
end

function Gun:BulletImpact(cast, result, velocity, bullet)

	local rayInstance = result.Instance -- oddly, FastCast results are never nil, so this line of code is safe
	local resultHumanoid = rayInstance.Parent:FindFirstChild("Humanoid")

	if resultHumanoid and resultHumanoid.Health > 0 then
		if rayInstance == rayInstance.Parent:FindFirstChild("Head") then
			-- print("You hit "..tostring(rayInstance.Parent) .." by headshot!")
			RemoteEvent:FireClient(self.plr, "characterHit", {hitSound = self.Gun_Sounds.Headshot})
			rayInstance.Parent.Humanoid:TakeDamage(self.damage*2)
		else
			-- print("You hit "..tostring(rayInstance.Parent) .."'s "..tostring(rayInstance.Name))
			RemoteEvent:FireClient(self.plr, "characterHit", {hitSound = self.Gun_Sounds.Hit})
			rayInstance.Parent.Humanoid:TakeDamage(self.damage)
		end
	
		if resultHumanoid and resultHumanoid.Health <= 0 then
			-- Give shooter money:
			WeaponsMarket:AwardKill(self.plr, 1)
			WeaponsMarket:AwardCash(self.plr, 5)
		end
	end
	
	delay(1.25, function() -- delay is like wait(), but instead it doesn't yield the entire script, and will be like a wait() on a seperate thread.
		bulletCache:ReturnPart(bullet)
	end)
end

function Gun:ChangeChamberRaycastLength(cast, lastPoint, direction, length, velocity, chamber)
	if chamber then
		local newAngles =  CFrame.Angles(0,math.rad(180),0)
		local bulletLength = chamber.Size.Z/2
		local offset = CFrame.new(0,0,-(length - bulletLength)) -- the length argument is the length of the segment of a Raycast. When the .VisualizeCasts property is enabled, you see a bunch of segments on a raycast. We want to offset our bullet so it doesn't go past each segment. If the bullet hits a wall, for example, we dont want the bullet to phaze through the wall; we want it to stay behind it.
		chamber.CFrame = CFrame.lookAt( lastPoint, lastPoint + direction ):ToWorldSpace(offset) -- Here, we have lastPoint, then we look towards the direction that the bullets going, which is done by adding lastPoint to direction. Then we add our CFrame offset relative to this CFrame by using :ToWorldSpace, which converts our offset to this CFrame
		chamber.CFrame = chamber.CFrame * newAngles
	end
end

function Gun:ChamberImpact(cast, result, velocity, chamber)
	self.Gun_Sounds.ChamberDrop.Parent = chamber
	self.Gun_Sounds.ChamberDrop:Play()
	delay(1.25, function()
		chamberCache:ReturnPart(chamber)
	end)
end

return Gun