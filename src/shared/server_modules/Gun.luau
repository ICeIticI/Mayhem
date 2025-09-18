local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local FastCast = require(game.ServerScriptService.FastCastRedux) -- require is how we use the data in module scripts
local partCache = require(game.ServerScriptService.PartCache) -- used to reduce lag. Stores bullets far from the map being played on

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

-- Creaitng folders to store bullets and it's chambers:

local bulletsFolder = Instance.new("Folder") -- the point of creating a folder via code is so the gun wont have any external dependencies (meaning it relies on other pre-created things to work), which wouln't work if uploaded to workspace. This checks if there already is a BulletsFolder, and if not, it will create its own.
bulletsFolder.Name = "BulletsFolder"
bulletsFolder.Parent = workspace

local chamberFolder = Instance.new("Folder")
chamberFolder.Name = "chamberFolder"
chamberFolder.Parent = workspace

local bulletCache = partCache.new(createBulletTemplate(Vector3.new(0.293, 0.042, 0.043)), 100, bulletsFolder) -- this creates a cache, which will reduce the lag of the game when the server is heavy in players and guns. The first parameter is the template thats being duplicated as bullets to store in the cache, the second is the ammount of bullets or duplicated part, and the third is the location (in the workspace not position) of where its stored
local chamberCache = partCache.new(createChamberTemplate(Vector3.new(0.284, 0.07, 0.056)), 100, chamberFolder)


local GunToolPresets = ServerStorage:WaitForChild("GunToolPresets")
Gun.gunPresets = {
	AK15_Preset = {
		tool = GunToolPresets.AK15,

		magCurrent = 30, -- how many bullets are currently in the clip
		magCapacity = 30, -- how many bullets can fit in a clip
		ammoCurrent = 90, -- how many bullets the shooter is holding not in the clip
		ammoMax = 180 -- the maximum amount of bullets the shooter can hold not in the clip
	}
}

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

function Gun.new(character, config)
	local self = setmetatable({}, Gun)

	self.shooter = character
	self.plr = Players:GetPlayerFromCharacter(self.shooter)

	self.tool = config.tool

	-- Parts:

	self.mag = self.tool.Mesh.Mag

	-- Bools:

	self.isReloading = false
	self.isHolding = false -- whether or not the trigger is being held down
	self.isEquipped = false

	-- Ammo:

	self.magCurrent = config.magCurrent
	self.magCapacity = config.magCapacity
	self.ammoCurrent = config.ammoCurrent
	self.ammoMax = config.ammoMax

	-- Attachments:

	self.firePoint = self.tool.BodyAttach.firePoint
	self.chamberPoint = self.tool.BodyAttach.chamberPoint

	-- Folders:

	self.Gun_Sounds = self.tool:WaitForChild("Gun_Sounds")
	self.Animations = self.tool:WaitForChild("Animations")

	-- FastCast:
	
	self.bulletCaster = FastCast.new() -- caster is FastCast equivilent of creating a new gun, basically. This only is created once, unlike fireing a raycast every time the player shoots on some gun models. This allows you to fire bullets and connect events to certain bullet actions
	self.chamberCaster = FastCast.new()

	-- Misc:

	self.bulletFlash = self.firePoint.bulletFlash
	self.bulletSmoke = self.firePoint.bulletSmoke

	return self
end


function Gun:Fire(mousePosition)
	if self.magCurrent > 0 and self.isReloading == false then
		
		local startPosition = self.firePoint.WorldPosition -- dont use position on attachments because position is relative. Instead, use WorldPosition (the 3D position)
		local otherStartPosition = self.chamberPoint.WorldPosition
		local direction = (mousePosition - startPosition).Unit
		local otherDirection = (self.tool.body.CFrame.LookVector).Unit
		
		self.bulletCaster:Fire(startPosition, direction, 1000, castBehavior) -- like a normal raycast, with the startPosition as the first parameter, and the direction as the second. Except the third parameter is a velocity value. It can be a number, or a Vector3 value
		self.chamberCaster:Fire(otherStartPosition, otherDirection, 10, chamberBehavior)
		self.Gun_Sounds.gunShotSFX:Play()
		self.Animations.recoilTrack:Play()
		self.bulletFlash.Enabled = true
		delay(0.1, function()
		self.bulletFlash.Enabled = false
		end)
		delay(3, function()
			for i = 0,300,1 do
				if self.isHolding ~= true then
					break			
				elseif i == 300 then
					--print(i)
					self.bulletSmoke.Enabled = true
					delay(15,function()
						self.bulletSmoke.Enabled = false
					end)
				end
			end
		end)
	-- running this FastCast alone wouldn't do anything visually. This is why we enabled the .VisualizeCasts property so we can see an example of what would happen
		self.magCurrent = self.magCurrent - 1

		self.plr = Players:GetPlayerFromCharacter(self.shooter)
		
		if not self.plr then return end
		RemoteEvent:FireClient(self.plr, "changeUiDisplay", {magCurrent = self.magCurrent, magCapacity = self.magCapacity})
	end
