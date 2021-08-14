local function SYS_INITGLOBAL()
	GLOBAL.setmetatable(env, {
		__index = function(t, k)
			if k ~= "PrefabFiles" and k ~= "Assets" and k ~= "clothing_exclude" then
				return GLOBAL[k] and GLOBAL[k] or nil
			end
		end,
	})	
end
SYS_INITGLOBAL()

TUNING.TIMESTOPPER_PERFORMANCE = GetModConfigData("performance") or 500
TUNING.TIMESTOPPER_IGNORE_SHADOW = GetModConfigData("ignore_shadow") or true
TUNING.TIMESTOPPER_IGNORE_WORTOX = GetModConfigData("ignore_wortox") or false
TUNING.TIMESTOPPER_INVINCIBLE_FOE = GetModConfigData("invincible_foe") or false
TUNING.TIMESTOPPER_GREYSCREEN = GetModConfigData("greyscreen") or true

AddComponentPostInit("projectile", function(self)	-- <改写投射物等API以达到时停效果
	-- self.theworldstate = nil
	self.origspeed = self.speed
	local pSetSpeed = self.SetSpeed
	self.SetSpeed = function(self, speed)
		self.origspeed = speed
		return pSetSpeed(self, speed)
	end
	-- self.SetOnTheworldTriggeredFn = function(self, fn)
	-- 	self.ontheworldtriggeredfn = fn
	-- end
	-- self.OnTheworldTriggered = function(self, sw)
	-- 	-- if self.ontheworldtriggeredfn ~= nil then
	-- 	-- 	self.ontheworldtriggeredfn(self.inst, sw, self.origspeed)
	-- 	-- end
	-- 	if sw then
	-- 		if self.speed >= self.origspeed then
	-- 			self.speed = self.origspeed / 4
	-- 			self.inst.Physics:SetMotorVel(self.origspeed / 4, 0, 0)
	-- 			self.inst:DoTaskInTime((120 + 30 * math.random()) * FRAMES / self.origspeed, function()
	-- 				if TheWorld:HasTag("the_world") and self:IsThrown() then
	-- 					self.speed = 0
	-- 					self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	-- 				end
	-- 			end)
	-- 		end
	-- 	else
	-- 		if self.speed <= self.origspeed / 4 then
	-- 			self.speed = self.origspeed / 4 + 1
	-- 			self.inst.Physics:SetMotorVel(self.origspeed / 4 + 1, 0, 0)
	-- 			self.inst:DoTaskInTime((120 + 30 * math.random()) * FRAMES / self.origspeed, function()
	-- 				if self:IsThrown() then
	-- 					self.speed = self.origspeed
	-- 					self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	-- 				end
	-- 			end)
	-- 		end
	-- 	end
	-- end
	local pStop = self.Stop
	self.Stop = function(self)
		self.speed = self.origspeed
		if self.inst.projspeedtask then
			self.inst.projspeedtask:Cancel()
			self.inst.projspeedtask = nil
		end
		-- self.theworldstate = nil
		return pStop(self)
	end
	-- local pOnUpdate = self.OnUpdate
	-- self.OnUpdate = function(self, dt)
	-- 	if self.target ~= nil then
	-- 		print(self.inst:HasTag("time_stopped"))
	-- 		-- if self.inst:HasTag("time_stopped") then
	-- 		if TheWorld:HasTag("the_world") then
	-- 			-- self:OnTheworldTriggered(true)
	-- 		else
	-- 		-- elseif self.theworldstate and not TheWorld:HasTag("the_world") then
	-- 			-- self:OnTheworldTriggered(false)
	-- 		end
	-- 		-- self.theworldstate = TheWorld:HasTag("the_world")
	-- 	end
	-- 	return pOnUpdate(self, dt)
	-- end
end)

