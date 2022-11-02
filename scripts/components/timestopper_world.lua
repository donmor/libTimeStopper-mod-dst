local function IsInTable(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return true;
		end
	end
	return false;
end

local function getdist(ent1, ent2)
	local x1, y1, z1 = ent1.Transform:GetWorldPosition()
	local x2, y2, z2 = ent2.Transform:GetWorldPosition()
	return math.sqrt((x1 - x2) ^ 2 + (z1 - z2) ^ 2)
end

local TimeStopper_World = Class(function(self, inst)
	self.inst = inst
	self.twents = {}
	self.releasingfn = nil
end,
nil,
{

})

local function freeze(ent)
	local projcomp = ent.components.projectile
	local isproj = projcomp and projcomp:IsThrown()
	if ent.AnimState and not isproj then
		ent.AnimState:Pause()
	end
	if ent.Physics then
		local mass = ent.Physics:GetMass()
		if ent.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
			if ent.components.boatphysics then
				ent.Physics:SetMotorVel(0, 0, 0)
			end
		elseif mass ~= 0 or ent.Physics:GetMotorVel() ~= 0 then --质量为0, 但不是障碍物, 如海浪
			ent.vmass = mass
			if isproj then
				local ospeed = projcomp.origspeed
				local mult = math.random(90, 120) / 100
				if ent.projspeedtask then
					ent.projspeedtask:Cancel()
					ent.projspeedtask = nil
				end
				local function projspeedfn()
					projcomp.speed = projcomp.speed - mult * ospeed / 3
					if projcomp.speed < 0 or projcomp.target and projcomp.hitdist + projcomp.target:GetPhysicsRadius(0) >= getdist(ent, projcomp.target) then
						projcomp.speed = 0
					end
					ent.Physics:SetMotorVel(projcomp.speed, 0, 0)
					if projcomp.speed == 0 and ent.projspeedtask then
						ent.projspeedtask:Cancel()
						ent.projspeedtask = nil
						if ent.AnimState then
							ent.AnimState:Pause()
						end
						ent.Physics:SetMass(0)
					end
				end
				ent.projspeedtask = ent:DoPeriodicTask(1 / ospeed, projspeedfn)
				projspeedfn()
			else
				ent.Physics:SetMass(0)
				ent.Physics:SetActive(false)
			end
		end
	end
	if TheWorld.ismastersim then
		ent:StopBrain()
		if ent.sg then
			ent.sg:Stop()
			if ent.components.health and ent.components.oldager then
				ent.sg:AddStateTag("nomorph")
			end
		end
		if ent.components.locomotor then
			ent.components.locomotor:StopUpdatingInternal()
		end
		if ent.components.propagator then
			ent.components.propagator:StopUpdating()
		end
		if ent.components.playercontroller then
			ent.components.playercontroller:Enable(false)
		end
		if ent.components.burnable then
			ent.components.burnable:PauseBurning()
		end
		if ent.components.disappears then
			ent.components.disappears:PauseDisappearing()
		end
	end
	if not ent:HasTag("time_stopped") then
		ent:AddTag("time_stopped")
	end

end

local function resume(ent)
	local projcomp = ent.components.projectile
	local isproj = projcomp and projcomp:IsThrown()
	if ent.AnimState then
		ent.AnimState:Resume()
	end
	if ent.Physics then
		if ent.Physics:GetCollisionGroup() ~= COLLISION.OBSTACLES and ent.vmass ~= 0 or ent.Physics:GetMotorVel() ~= 0 then
			if ent.vmass then
				ent.Physics:SetMass(ent.vmass)
			end
			if isproj then
				local ospeed = projcomp.origspeed
				local mult = math.random(90, 120) / 100
				if ent.projspeedtask then
					ent.projspeedtask:Cancel()
					ent.projspeedtask = nil
				end
				ent.projspeedtask = ent:DoPeriodicTask(1 / ospeed, function()
					projcomp.speed = projcomp.speed + mult * ospeed / 3
					if projcomp.speed > ospeed then
						projcomp.speed = ospeed
					end
					ent.Physics:SetMotorVel(projcomp.speed, 0, 0)
					if projcomp.speed == ospeed and ent.projspeedtask then
						ent.projspeedtask:Cancel()
						ent.projspeedtask = nil
					end
				end)
			else
				ent.Physics:SetActive(true)
			end
		end
	end
	if TheWorld.ismastersim then
		ent:RestartBrain()
		if ent.sg and ent.sg.stopped then
			ent.sg:Start()
		end
		if ent.components.locomotor then
			ent.components.locomotor:StartUpdatingInternal()
		end
		if ent.components.propagator then
			ent.components.propagator:StartUpdating()
		end
		if ent.components.playercontroller then
			ent.components.playercontroller:Enable(true)
		end
		if ent.components.health then
			ent.components.health:UpdateStatus()
			if ent.components.oldager then
				if ent.sg then
					ent.sg:RemoveStateTag("nomorph")
				end
				ent:PushEvent("healthdelta", { oldpercent = ent.components.health:GetPercent(), newpercent = ent.components.health:GetPercent(), overtime = false, cause = "oldager_component", afflicter = nil, amount = 0 })
			end
		end
		if ent.components.burnable then
			ent.components.burnable:ResumeBurning()
		end
		if ent.components.disappears then
			ent.components.disappears:ResumeDisappearing()
		end
	end
	if ent:HasTag("time_stopped") then
		ent:RemoveTag("time_stopped")
	end
end

function TimeStopper_World:OnPeriod()
	for k, v in pairs(AllPlayers) do
		if v.instoppedtime:value() == 0 then
			v.instoppedtime:set(TheWorld.nogrey and -0.5 or 0.5)
		end
		local x0, y0, z0 = v.Transform:GetWorldPosition()
		for k, v in pairs(TheSim:FindEntities(x0, y0, z0, TUNING.TIMESTOPPER_PERFORMANCE, nil, {"wall", "INLIMBO", "time_stopped", "canmoveintime"})) do
			if v and v:IsValid() and
					not (v:HasTag("ghostlyelixirable") and v.components.follower and
					v.components.follower:GetLeader() and v.components.follower:GetLeader():HasTag("canmoveintime")) and
					not (TUNING.TIMESTOPPER_IGNORE_SHADOW and
					(v:HasTag("shadowcreature") or
					string.find(v.prefab or "", "shadowhand") == 1 or
					string.find(v.prefab or "", "waveyjones") == 1 or
					v.prefab == "shadowskittish" or
					v.prefab == "shadowwatcher" or
					v.prefab == "creepyeyes")) then
				freeze(v)
				v:PushEvent("time_stopped")
				if not IsInTable(self.twents, v) then
					table.insert(self.twents, v)
				end
			end
		end
	end
end

function TimeStopper_World:OnResume()
	for k, v in pairs(AllPlayers) do
		v.instoppedtime:set(0)
	end
	for k, v in pairs(self.twents) do
		if v:HasTag("time_stopped") then
			resume(v)
			v:PushEvent("time_resumed")
		end
	end
	self.twents = {}
end


function TimeStopper_World:DoTimeStop(time, host, silent, nogrey)
	if time == 0 then
		return
	end
	local function makestopping(ent)
		if ent and ent:IsValid() then
			if time > 0 then
				if not ent.components.timer:TimerExists("stoppingtime") then
					if not ent:HasTag("stoppingtime") then
						ent.components.timer:StartTimer("stoppingtime", time + 0.1)
					end
				elseif ent.components.timer:GetTimeLeft("stoppingtime") < time then
					ent.components.timer:SetTimeLeft("stoppingtime", time + 0.1)
				end
			elseif ent.components.timer:TimerExists("stoppingtime") then
				ent.components.timer:StopTimer("stoppingtime")
			end
			if not ent:HasTag("stoppingtime") then
				ent:AddTag("stoppingtime")
			end
			self:ResumeEntity(ent, time)
		end
	end
	local grandhost = host and host.components.timestopper and host.components.timestopper:GetHost()
	makestopping(host)
	if grandhost and grandhost ~= host then
		makestopping(grandhost)
	end
	if not TheWorld:HasTag("the_world") then
		TheWorld.twtask = TheWorld:DoPeriodicTask(0.1, function() self:OnPeriod() end)
		TheWorld.nogrey = nogrey
		for k, v in pairs(AllPlayers) do
			v.instoppedtime:set(nogrey and -math.abs(time) or math.abs(time))
		end
		if time > 0 then
			if not TheWorld.components.timer:TimerExists("the_world") then
				TheWorld.components.timer:StartTimer("the_world", time)
			else
				TheWorld.components.timer:SetTimeLeft("the_world", time)
			end
		elseif TheWorld.components.timer:TimerExists("the_world") then
			TheWorld.components.timer:StopTimer("the_world")
		end
		TheWorld.net.components.clock:Stop()
		TheWorld:AddTag("the_world")
		TheWorld:PushEvent("the_world")
		if host and host.components.timestopper then
			if host.components.timestopper.ontimestoppedfn then
				host.components.timestopper.ontimestoppedfn(silent)
			end
			if time > 0 then
				local time2 = time - host.components.timestopper.onresumingtime
				if TheWorld.components.timer:TimerExists("twreleasing") then
					if TheWorld.components.timer:GetTimeLeft("twreleasing") < time2 then
						TheWorld.components.timer:SetTimeLeft("twreleasing", time2)
					end
				else
					TheWorld.components.timer:StartTimer("twreleasing", time2)
				end
				self.releasingfn = host.components.timestopper.onresumingfn
			elseif ent.components.timer:TimerExists("twreleasing") then
				ent.components.timer:StopTimer("twreleasing")
			end
		end
	else
		if time > 0 then
			if TheWorld.components.timer:TimerExists("the_world") and TheWorld.components.timer:GetTimeLeft("the_world") < time then
				TheWorld.components.timer:SetTimeLeft("the_world", time)
				if host and host.components.timestopper then
					local time2 = time - host.components.timestopper.onresumingtime
					if TheWorld.components.timer:TimerExists("twreleasing") then
						if TheWorld.components.timer:GetTimeLeft("twreleasing") < time2 then
							TheWorld.components.timer:SetTimeLeft("twreleasing", time2)
						end
					else
						TheWorld.components.timer:StartTimer("twreleasing", time2)
					end
					self.releasingfn = host.components.timestopper.onresumingfn
				end
			end
		else
			if ent.components.timer:TimerExists("the_world") then
				ent.components.timer:StopTimer("the_world")
			end
			if ent.components.timer:TimerExists("twreleasing") then
				ent.components.timer:StopTimer("twreleasing")
			end
		end
		if host and host.components.timestopper and host.components.timestopper.ontimestoppedfn then
			host.components.timestopper.ontimestoppedfn(true)
		end
	end
	if not TheWorld.twlistener then
		TheWorld.twlistener = TheWorld:ListenForEvent("timerdone", function(inst, data)
			if data.name == "the_world" then
				self:BreakTimeStop()
			end
			if data.name == "twreleasing" and self.releasingfn then
				self.releasingfn()
				self.releasingfn = nil
			end
		end)
	end

end

function TimeStopper_World:ResumeEntity(ent, time)
	if not (ent and ent:IsValid() and time ~= 0) or ent:HasTag("timemaster") then
		return
	end
	if time > 0 then
		if not ent.components.timer:TimerExists("canmoveintime") then
			if not ent:HasTag("canmoveintime") then
				ent.components.timer:StartTimer("canmoveintime", time + 0.1)
			end
		elseif ent.components.timer:GetTimeLeft("canmoveintime") < time then
			ent.components.timer:SetTimeLeft("canmoveintime", time + 0.1)
		end
	elseif ent.components.timer:TimerExists("canmoveintime") then
		ent.components.timer:StopTimer("canmoveintime")
	end
	if not ent:HasTag("canmoveintime") and not ent:HasTag("timemaster") then
		ent:AddTag("canmoveintime")
	end
	resume(ent)
	if ent.components.ghostlybond and not ent.components.ghostlybond.notsummoned and ent.components.ghostlybond.ghost and ent.components.ghostlybond.ghost:IsValid() then
		self:ResumeEntity(ent.components.ghostlybond.ghost, time)
	end
end

function TimeStopper_World:BreakTimeStop()
	if TheWorld.components.timer:TimerExists("twreleasing") then
		TheWorld.components.timer:StopTimer("twreleasing")
	end
	if TheWorld.components.timer:TimerExists("the_world") then
		TheWorld.components.timer:StopTimer("the_world")
	end
	if TheWorld.twtask ~= nil then
		TheWorld.twtask:Cancel()
		TheWorld.twtask = nil
	end
	self:OnResume()
	TheWorld.net.components.clock:Resume()
	TheWorld:DoTaskInTime(0.1, function()
		if TheWorld:HasTag("the_world") then
			TheWorld:RemoveTag("the_world")
		end
	end)
	TheWorld:PushEvent("the_world_end")
end

function TimeStopper_World:BreakMovability(ent)
	if ent and ent:IsValid() then
		if ent.components.timer:TimerExists("canmoveintime") then
			ent.components.timer:StopTimer("canmoveintime")
		end
		if ent.components.timer:TimerExists("stoppingtime") then
			ent.components.timer:StopTimer("stoppingtime")
		end
		if ent:HasTag("canmoveintime") and not ent:HasTag("timemaster") then
			ent:RemoveTag("canmoveintime")
		end
		if ent:HasTag("stoppingtime") then
			ent:RemoveTag("stoppingtime")
		end
	end
end

function TimeStopper_World:OnRemoveFromEntity()
	TheWorld:RemoveTag("the_world")
end

return TimeStopper_World