end

function Gun:Reload()
	if self.magCurrent == 0 and self.isReloading == false and self.ammoCurrent > 0 then -- Reload when the entire mag is empty
		
		self.isReloading = true

		if self.plr then
			RemoteEvent:FireClient(self.plr, "iconChange", {magCurrent = self.magCurrent, isEquipped = self.isEquipped})
		end

		self.Animations.reloadTrack:Play()
		self.Gun_Sounds.reloadSFX:Play()
		wait(1.25)
		self.mag.Transparency = 1
		wait(0.25)
		self.mag.Transparency = 0
		wait(2)
		-- total wait() time should equal: 3.5
		
		if self.ammoCurrent >= 30 then
			local loss = self.magCapacity - self.magCurrent
			self.magCurrent = self.magCapacity
			self.ammoCurrent = self.ammoCurrent - loss
		elseif self.ammoCurrent < 30 then
			self.magCurrent = self.ammoCurrent
			self.ammoCurrent = self.ammoCurrent - self.ammoCurrent
		end
		
		if self.plr then
			RemoteEvent:FireClient(self.plr, "reload", {magCurrent = self.magCurrent, magCapacity = self.magCapacity, ammoCurrent = self.ammoCurrent})
		end
		self.isReloading = false
		
	elseif self.magCurrent < self.magCapacity and self.isReloading == false and self.ammoCurrent > 0 then -- tactical reload for when the mag is only partially empty
		
		local tacticalReloadSFX = self.Gun_Sounds.reloadSFX:Clone()
		tacticalReloadSFX.Parent = self.Gun_Sounds.reloadSFX.Parent
		
		if not tacticalReloadSFX.IsLoaded then
			tacticalReloadSFX.Loaded:Wait()
		end
		self.Animations.tactTrack:Play()
		tacticalReloadSFX:Play()
		
		delay(2.3, function()
			tacticalReloadSFX:Stop()
		end)
		
		self.isReloading = true

		if self.plr then
			RemoteEvent:FireClient(self.plr, "iconChange", {magCurrent = self.magCurrent, isEquipped = self.isEquipped})
		end
		
		wait(1.25)
		self.mag.Transparency = 1
		wait(0.25)
		self.mag.Transparency = 0
		wait(0.8)
		-- total wait() time should equal: 2.3
		
		if self.ammoCurrent >= 30 then
			local loss = self.magCapacity - self.magCurrent
			self.magCurrent = self.magCapacity
			self.ammoCurrent = self.ammoCurrent - loss
		elseif self.ammoCurrent < 30 then
			self.magCurrent = self.ammoCurrent
			self.ammoCurrent = self.ammoCurrent - self.ammoCurrent
		end
		
		if self.plr then
			RemoteEvent:FireClient(self.plr, "reload", {magCurrent = self.magCurrent, ammoCurrent = self.ammoCurrent})
		end

		self.isReloading = false
		
	end
end

function Gun:Equip()
	self.isEquipped = true
	params.FilterDescendantsInstances = {self.tool.Parent, bulletsFolder, chamberFolder}
	self.Gun_Sounds.equipSFX:Play()
end

function Gun:Unequip()
	self.isEquipped = false
end

function Gun:Activate()
	self.isHolding = true
	if self.magCurrent == 0 and self.isReloading == false then
		self.Gun_Sounds.emptyMagSFX:Play()
	end
end

function Gun:Deactivate()
	self.isHolding = false
end

function Gun:ChangeBulletRaycastLength()
	
end

return Gun