AddComponentPostInit("burnable", function(self)	-- <改写燃烧API
	-- self.countdown = nil
	-- local function DoneBurning(inst, self)
    --     local isplant = inst:HasTag("plant") and not (inst.components.diseaseable ~= nil and inst.components.diseaseable:IsDiseased())
    --     local pos = isplant and inst:GetPosition() or nil
    
    --     inst:PushEvent("onburnt")

	-- 	if self.onburnt ~= nil then
	-- 		self.onburnt(inst)
	-- 	end

    --     if self.inst:IsValid() then
    --         if inst.components.explosive ~= nil then
    --             --explosive explode
    --             inst.components.explosive:OnBurnt()
    --         end

    --         if self.extinguishimmediately then
    --             self:Extinguish()
    --         end
    --     end

    --     if isplant then
    --         TheWorld:PushEvent("plantkilled", { pos = pos }) --this event is pushed in other places too
    --     end    
	-- end
	-- local function vtick(inst, self)
	-- 	if inst.components.explosive ~= nil and self.countdown > 0.1 or not inst:HasTag("time_stopped") then
	-- 		self.countdown = self.countdown - 0.1
	-- 		if self.countdown <= 0 then
	-- 			self.task:Cancel()
	-- 			self.task = nil
	-- 			self.countdown = nil
	-- 			DoneBurning(inst, self)
	-- 		end
	-- 	end
	-- end
		local function eventfn()
			-- print("BURN")
			if self.task then
				self.taskfn = self.task.fn
				self.taskremaining = GetTimeForTick(self.task.nexttick - GetTick())
				-- print("REMAINING", self.taskremaining)
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
			-- self.twevent = self.inst:ListenForEvent("time_stopped", function()
				-- print("LISTENER")
				-- eventfn(self)
				-- if self.task then 
				-- 	self.taskfn = self.task.fn
				-- 	self.taskremaining = GetTimeForTick(self.task.nexttick - GetTick())
				-- 	if self.taskfn and self.taskremaining then 
				-- 		self.task:Cancel()
				-- 		self.task = nil
				-- 	end
				-- end
			-- end)
		end
		if not self.twevent2 then 
			self.twevent2 = self.inst:ListenForEvent("time_resumed", function()
				-- print("RESUME", self.taskfn, self.taskremaining)
				if not self.task and self.taskfn and self.taskremaining then
					self.task = self.inst:DoTaskInTime(self.taskremaining > 0 and self.taskremaining + FRAMES * 3 or FRAMES * 3, self.taskfn, self)
				end
			end)
		end
		pExtendBurning(self)
		if self.inst:HasTag("time_stopped") then
			self.inst:DoTaskInTime(FRAMES, eventfn)
		end
		-- if self.task ~= nil then
		-- 	self.task:Cancel()
		-- end
		-- self.countdown = self.burntime
		-- self.task = self.burntime ~= nil and self.inst:DoPeriodicTask(0.1, vtick, nil, self) or nil
	end    
	local pStartWildfire = self.StartWildfire
	self.StartWildfire = function(self)
		pStartWildfire(self)
		local pfn = self.smolder_task.fn
		self.smolder_task.fn = function(inst, self)
			-- print(inst, "CHECK")
			if not TheWorld:HasTag("the_world") then
				-- print(inst, "UPDATE")
				pfn(inst, self)
			end
		end

	end
end)

AddComponentPostInit("childspawner", function(self)	-- <改写巢穴类API
	local pCanSpawn = self.CanSpawn
	self.CanSpawn = function(self)
		return not TheWorld:HasTag("the_world") and pCanSpawn(self)
	end
	local pCanEmergencySpawn = self.CanEmergencySpawn
	self.CanEmergencySpawn = function(self)
		return not TheWorld:HasTag("the_world") and pCanEmergencySpawn(self)
	end
end)	-- >

AddComponentPostInit("combat", function(self)	-- <改写攻击API
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
end)	-- >

AddComponentPostInit("health", function(self)	-- <改写生命API
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
	-- self.twtask = nil
	-- local function vtick(inst, data)
	-- 	if not data.self.inst:HasTag("time_stopped") then
	-- 		data.self.twtask:Cancel()
	-- 		data.self.twtask = nil
	-- 		TheWorld:PushEvent("entity_death", { inst = data.self.inst, cause = data.cause, afflicter = data.afflicter })
	-- 		data.self.inst:PushEvent("death", { cause = data.cause, afflicter = data.afflicter })
    --         if(data.self.inst:HasTag("player")) then
    --             NotifyPlayerProgress("TotalPlayersKilled", 1, data.afflicter);
    --         else
    --             NotifyPlayerProgress("TotalEnemiesKilled", 1, data.afflicter);
    --         end
    --     	if not data.self.nofadeout then
	-- 			data.self.inst:AddTag("NOCLICK")
	-- 			data.self.inst.persists = false
	-- 			data.self.inst:DoTaskInTime(data.self.destroytime or 2, ErodeAway)
	-- 		end
	-- 	end
	-- end
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
				print(cause)
				-- if old_health > 0 and self.currenthealth <= 0 then
					-- if self.inst:HasTag("time_stopped") then
						-- self.twtask = self.inst:DoPeriodicTask(0.5, vtick, nil, { self = self, cause = cause, afflicter = afflicter })
					-- else
					--     --Push world event first, because the entity event may invalidate itself
					--     --i.e. items that use .nofadeout and manually :Remove() on "death" event
					-- 	TheWorld:PushEvent("entity_death", { inst = self.inst, cause = cause, afflicter = afflicter })
					-- 	self.inst:PushEvent("death", { cause = cause, afflicter = afflicter })

					--     --Here, check if killing player or monster
					--     if(self.inst:HasTag("player")) then
					--         NotifyPlayerProgress("TotalPlayersKilled", 1, afflicter);
					--     else
					--         NotifyPlayerProgress("TotalEnemiesKilled", 1, afflicter);
					--     end

					--     --V2C: If "death" handler removes ourself, then the prefab should explicitly set nofadeout = true.
					--     --     Intentionally NOT using IsValid() here to hide those bugs.
					-- 	if not self.nofadeout then
					-- 		self.inst:AddTag("NOCLICK")
					-- 		self.inst.persists = false
					-- 		self.inst:DoTaskInTime(self.destroytime or 2, ErodeAway)
					-- 	end
					-- end
				-- end
				-- if old_health <= 0 and self.currenthealth > 0 and self.twtask ~= nil then
				-- 	self.twtask:Cancel()
				-- 	self.twtask = nil
				-- end
			end
		else
			self.lastcause = cause
			self.lastafflicter = afflicter
			pSetVal(self, val, cause, afflicter)
		end
	end
	-- local pDoFireDamage = self.DoFireDamage
	-- self.DoFireDamage = function(self, amount, doer, instant)
	-- 	print("FIRE", amount, doer, instant)
	-- 	if instant or not self.inst:HasTag("time_stopped") then
	-- 		pDoFireDamage(self, amount, doer, instant)
	-- 	end
	-- end
	-- local pOnUpdate = self.OnUpdate
	-- self.OnUpdate = function(self, dt)
	-- 	if not self.inst:HasTag("time_stopped") then
	-- 		pOnUpdate(self, dt)
	-- 	end
	-- end
end)	-- >

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
end)

