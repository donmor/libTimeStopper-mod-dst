GLOBAL.setmetatable(env,{__index = function(_, k)
	return GLOBAL.rawget(GLOBAL,k)
end})

TUNING.TIMESTOPPER_PERFORMANCE = GetModConfigData("performance") or 500
TUNING.TIMESTOPPER_IGNORE_SHADOW = GetModConfigData("ignore_shadow")
TUNING.TIMESTOPPER_IGNORE_WORTOX = GetModConfigData("ignore_wortox")
TUNING.TIMESTOPPER_IGNORE_WANDA = GetModConfigData("ignore_wanda")
TUNING.TIMESTOPPER_IGNORE_CHARLIE = GetModConfigData("ignore_charlie")
TUNING.TIMESTOPPER_INVINCIBLE_FOE = GetModConfigData("invincible_foe")
TUNING.TIMESTOPPER_GREYSCREEN = GetModConfigData("greyscreen")

AddComponentPostInit("projectile", function(self)
	self.origspeed = self.speed
	local pSetSpeed = self.SetSpeed
	self.SetSpeed = function(self, speed)
		self.origspeed = speed
		return pSetSpeed(self, speed)
	end
	local pStop = self.Stop
	self.Stop = function(self)
		self.speed = self.origspeed
		if self.inst.projspeedtask then
			self.inst.projspeedtask:Cancel()
			self.inst.projspeedtask = nil
		end
		return pStop(self)
	end
	local pOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		if self.onupdatefn then
			self.onupdatefn(self)
		end
		return not self.inst:HasTag("time_stopped") and pOnUpdate(self, dt)
	end
end)	-- <改写投射物等以达到时停效果

AddComponentPostInit("burnable", function(self)
		local function eventfn()
			if self.task then
				self.taskfn = self.task.fn
				self.taskremaining = self.task.nexttick and GetTimeForTick(self.task.nexttick - GetTick()) or self.burntime
				if self.taskfn and self.taskremaining then
					self.task:Cancel()
					self.task = nil
				end
			end
		end
	local pExtendBurning = self.ExtendBurning
	self.ExtendBurning = function(self)
		if not self.twevent then
			self.twevent = self.inst:ListenForEvent("time_stopped", eventfn)
		end
		if not self.twevent2 then
			self.twevent2 = self.inst:ListenForEvent("time_resumed", function()
				if not self.task and self.taskfn and self.taskremaining then
					self.task = self.inst:DoTaskInTime(self.taskremaining > 0 and self.taskremaining + FRAMES * 3 or FRAMES * 3, self.taskfn, self)
				end
			end)
		end
		pExtendBurning(self)
		if self.inst:HasTag("time_stopped") then
			self.inst:DoTaskInTime(FRAMES, eventfn)
		end
	end
	local pStartWildfire = self.StartWildfire
	self.StartWildfire = function(self)
		if not TheWorld:HasTag("the_world") then
			pStartWildfire(self)
			if self.smolder_task then
				local pfn = self.smolder_task.fn
				self.smolder_task.fn = function(inst, self)
					if not TheWorld:HasTag("the_world") then
						pfn(inst, self)
					end
				end
			end
		end
	end
end)	-- <改写燃烧

AddComponentPostInit("childspawner", function(self)
	local pCanSpawn = self.CanSpawn
	self.CanSpawn = function(self)
		return not TheWorld:HasTag("the_world") and pCanSpawn(self)
	end
	local pCanEmergencySpawn = self.CanEmergencySpawn
	self.CanEmergencySpawn = function(self)
		return not TheWorld:HasTag("the_world") and pCanEmergencySpawn(self)
	end
end)	-- <改写巢穴类

AddComponentPostInit("combat", function(self)
	local pOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		if not self.inst:HasTag("time_stopped") then
			return pOnUpdate(self, dt)
		end
	end
	local pStartAttack = self.StartAttack
	self.StartAttack = function(self)
		if not self.inst:HasTag("time_stopped") then
			local ret = pStartAttack(self)
			self.inst:PushEvent("startattack")
			return ret
		end
	end
end)	-- <改写攻击

AddComponentPostInit("health", function(self)
	self.UpdateStatus = function(self)
		if self.currenthealth <= 0 then
			TheWorld:PushEvent("entity_death", { inst = self.inst, cause = self.lastcause, afflicter = self.lastafflicter })
			self.inst:PushEvent("death", { cause = self.lastcause, afflicter = self.lastafflicter })
			if(self.inst:HasTag("player")) then
				NotifyPlayerProgress("TotalPlayersKilled", 1, self.lastafflicter);
			else
				NotifyPlayerProgress("TotalEnemiesKilled", 1, self.lastafflicter);
			end
			if not self.nofadeout then
				self.inst:AddTag("NOCLICK")
				self.inst.persists = false
				self.inst:DoTaskInTime(self.destroytime or 2, ErodeAway)
			end
		end
	end
	local pSetVal = self.SetVal
	self.SetVal = function(self, val, cause, afflicter)
		if self.inst:HasTag("time_stopped") then
			if not TUNING.TIMESTOPPER_INVINCIBLE_FOE then
				self.lastcause = cause
				self.lastafflicter = afflicter
				local old_health = self.currenthealth
				local max_health = self:GetMaxWithPenalty()
				local min_health = math.min(self.minhealth or 0, max_health)

				if val > max_health then
					val = max_health
				end

				if val <= min_health then
					self.currenthealth = min_health
					self.inst:PushEvent("minhealth", { cause = cause, afflicter = afflicter })
				else
					self.currenthealth = val
				end
			end
		else
			self.lastcause = cause
			self.lastafflicter = afflicter
			pSetVal(self, val, cause, afflicter)
		end
	end
end)	-- <改写生命

