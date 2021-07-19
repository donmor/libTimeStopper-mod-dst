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


TUNING.TIMESTOPPER_PERFORMANCE_MODE = GetModConfigData("performance_mode")
TUNING.TIMESTOPPER_INVINCIBLE_FOE = GetModConfigData("invincible_foe")
-- TUNING.TIMESTOPPER_GLOBAL_GREY_EFFECT = GetModConfigData("global_grey_effect")


AddComponentPostInit("projectile", function(self)	-- <改写投射物等API以达到时停效果
	self.theworldstate = nil
	self.origspeed = nil
	local pSetSpeed = self.SetSpeed
	self.SetSpeed = function(self, speed)
		self.origspeed = speed
		return pSetSpeed(self, speed)
	end
	self.SetOnTheworldTriggeredFn = function(self, fn)
		self.ontheworldtriggeredfn = fn
	end
	self.OnTheworldTriggered = function(self, sw)
		if self.ontheworldtriggeredfn ~= nil then
			self.ontheworldtriggeredfn(self.inst, sw, self.origspeed)
		end
		if sw then
			if self.speed >= self.origspeed then
				self.speed = self.origspeed / 4
				self.inst.Physics:SetMotorVel(self.origspeed / 4, 0, 0)
				self.inst:DoTaskInTime((120 + 30 * math.random()) * FRAMES / self.origspeed, function()
					if TheWorld:HasTag("the_world") and self:IsThrown() then
						self.speed = 0.1
						self.inst.Physics:SetMotorVel(self.speed, 0, 0)
					end
				end)
			end
		else
			if self.speed <= self.origspeed / 4 then
				self.speed = self.origspeed / 4 + 1
				self.inst.Physics:SetMotorVel(self.origspeed / 4 + 1, 0, 0)
				self.inst:DoTaskInTime((120 + 30 * math.random()) * FRAMES / self.origspeed, function()
					if self:IsThrown() then
						self.speed = self.origspeed
						self.inst.Physics:SetMotorVel(self.speed, 0, 0)
					end
				end)
			end
		end
	end
	local pStop = self.Stop
	self.Stop = function(self)
		local ret = pStop(self)
		self.speed = self.origspeed
		self.theworldstate = nil
		return ret
	end
	local pOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		if self.target ~= nil then
			if TheWorld:HasTag("the_world") then
				self:OnTheworldTriggered(true)
			elseif self.theworldstate and not TheWorld:HasTag("the_world") then
				self:OnTheworldTriggered(false)
			end
			self.theworldstate = TheWorld:HasTag("the_world")
		end
		return pOnUpdate(self, dt)
	end
end)

AddComponentPostInit("burnable", function(self)	-- <改写燃烧API
	self.countdown = nil
	local function DoneBurning(inst, self)
        local isplant = inst:HasTag("plant") and not (inst.components.diseaseable ~= nil and inst.components.diseaseable:IsDiseased())
        local pos = isplant and inst:GetPosition() or nil
    
        inst:PushEvent("onburnt")

		if self.onburnt ~= nil then
			self.onburnt(inst)
		end

        if self.inst:IsValid() then
            if inst.components.explosive ~= nil then
                --explosive explode
                inst.components.explosive:OnBurnt()
            end

            if self.extinguishimmediately then
                self:Extinguish()
            end
        end

        if isplant then
            TheWorld:PushEvent("plantkilled", { pos = pos }) --this event is pushed in other places too
        end    
	end
	local function vtick(inst, self)
		if inst.components.explosive ~= nil and self.countdown > 0.1 or not inst:HasTag("time_stopped") then
			self.countdown = self.countdown - 0.1
			if self.countdown <= 0 then
				self.task:Cancel()
				self.task = nil
				self.countdown = nil
				DoneBurning(inst, self)
			end
		end
	end
	self.ExtendBurning = function(self)
		if self.task ~= nil then
			self.task:Cancel()
		end
		self.countdown = self.burntime
		self.task = self.burntime ~= nil and self.inst:DoPeriodicTask(0.1, vtick, nil, self) or nil
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
	self.twtask = nil
	local function vtick(inst, data)
		if not data.self.inst:HasTag("time_stopped") then
			data.self.twtask:Cancel()
			data.self.twtask = nil
			TheWorld:PushEvent("entity_death", { inst = data.self.inst, cause = data.cause, afflicter = data.afflicter })
			data.self.inst:PushEvent("death", { cause = data.cause, afflicter = data.afflicter })
            if(data.self.inst:HasTag("player")) then
                NotifyPlayerProgress("TotalPlayersKilled", 1, data.afflicter);
            else
                NotifyPlayerProgress("TotalEnemiesKilled", 1, data.afflicter);
            end
        	if not data.self.nofadeout then
				data.self.inst:AddTag("NOCLICK")
				data.self.inst.persists = false
				data.self.inst:DoTaskInTime(data.self.destroytime or 2, ErodeAway)
			end
		end
	end
	self.SetVal = function(self, val, cause, afflicter)
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

		if old_health > 0 and self.currenthealth <= 0 then
			if self.inst:HasTag("time_stopped") then
				self.twtask = self.inst:DoPeriodicTask(0.5, vtick, nil, { self = self, cause = cause, afflicter = afflicter })
			else
                --Push world event first, because the entity event may invalidate itself
                --i.e. items that use .nofadeout and manually :Remove() on "death" event
				TheWorld:PushEvent("entity_death", { inst = self.inst, cause = cause, afflicter = afflicter })
				self.inst:PushEvent("death", { cause = cause, afflicter = afflicter })

                --Here, check if killing player or monster
                if(self.inst:HasTag("player")) then
                    NotifyPlayerProgress("TotalPlayersKilled", 1, afflicter);
                else
                    NotifyPlayerProgress("TotalEnemiesKilled", 1, afflicter);
                end

                --V2C: If "death" handler removes ourself, then the prefab should explicitly set nofadeout = true.
                --     Intentionally NOT using IsValid() here to hide those bugs.
				if not self.nofadeout then
					self.inst:AddTag("NOCLICK")
					self.inst.persists = false
					self.inst:DoTaskInTime(self.destroytime or 2, ErodeAway)
				end
			end
		end
		if old_health <= 0 and self.currenthealth > 0 and self.twtask ~= nil then
			self.twtask:Cancel()
			self.twtask = nil
		end
	end
end)	-- >