-- AddComponentPostInit("workable", function(self)
-- 	local pWorkedBy = self.WorkedBy
-- 	self.WorkedBy = function(self, worker, numworks)
-- 		return pWorkedBy(self, worker, numworks)
-- 	end
-- end)

AddComponentPostInit("perishable", function(self)
	local pStartPerishing = self.StartPerishing
	self.StartPerishing = function(self)
		pStartPerishing(self)
		local pfn = self.updatetask.fn
		self.updatetask.fn = function(inst, dt)
			-- print(inst, "CHECK")
			if not TheWorld:HasTag("the_world") then
				-- print(inst, "UPDATE")
				pfn(inst, dt)
			end
		end
	end
end)

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
		-- print("UPDATE")
		if not self.stopped then
			return pOnUpdate(self, dt)
		end
	end
	
end)	-- >

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

-- AddPrefabPostInit("moon_tree_blossom_worldgen", function(inst)
-- 	inst:AddTag("perishable_worldgen")
-- 	if not TheWorld.ismastersim then
-- 		return
-- 	end
-- 	local pOnPickup = inst.components.inventoryitem.onpickupfn
-- 	inst.components.inventoryitem:SetOnPickupFn(function(inst, pickupguy, src_pos)
-- 		inst:RemoveTag("perishable_worldgen")
-- 		return pOnPickup(inst, pickupguy, src_pos)
-- 	end)
-- end)

-- AddPrefabPostInit("wobster_sheller_land", function(inst)
-- 	inst:AddTag("small_livestock")
-- end)

AddPlayerPostInit(function(inst)
	if inst.prefab == "wortox" and TUNING.TIMESTOPPER_IGNORE_WORTOX then
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
        -- inst:ListenForEvent("timerdone", function(inst, data)
        --     if data.name == "canmoveintime" then
        --         if inst:HasTag("canmoveintime") then
        --             inst:RemoveTag("canmoveintime")
        --         end
        --     end
        -- end)
        inst:ListenForEvent("instoppedtime", function(inst)
			-- print("000")
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
		-- 	local em = {}
		-- 	for k, v in pairs(Precipitation) do
		-- 		local FindEntity
		-- 	end
            -- if data.name == "canmoveintime" then
            --     if inst:HasTag("canmoveintime") then
            --         inst:RemoveTag("canmoveintime")
            --     end
            -- end
        end)
        inst:ListenForEvent("globalsound", function(inst)
			local sound = inst.globalsound and inst.globalsound:value() or nil
			if sound then
				TheWorld.SoundEmitter:PlaySound(sound)
			end
        end)
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
	-- inst:ListenForEvent("the_world_end", function(inst)
	-- 	if inst.components.timestopper and inst.components.timestopper.onresumedfn then 
	-- 		inst.components.timestopper.onresumedfn(silent)
	-- 	end
	-- end, TheWorld)
end)

local fxp = {"raindrop","wave_shimmer","wave_shimmer_med", "wave_shimmer_deep","wave_shimmer_flood","wave_shore","impact","shatter"}
for _,v in pairs(fxp) do 
	AddPrefabPostInit(v, function(inst)
		if ThePlayer and ThePlayer.instoppedtime:value() ~= 0 then
			inst:Hide()
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
			-- print("CHK")
				if ThePlayer and ThePlayer.instoppedtime:value() ~= 0 then
					vfxoff(inst)
				else
					vfxon(inst)
				end
		end
		inst:DoTaskInTime(FRAMES, function()
			-- inst:DoPeriodicTask(0.1, checktw)
			checktw(inst)
			inst:ListenForEvent("instoppedtime", checktw)
		end)
	end)
end