-- Register the behaviour
behaviour("GearRechargeMutator")

function GearRechargeMutator:Start()
	local mainObject = GameObject.Instantiate(self.targets.MainBehaviour)

	local mainBehaviour = mainObject.GetComponent(GearRecharge)

	local chargePerKill = self.script.mutator.GetConfigurationFloat("ChargePerKill")
	local chargePerCapturePoint = self.script.mutator.GetConfigurationFloat("ChargePerCapturePoint")
	local chargePerSecond = self.script.mutator.GetConfigurationFloat("ChargePerSecond")

	mainBehaviour:Init(chargePerKill, chargePerCapturePoint, chargePerSecond)
	mainBehaviour:ParseString(self.script.mutator.GetConfigurationString("line1"))
	mainBehaviour:ParseString(self.script.mutator.GetConfigurationString("line2"))
	mainBehaviour:ParseString(self.script.mutator.GetConfigurationString("line3"))
	mainBehaviour:ParseString(self.script.mutator.GetConfigurationString("line4"))
	mainBehaviour:ParseString(self.script.mutator.GetConfigurationString("line5"))
end