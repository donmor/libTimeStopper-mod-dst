local function IsInTable(tbl, value)
	for k, v in ipairs(tbl) do
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

local timestopper_world = Class(function(self, inst)
    self.inst = inst
    self.twents = {}
    self.releasingfn = nil
end,
nil,
{

})

function timestopper_world:OnPeriod()
    for k, v in pairs(AllPlayers) do
        local x0, y0, z0 = v.Transform:GetWorldPosition()
        for k, v in pairs(TheSim:FindEntities(x0, y0, z0, TUNING.TIMESTOPPER_PERFORMANCE_MODE and 1000 or 50, nil, {"wall", "INLIMBO", "time_stopped", "canmoveintime"})) do
            if v and v:IsValid() and not IsInTable(v, self.twents) and
                    not (TUNING.TIMESTOPPER_IGNORE_SHADOW and
                    (v:HasTag("shadowcreature") or
                    string.find(v.prefab or "", "shadowhand") == 1 or
                    string.find(v.prefab or "", "waveyjones") == 1 or
                    v.prefab == "shadowskittish" or
                    v.prefab == "shadowwatcher" or
                    v.prefab == "creepyeyes")) then
                local projcomp = v.components.projectile
                local isproj = projcomp and projcomp:IsThrown()
                if v.AnimState and not isproj then
                    v.AnimState:Pause()
                end
                if v.Physics then
                    local mass = v.Physics:GetMass()
                    if v.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
                        -- Ignore OBSTACLES
                    elseif mass ~= 0 or v.Physics:GetMotorVel() ~= 0 then --质量为0, 但不是障碍物, 如海浪
                        v.vmass = mass
                        if isproj then
                            local ospeed = projcomp.origspeed
                            -- v.projspeedtask = v:DoPeriodicTask(90/4/30/30, function()
                            --     projcomp.speed = projcomp.speed - 6
                            local mult = math.random(80, 110) / 100
                            if v.projspeedtask then
                                v.projspeedtask:Cancel()
                                v.projspeedtask = nil
                            end
                            local function projspeedfn()
                                projcomp.speed = projcomp.speed - mult * ospeed / 3
                                if projcomp.speed < 0 or projcomp.target and projcomp.hitdist + projcomp.target:GetPhysicsRadius(0) >= getdist(v, projcomp.target) then   -- TODO: TESTING
                                    projcomp.speed = 0
                                end
                                v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                                if projcomp.speed == 0 and v.projspeedtask then
                                    v.projspeedtask:Cancel()
                                    v.projspeedtask = nil
                                    if v.AnimState then
                                        v.AnimState:Pause()
                                    end
                                    v.Physics:SetMass(0)
                                end
                            end
                            v.projspeedtask = v:DoPeriodicTask(1 / ospeed, projspeedfn)
                            projspeedfn()
                            -- if projcomp.speed >= projcomp.origspeed then
                            --     projcomp.speed = projcomp.origspeed / 4
                            --     v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                            --     v:DoTaskInTime((180 + math.random(0, 60)) * FRAMES / projcomp.origspeed, function()
                            --         projcomp.speed = 0
                            --         v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                            --         if v.AnimState then
                            --             v.AnimState:Pause()
                            --         end
                            --     end)
                            -- end                
                        else
                            v.Physics:SetMass(0)
                            v.Physics:SetActive(false)
                        end
                    end
                end
                if TheWorld.ismastersim then
                    v:StopBrain()
                    if v.sg then
                        v.sg:Stop()
                    end
                    if v.components.combat then
                        v.components.combat:SetTarget(nil)
                    end
                    if v.components.locomotor then
                        v.components.locomotor:StopUpdatingInternal()
                    end
                    if v.components.playercontroller then
                        v.components.playercontroller:Enable(false)
                    end
                    if TUNING.TIMESTOPPER_INVINCIBLE_FOE and v.components.health then
                        v.components.health:SetInvincible(true)
                    end
                end
                if not v:HasTag("time_stopped") then
                    v:AddTag("time_stopped")
                    v:PushEvent("time_stopped")
                end
                if not IsInTable(v, self.twents) then
                    table.insert(self.twents, v)
                end
            end
        end
    end
end

function timestopper_world:OnResume()
    for k, v in pairs(AllPlayers) do
        v.instoppedtime:set(false)
    end
    for k, v in pairs(self.twents) do
        if v:HasTag("time_stopped") then
            local projcomp = v.components.projectile
            local isproj = projcomp and projcomp:IsThrown()
            if v.AnimState then
                v.AnimState:Resume()
            end
            if v.Physics then
                if v.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
                    -- Ignore OBSTACLES            
                elseif v.vmass ~= 0 or v.Physics:GetMotorVel() ~= 0 then
                    if v.vmass then
                        v.Physics:SetMass(v.vmass)
                    end
                    if isproj then
                        local ospeed = projcomp.origspeed
                        local mult = math.random(80, 110) / 100
                        if v.projspeedtask then
                            v.projspeedtask:Cancel()
                            v.projspeedtask = nil
                        end
                        v.projspeedtask = v:DoPeriodicTask(1 / ospeed, function()
                            projcomp.speed = projcomp.speed + mult * ospeed / 3
                            if projcomp.speed > ospeed or projcomp.target and projcomp.hitdist + projcomp.target:GetPhysicsRadius(0) >= getdist(v, projcomp.target) then
                                projcomp.speed = ospeed
                            end
                            v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                            if projcomp.speed == ospeed and v.projspeedtask then
                                v.projspeedtask:Cancel()
                                v.projspeedtask = nil
                            end
                        end)
                    -- if projcomp.speed < projcomp.origspeed / 4 then
                        --     projcomp.speed = projcomp.origspeed / 4 + 1
                        --     v.Physics:SetMotorVel(projcomp.origspeed / 4 + 1, 0, 0)
                        --     v:DoTaskInTime((180 + math.random(0, 60)) * FRAMES / projcomp.origspeed, function()
                        --         projcomp.speed = projcomp.origspeed
                        --         v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                        --     end)
                        -- end
                    else
                        v.Physics:SetActive(true)
                    end
            end
            end
            if TheWorld.ismastersim then
                v:RestartBrain()
                if v.sg then
                    v.sg:Start()
                end
                if v.components.locomotor then
                    v.components.locomotor:StartUpdatingInternal()
                end
                if v.components.playercontroller then
                    v.components.playercontroller:Enable(true)
                end
                if TUNING.TIMESTOPPER_INVINCIBLE_FOE then
                    v.components.health:SetInvincible(false)
                end
            end
            if v:HasTag("time_stopped") then
                v:RemoveTag("time_stopped")
                v:PushEvent("time_resumed")
            end
        end
    end
    self.twents = {}
end


function timestopper_world:DoTimeStop(host, time, silent)
    host:AddTag("canmoveintime")
    if not host.components.timer:TimerExists("canmoveintime") then
        host.components.timer:StartTimer("canmoveintime", time + 0.1)
    else
        host.components.timer:SetTimeLeft("canmoveintime", time + 0.1)
    end
    if host.AnimState then
        host.AnimState:Resume()
    end
    if host.components.locomotor then
        host.components.locomotor:StartUpdatingInternal()
    end
    if host.components.playercontroller then
        host.components.playercontroller:Enable(true)
    end
    if host:HasTag("time_stopped") then
        host:RemoveTag("time_stopped")
    end
    if not TheWorld:HasTag("the_world") then
        TheWorld.twtask = TheWorld:DoPeriodicTask(0.1, function() self:OnPeriod() end)
        for k, v in pairs(AllPlayers) do
            v.instoppedtime:set(true)
        end
        if not TheWorld.components.timer:TimerExists("the_world") then
            TheWorld.components.timer:StartTimer("the_world", time)
        else
            TheWorld.components.timer:SetTimeLeft("the_world", time)
        end
        TheWorld:AddTag("the_world")
        if host.components.timestopper then 
            host.components.timestopper:OnTimeStopped(silent)
            if TheWorld.components.timer:TimerExists("twreleasing") then
                TheWorld.components.timer:SetTimeLeft("twreleasing", time - host.components.timestopper:GetResumingTimer())
            else
                TheWorld.components.timer:StartTimer("twreleasing", time - host.components.timestopper:GetResumingTimer())
            end
            self.releasingfn = host.components.timestopper:GetOnResumingFn()
        end
    else
        if TheWorld.components.timer:GetTimeLeft("the_world") < time then
            if TheWorld.components.timer:TimerExists("the_world") then
                TheWorld.components.timer:SetTimeLeft("the_world", time)
            else
                TheWorld.components.timer:StartTimer("the_world", time)
            end
            if host.components.timestopper then 
                if TheWorld.components.timer:TimerExists("twreleasing") then
                    TheWorld.components.timer:SetTimeLeft("twreleasing", time - host.components.timestopper:GetResumingTimer())
                else
                    TheWorld.components.timer:StartTimer("twreleasing", time - host.components.timestopper:GetResumingTimer())
                end
                self.releasingfn = host.components.timestopper:GetOnResumingFn()
            end
        end
        if host.components.timestopper then 
            host.components.timestopper:OnTimeStopped(true)
        end
    end
    if not TheWorld.twlistener then
        TheWorld:ListenForEvent("timerdone", function(inst, data)
            if data.name == "the_world" then
                if TheWorld.twtask ~= nil then
                    TheWorld.twtask:Cancel()
                    TheWorld.twtask = nil
                end
                self:OnResume()
                TheWorld:DoTaskInTime(0.1, function()
                    if TheWorld:HasTag("the_world") then
                        TheWorld:RemoveTag("the_world")
                    end
                end)
            end
            if data.name == "twreleasing" and self.releasingfn then -- TODO
                self.releasingfn(silent)
            end
        end)
        TheWorld.twlistener = true
    end

end

return timestopper_world