AddComponentPostInit("disappears", function(self)
	local function eventfn()
		if self.disappeartask then
			self.taskfn = self.disappeartask.fn
			self.taskremaining = GetTimeForTick(self.disappeartask.nexttick - GetTick())
			if self.taskfn and self.taskremaining then
				self.disappeartask:Cancel()
				self.disappeartask = nil
			end
		end
	end
	local pPrepareDisappear = self.PrepareDisappear
	self.PrepareDisappear = function(self)
		if not self.twevent then
			self.twevent = self.inst:ListenForEvent("time_stopped", eventfn)
		end
		if not self.twevent2 then
			self.twevent2 = self.inst:ListenForEvent("time_resumed", function()
				if not self.disappeartask and self.taskfn and self.taskremaining then
					self.disappeartask = self.inst:DoTaskInTime(self.taskremaining > 0 and self.taskremaining + FRAMES * 3 or FRAMES * 3, self.taskfn, self)
				end
			end)
		end
		pPrepareDisappear(self)
		if self.inst:HasTag("time_stopped") then
			self.inst:DoTaskInTime(FRAMES, eventfn)
		end
	end
end)	-- <改写灰烬消失

AddComponentPostInit("boatphysics", function(self)
	local pOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		if not TheWorld:HasTag("the_world") then
			pOnUpdate(self, dt)
		end
	end
end)	-- <改写船物理

AddComponentPostInit("perishable", function(self)
	local pStartPerishing = self.StartPerishing
	self.StartPerishing = function(self)
		pStartPerishing(self)
		local pfn = self.updatetask.fn
		self.updatetask.fn = function(inst, dt)
			if not TheWorld:HasTag("the_world") then
				pfn(inst, dt)
			end
		end
	end
end)	-- <改写腐烂

AddComponentPostInit("playerprox", function(self)
	local ptargetmode = self.targetmode
	self.targetmode = function(inst, self)
		if not inst:HasTag("time_stopped") then
			ptargetmode(inst, self)
		end
	end
	local pSetTargetMode = self.SetTargetMode
	self.SetTargetMode = function(self, mode, target, override)
		local vmode = function(inst, self)
			if not inst:HasTag("time_stopped") then
				mode(inst, self)
			end
		end
		pSetTargetMode(self, vmode, target, override)
	end
end)	-- <改写玩家侦测

AddComponentPostInit("builder", function(self)
	table.insert(self.exclude_tags, "time_stopped")	-- 时停禁止使用建造站
end)	-- <改写建造