AddPrefabPostInit("world", function(inst)
	-- inst.time_stopped = net_bool(inst.GUID, "stopped", "the_world")
    -- inst:AddComponent("timestopper_world")
    if not inst.components.timer then
        inst:AddComponent("timer")
    end
    if not inst.components.timestopper_world then
        inst:AddComponent("timestopper_world")
    end
end)

-- 时停可刮牛毛
AddPrefabPostInit("beefalo", function(inst)
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
    if not inst.components.timer then
        inst:AddComponent("timer")
    end
	-- if ThePlayer then
	-- 	ThePlayer:ListenForEvent("instoppedtime", function(inst1)
	-- 		print(inst)
	-- 		print(inst1)
	-- 		print(0)
	-- 	end)
	-- end
	inst.instoppedtime = net_bool(inst.GUID, "stopped", "instoppedtime")
    inst:DoTaskInTime(0, function()
        inst:ListenForEvent("timerdone", function(inst, data)
            if data.name == "canmoveintime" then
                if inst:HasTag("canmoveintime") then
                    inst:RemoveTag("canmoveintime")
                end
            end
        end)
    end)
end)

AddPrefabPostInit("raindrop", function(inst)
	if ThePlayer and ThePlayer.instoppedtime:value() then
	-- if ThePlayer and (ThePlayer:HasTag("time_stopped") or ThePlayer:HasTag("canmoveintime")) then
		inst:Hide()
	end
end)

local Precipitation = {rain = 0.2, caverain = 0.2, pollen = .0001, snow = 0.8}
for k, v in pairs(Precipitation)do
	AddPrefabPostInit(k, function(inst)
		local function vfxoff(inst)
			inst.VFXEffect:SetDragCoefficient(0,1)
		end
		local function vfxon(inst)
			inst.VFXEffect:SetDragCoefficient(0,v)
		end
		-- if ThePlayer then
		-- 	if ThePlayer.instoppedtime:value() then
		-- -- if ThePlayer and (ThePlayer:HasTag("time_stopped") or ThePlayer:HasTag("canmoveintime")) then
		-- 		vfxoff(inst)
		-- 	end
		-- 	ThePlayer:ListenForEvent("instoppedtime", function(inst1)
		-- 		print(inst)
		-- 		print(inst1)
		-- 		print(1)
		-- 		-- if inst.instoppedtime:value() then
		-- 		-- 	vfxoff()
		-- 		-- else
		-- 		-- 	vfxon()
		-- 		-- end
		-- 	end)
		-- end
		inst:DoPeriodicTask(0.1, function(inst)
			if ThePlayer and ThePlayer.instoppedtime:value() then
			-- if ThePlayer and (ThePlayer:HasTag("time_stopped") or ThePlayer:HasTag("canmoveintime")) then
				vfxoff(inst)
			else
				vfxon(inst)
			end
		end)
	end)
end

