-- Register the behaviour
behaviour("GearRecharge")

function GearRecharge:Awake()
	self.gameObject.name = "GearRecharge"
end

function GearRecharge:Start()
	-- Run when behaviour is created

	self.hasSpawnedOnce = false

	self.gearData = {}
	self:ParseString(self.script.mutator.GetConfigurationString("line1"))
	self:ParseString(self.script.mutator.GetConfigurationString("line2"))
	self:ParseString(self.script.mutator.GetConfigurationString("line3"))
	self:ParseString(self.script.mutator.GetConfigurationString("line4"))
	self:ParseString(self.script.mutator.GetConfigurationString("line5"))

	GameEvents.onActorDied.AddListener(self,"OnActorDied")
	GameEvents.onActorSpawn.AddListener(self,"OnActorSpawn")
	GameEvents.onCapturePointCaptured.AddListener(self,"OnCapturePointCaptured")

	self.activeGear = {}
	self.chargePerKill = self.script.mutator.GetConfigurationFloat("ChargePerKill")
	self.chargePerCapturePoint = self.script.mutator.GetConfigurationFloat("ChargePerCapturePoint")

	local function onWeaponReturn(weapon)
		self:EvaluateWeapon(weapon)
	end

	local quickThrowObj = self.gameObject.Find("QuickThrow")
	if quickThrowObj then
		self.quickThrow = quickThrowObj.GetComponent(ScriptedBehaviour)
		self.quickThrow.self:SubscribeToWeaponReturnEvent("GearRecharge", onWeaponReturn)
	end

	local armorObj = self.gameObject.Find("PlayerArmor")
	if armorObj then
		self.playerArmor = armorObj.GetComponent(ScriptedBehaviour)
		self.playerArmor.self:SubscribeToWeaponReturnEvent("GearRecharge", onWeaponReturn)
	end

	local weaponPickup = self.gameObject.Find("[LQS]WeaponPickup(Clone)")
	if weaponPickup then
		self.weaponPickup = weaponPickup.GetComponent(ScriptedBehaviour)
		if self.weaponPickup.self.onWeaponPickUpListeners then
			self.weaponPickup.self:AddOnWeaponPickupListener("GearRecharge", onWeaponReturn)
		end
	end

	self.targets.AudioSource.SetOutputAudioMixer(AudioMixer.Important)
end

--Parse string lines for weapon data
function GearRecharge:ParseString(str)
	for word in string.gmatch(str, '([^,]+)') do
		local iterations = 0
		local name = ""
		local rechargeRequirement = 0

		--Type 0: Always Charges
		--Type 1: Kills Only
		--Type 2: Captures Only
		local gearType = 0
		for wrd in string.gmatch(word,'([^|]+)') do
			if wrd ~= "-" then
				if iterations == 0 then name = wrd end
				if iterations == 1 then rechargeRequirement = tonumber(wrd) end
				if iterations == 2 then gearType = tonumber(wrd) end
			end
			iterations = iterations + 1
			if(iterations >= 3) then break end
		end
		local data = {}
		data.rechargeRequirement = rechargeRequirement
		data.type = gearType
		self.gearData[name] = data

		--self:Debug("Registered " .. name .. " with mag size of " .. maxAmmo .. " and max spare ammo of " .. maxSpareAmmo)
		print("Registered " .. name .. " with recharge requirement of " .. rechargeRequirement .. " with type of " .. gearType)
	end
end

function GearRecharge:OnActorSpawn(actor)
	if actor.isPlayer then
		self.hasSpawnedOnce = true
		self:EvaluateLoadout()
	end
end

function GearRecharge:EvaluateLoadout()
	for i, weapon in pairs(Player.actor.weaponSlots) do
		self:EvaluateWeapon(weapon)
	end
end

function GearRecharge:EvaluateWeapon(weapon)
	local cleanName = string.gsub(weapon.weaponEntry.name,"<.->","")
	local gearData = self.gearData[cleanName]
	if gearData then
		local gear = self.activeGear[weapon.slot]
		if gear and gear.name == cleanName then
			gear.weapon = weapon
		else
			gear = {}
			gear.weapon = weapon
			gear.name = cleanName
			gear.currentCharge = 0
			gear.type = gearData.type
			gear.rechargeRequirement = gearData.rechargeRequirement
			self.activeGear[weapon.slot] = gear
		end
	end
end

function GearRecharge:OnCapturePointCaptured(capturePoint, newOwner)
	if self.hasSpawnedOnce and not Player.actor.isDead then
		if Player.actor.currentCapturePoint == capturePoint and Player.actor.team == newOwner then
			for i, gear in pairs(self.activeGear) do
				self:TryRecharge(gear, self.chargePerCapturePoint,2)
			end
		end
	end
end

function GearRecharge:OnActorDied(actor, source, isSilent)
	if isSilent then return end

	if actor.team == Player.actor.team and source and source.isPlayer then
		for i, gear in pairs(self.activeGear) do
			self:TryRecharge(gear, self.chargePerKill, 1)
		end
	elseif actor.isPlayer then
		self.activeGear = {}
	end
end

function GearRecharge:TryRecharge(gear, amount, typeRequired)
	if gear.weapon == nil then return end
	if gear.type ~= typeRequired and gear.type ~= 0 then return end

	if gear.weapon.ammo < gear.weapon.maxAmmo then
		gear.currentCharge = gear.currentCharge + amount
		if gear.currentCharge >= gear.rechargeRequirement then
			if gear.weapon.ammo == - 1 then
				gear.weapon.ammo = 1
			else
				gear.weapon.ammo = gear.weapon.ammo + 1
			end
			
			self.targets.AudioSource.Play()
			self.targets.Animator.SetTrigger("Flash")
			gear.currentCharge = 0

			if self.quickThrow then
				self.quickThrow.self:UpdateDisplay()
			end
		end
	end
end