AddComponentPostInit("oldager", function(self)
	local pOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		return not self.inst:HasTag("time_stopped") and pOnUpdate(self, dt)
	end
	local pOnTakeDamage = self.OnTakeDamage
	self.OnTakeDamage = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		return not self.inst:HasTag("time_stopped") and pOnTakeDamage(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	end
end)	-- <改写Wanda衰老

AddComponentPostInit("clock", function(self)
	self.stopped = false
	self.Stop = function(self)
		self.stopped = true
	end
	self.Resume = function(self)
		self.stopped = false
	end
	local pOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		if not self.stopped then
			return pOnUpdate(self, dt)
		end
	end

end)	-- <改写时钟

AddPrefabPostInit("world", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if not inst.components.timer then
		inst:AddComponent("timer")
	end
	if not inst.components.timestopper_world then
		inst:AddComponent("timestopper_world")
	end
end)

AddPrefabPostInit("creepyeyes", function(inst)
	if ThePlayer == nil or ThePlayer.instoppedtime:value() ~= 0 then
		inst:DoTaskInTime(0, inst.Remove)
	else
		inst:DoTaskInTime(0, function()
			if ThePlayer.instoppedtime:value() ~= 0 then
				inst:Remove()
			end
		end)
		inst:ListenForEvent("instoppedtime", function(player)
			if player.instoppedtime:value() ~= 0 then
				inst:Remove()
			end
		end, ThePlayer)
	end
end)

-- 时停可刮牛毛
AddPrefabPostInit("beefalo", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.beard then
		local old_can = inst.components.beard.canshavetest
		inst.components.beard.canshavetest = function(inst, ...)
			if TheWorld:HasTag("the_world") then
				return true
			else
				return old_can(inst, ...)
			end
		end
	end
end)

AddPlayerPostInit(function(inst)
	if inst.prefab == "wortox" and TUNING.TIMESTOPPER_IGNORE_WORTOX or inst.prefab == "wanda" and TUNING.TIMESTOPPER_IGNORE_WANDA then
		inst:AddTag("timemaster")
		inst:AddTag("canmoveintime")
	end
	local pOnDespawn = inst.OnDespawn
	inst.OnDespawn = function(inst, migrationdata)
		if inst:HasTag("time_stopped") then
			inst:RemoveTag("time_stopped")
		end
		if inst:HasTag("stoppingtime") then
			inst:RemoveTag("stoppingtime")
		end
		if inst:HasTag("canmoveintime") and not inst:HasTag("timemaster") then
			inst:RemoveTag("canmoveintime")
		end
		pOnDespawn(inst, migrationdata)
	end
	inst.instoppedtime = net_float(inst.GUID, "instoppedtime", "instoppedtime")
	inst.globalsound = net_string(inst.GUID, "globalsound", "globalsound")
	inst:DoTaskInTime(0, function()
		inst:ListenForEvent("instoppedtime", function(inst)
			local time = inst.instoppedtime and inst.instoppedtime:value() or nil
			if TUNING.TIMESTOPPER_GREYSCREEN and time and time > 0 then
				if time < 1 then
					TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/ghost_cc.tex")
				else
					TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/mole_vision_on_cc.tex")
					TheWorld.grey_task = TheWorld:DoTaskInTime(0.25, function()
						TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/ghost_cc.tex")
					end)
				end
			elseif time and time == 0 then
				TheWorld:PushEvent("overridecolourcube", nil)
				if TheWorld.grey_task then
					TheWorld.grey_task:Cancel()
					TheWorld.grey_task = nil
				end
			end
			local x, y, z = inst.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, 1, { "FX" })
			for k, v in pairs(ents) do
				v:PushEvent("instoppedtime")
			end
		end)
		inst:ListenForEvent("globalsound", function(inst)
			local sound = inst.globalsound and inst.globalsound:value() or nil
			if sound then
				TheWorld.SoundEmitter:PlaySound(sound)
			end
		end)
	end)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, function()
		if not TUNING.TIMESTOPPER_IGNORE_CHARLIE then
			inst:ListenForEvent("the_world", function(world)
				inst.components.grue:AddImmunity("the_world")
			end, TheWorld)
			inst:ListenForEvent("the_world_end", function(world)
				inst.components.grue:RemoveImmunity("the_world")
			end, TheWorld)
		end
	end)
end)
AddPrefabPostInitAny(function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, function()
		inst:ListenForEvent("timerdone", function(inst, data)
			if data.name == "canmoveintime" and inst:HasTag("canmoveintime") and not inst:HasTag("timemaster") then
				inst:RemoveTag("canmoveintime")
			end
			if data.name == "stoppingtime" then
				if inst:HasTag("stoppingtime") then
					inst:RemoveTag("stoppingtime")
				end
			end
		end)
		inst:ListenForEvent("death", function(inst)
			if inst:HasTag("canmoveintime") and not inst:HasTag("timemaster") then
				inst:RemoveTag("canmoveintime")
			end
		end)
	end)
	if not inst.components.timer then
		inst:AddComponent("timer")
	end
end)

local fxp = {"raindrop", "wave_shimmer", "wave_shimmer_med", "wave_shimmer_deep", "wave_shimmer_flood", "wave_shore", "impact", "shatter"}
for _,v in pairs(fxp) do
	AddPrefabPostInit(v, function(inst)
		if ThePlayer and ThePlayer.instoppedtime:value() ~= 0 then
			inst:Hide()
		end
	end)
end

local fxv = {"staffcastfx", "staffcastfx_mount", "cointosscastfx", "cointosscastfx_mount"}
for _,v in pairs(fxv) do
	AddPrefabPostInit(v, function(inst)
		local pSetUp = inst.SetUp
		inst.SetUp = function(inst, colour)
			local parent = inst.entity:GetParent()
			if parent and parent:HasTag("canmoveintime") then
				inst:AddTag("canmoveintime")
			end
			pSetUp(inst, colour)
		end
	end)
end

local fxs = {"pocketwatch_cast_fx", "pocketwatch_cast_fx_mount", "pocketwatch_warpback_fx", "pocketwatch_warpbackout_fx"}
for _,v in pairs(fxs) do
	AddPrefabPostInit(v, function(inst)
		local pSetUp = inst.SetUp
		inst.SetUp = function(inst, colour)
			inst:AddTag("canmoveintime")
			pSetUp(inst, colour)
		end
	end)
end

local Precipitation = {rain = 0.2, caverain = 0.2, pollen = .0001, snow = 0.8}
for k, v in pairs(Precipitation)do
	AddPrefabPostInit(k, function(inst)
		local function vfxoff(inst)
			inst.VFXEffect:SetDragCoefficient(0,1)
		end
		local function vfxon(inst)
			inst.VFXEffect:SetDragCoefficient(0,v)
		end
		local function checktw(inst)
				if ThePlayer and ThePlayer.instoppedtime:value() ~= 0 then
					vfxoff(inst)
				else
					vfxon(inst)
				end
		end
		inst:DoTaskInTime(FRAMES, function()
			checktw(inst)
			inst:ListenForEvent("instoppedtime", checktw)
		end)
	end)
end