-- AddPrefabPostInitAny(function(inst)
-- 	if inst and inst:HasTag("FX") then
-- print(inst.prefab)
-- 		if ThePlayer and (ThePlayer:HasTag("time_stopped") or ThePlayer:HasTag("canmoveintime")) then
-- print(1)
-- -- 			if inst.AnimState then
-- -- print(0)
-- -- 				inst.AnimState:Pause()
-- -- 			end
-- 			inst:Hide()
-- 		end
-- 		inst:ListenForEvent("time_stopped", function(inst)
-- print(2)
-- 			if inst.AnimState then
-- 				inst.AnimState:Pause()
-- 			end
-- 		end, TheWorld)
-- 		inst:ListenForEvent("time_resumed", function(inst)
-- 			if inst.AnimState then
-- 				inst.AnimState:Resume()
-- 			end
-- 		end, TheWorld)
-- 	end
-- end)

-- AddPrefabPostInit("rain", function(inst)
	-- local tt = TheSim:GetTickTime()
	-- local tick_time = function()
	-- 	return TheWorld:HasTag("the_world") and 0 or tt
	-- end
    -- local desired_particles_per_second = 0--1000
    -- local desired_splashes_per_second = 0--100
    -- inst.particles_per_tick = desired_particles_per_second * tick_time()
    -- inst.splashes_per_tick = desired_splashes_per_second * tick_time()
	-- inst:DoPeriodicTask(0.1, function()
	-- 	inst.particles_per_tick = desired_particles_per_second * tick_time()
	-- 	inst.splashes_per_tick = desired_splashes_per_second * tick_time()
	-- end)
	-- local TEXTURE = "fx/rain.tex"
	-- local SHADER = "shaders/vfx_particle.ksh"
	-- local COLOUR_ENVELOPE_NAME = "raincolourenvelope"
	-- local SCALE_ENVELOPE_NAME = "rainscaleenvelope"
	-- local MAX_LIFETIME = 2
	-- local MIN_LIFETIME = 2
	-- local effect = inst.entity:AddVFXEffect()
    -- effect:InitEmitters(1)
    -- effect:SetRenderResources(0, TEXTURE, SHADER)
    -- effect:SetRotationStatus(0, true)
    -- effect:SetMaxNumParticles(0, 4800)
    -- effect:SetMaxLifetime(0, MAX_LIFETIME)
    -- effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    -- effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    -- effect:SetBlendMode(0, BLENDMODE.Premultiplied)
    -- effect:SetSortOrder(0, 3)
    -- effect:SetDragCoefficient(0, .2)
    -- effect:EnableDepthTest(0, true)
	-- local bx, by, bz = 0, 20, 0
	-- local emitter_shape = CreateBoxEmitter(bx, by, bz, bx + 20, by, bz + 20)
    -- local angle = 0
    -- local dx = math.cos(angle * PI / 180)
    -- effect:SetAcceleration(0, dx, -9.80, 1)
    -- local function emit_fn()
    --     local vy = -2 - 8 * UnitRand()
    --     local vz = 0
    --     local vx = dx
    --     local lifetime = MIN_LIFETIME + (MAX_LIFETIME - MIN_LIFETIME) * UnitRand()
    --     local px, py, pz = emitter_shape()

    --     effect:AddRotatingParticle(
    --         0,                  -- the only emitter
    --         lifetime,           -- lifetime
    --         px, py, pz,         -- position
    --         vx, vy, vz,         -- velocity
    --         angle, 0            -- angle, angular_velocity
    --     )
    -- end
    -- local raindrop_offset = CreateDiscEmitter(20)
	-- EmitterManager:AddEmitter(inst, nil, function(fastforward)
	-- 	while inst.num_particles_to_emit > 0 do
    --         emit_fn()
    --         inst.num_particles_to_emit = inst.num_particles_to_emit - 1
    --     end

    --     while inst.num_splashes_to_emit > 0 and not TheWorld:HasTag("the_world") do
    --         local x, y, z = inst.Transform:GetWorldPosition()
    --         local dx, dz = raindrop_offset()

    --         x = x + dx
    --         z = z + dz

    --         --if map:IsPassableAtPoint(x, y, z) then
    --             local raindrop = SpawnPrefab("raindrop")
    --             raindrop.Transform:SetPosition(x, y, z)

    --             if fastforward ~= nil then
    --                 raindrop.AnimState:FastForward(fastforward)
    --             end

    --         --end
    --         inst.num_splashes_to_emit = inst.num_splashes_to_emit - 1
    --     end

    --     inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick
    --     inst.num_splashes_to_emit = inst.num_splashes_to_emit + inst.splashes_per_tick

	-- end)
-- end)