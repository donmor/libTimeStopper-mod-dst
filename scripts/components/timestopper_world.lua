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
    -- print(ent.prefab == "boat")
    -- if ent.prefab == "boat" then
    --     print("B", ent.Physics, ent.components.boatphysics)
    -- end
    if ent.Physics then
        local mass = ent.Physics:GetMass()
        if ent.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
            -- Ignore OBSTACLES
            if ent.components.boatphysics then
            -- print("OBSTACLES")
            --     print("BOAT")
                -- ent.vmass = mass
                ent.Physics:SetMotorVel(0, 0, 0)
                -- ent.Physics:SetMass(0)
                -- ent.Physics:SetActive(false)
            end
        elseif mass ~= 0 or ent.Physics:GetMotorVel() ~= 0 then --质量为0, 但不是障碍物, 如海浪
            ent.vmass = mass
            if isproj then
                local ospeed = projcomp.origspeed
                -- ent.projspeedtask = ent:DoPeriodicTask(90/4/30/30, function()
                --     projcomp.speed = projcomp.speed - 6
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
                -- if projcomp.speed >= projcomp.origspeed then
                --     projcomp.speed = projcomp.origspeed / 4
                --     ent.Physics:SetMotorVel(projcomp.speed, 0, 0)
                --     ent:DoTaskInTime((180 + math.random(0, 60)) * FRAMES / projcomp.origspeed, function()
                --         projcomp.speed = 0
                --         ent.Physics:SetMotorVel(projcomp.speed, 0, 0)
                --         if ent.AnimState then
                --             ent.AnimState:Pause()
                --         end
                --     end)
                -- end                
            else
                ent.Physics:SetMass(0)
                ent.Physics:SetActive(false)
                -- if ent.components.boatphysics then
                -- print("NONPROJ")
                --     print("BOAT")
                --     ent.Physics:SetMotorVel(0, 0, 0)
                -- end
            end
        end
    end
    if TheWorld.ismastersim then
        ent:StopBrain()
        if ent.sg then
            ent.sg:Stop()
        end
        -- if ent.components.combat then
        --     ent.components.combat:SetTarget(nil)
        -- end
        if ent.components.locomotor then
            ent.components.locomotor:StopUpdatingInternal()
        end
        if ent.components.propagator then
            ent.components.propagator:StopUpdating()
        end
        -- if ent.components.perishable and not ent:HasTag("small_livestock") and ent.prefab ~= "wobster_sheller_land" then
        --     ent.components.perishable:StopPerishing()
        -- end
        if ent.components.playercontroller then
            ent.components.playercontroller:Enable(false)
        end
        -- if TUNING.TIMESTOPPER_INVINCIBLE_FOE and ent.components.health then
        --     ent.components.health:SetInvincible(true)
        -- end
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
        -- if ent.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
            -- Ignore OBSTACLES            
            -- if ent.components.boatphysics then
                -- if ent.vmass then
                --     ent.Physics:SetMass(ent.vmass)
                -- end
                -- ent.Physics:SetActive(true)
            -- end
        if ent.Physics:GetCollisionGroup() != COLLISION.OBSTACLES and ent.vmass ~= 0 or ent.Physics:GetMotorVel() ~= 0 then
        -- elseif ent.vmass ~= 0 or ent.Physics:GetMotorVel() ~= 0 then
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
        -- if ent.components.perishable and not ent:HasTag("small_livestock") and ent.prefab ~= "wobster_sheller_land" then
        --     ent.components.perishable:StartPerishing()
        -- end
        if ent.components.playercontroller then
            ent.components.playercontroller:Enable(true)
        end
        if ent.components.health then
            ent.components.health:UpdateStatus()
        end
        -- if TUNING.TIMESTOPPER_INVINCIBLE_FOE then
        --     ent.components.health:SetInvincible(false)
        -- end
    end
    if ent:HasTag("time_stopped") then
        ent:RemoveTag("time_stopped")
    end
end

function TimeStopper_World:OnPeriod()
    for k, v in pairs(AllPlayers) do
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
                -- local projcomp = v.components.projectile
                -- local isproj = projcomp and projcomp:IsThrown()
                -- if v.AnimState and not isproj then
                --     v.AnimState:Pause()
                -- end
                -- if v.Physics then
                --     local mass = v.Physics:GetMass()
                --     if v.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
                --         -- Ignore OBSTACLES
                --     elseif mass ~= 0 or v.Physics:GetMotorVel() ~= 0 then --质量为0, 但不是障碍物, 如海浪
                --         v.vmass = mass
                --         if isproj then
                --             local ospeed = projcomp.origspeed
                --             -- v.projspeedtask = v:DoPeriodicTask(90/4/30/30, function()
                --             --     projcomp.speed = projcomp.speed - 6
                --             local mult = math.random(90, 120) / 100
                --             if v.projspeedtask then
                --                 v.projspeedtask:Cancel()
                --                 v.projspeedtask = nil
                --             end
                --             local function projspeedfn()
                --                 projcomp.speed = projcomp.speed - mult * ospeed / 3
                --                 if projcomp.speed < 0 or projcomp.target and projcomp.hitdist + projcomp.target:GetPhysicsRadius(0) >= getdist(v, projcomp.target) then   -- TODO: TESTING
                --                     projcomp.speed = 0
                --                 end
                --                 v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                --                 if projcomp.speed == 0 and v.projspeedtask then
                --                     v.projspeedtask:Cancel()
                --                     v.projspeedtask = nil
                --                     if v.AnimState then
                --                         v.AnimState:Pause()
                --                     end
                --                     v.Physics:SetMass(0)
                --                 end
                --             end
                --             v.projspeedtask = v:DoPeriodicTask(1 / ospeed, projspeedfn)
                --             projspeedfn()
                --             -- if projcomp.speed >= projcomp.origspeed then
                --             --     projcomp.speed = projcomp.origspeed / 4
                --             --     v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                --             --     v:DoTaskInTime((180 + math.random(0, 60)) * FRAMES / projcomp.origspeed, function()
                --             --         projcomp.speed = 0
                --             --         v.Physics:SetMotorVel(projcomp.speed, 0, 0)
                --             --         if v.AnimState then
                --             --             v.AnimState:Pause()
                --             --         end
                --             --     end)
                --             -- end                
                --         else
                --             v.Physics:SetMass(0)
                --             v.Physics:SetActive(false)
                --         end
                --     end
                -- end
                -- if TheWorld.ismastersim then
                --     v:StopBrain()
                --     if v.sg then
                --         v.sg:Stop()
                --     end
                --     if v.components.combat then
                --         v.components.combat:SetTarget(nil)
                --     end
                --     if v.components.locomotor then
                --         v.components.locomotor:StopUpdatingInternal()
                --     end
                --     if v.components.playercontroller then
                --         v.components.playercontroller:Enable(false)
                --     end
                --     if TUNING.TIMESTOPPER_INVINCIBLE_FOE and v.components.health then
                --         v.components.health:SetInvincible(true)
                --     end
                -- end
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
            -- local projcomp = v.components.projectile
            -- local isproj = projcomp and projcomp:IsThrown()
            -- if v.AnimState then
            --     v.AnimState:Resume()
            -- end
            -- if v.Physics then
            --     if v.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
            --         -- Ignore OBSTACLES            
            --     elseif v.vmass ~= 0 or v.Physics:GetMotorVel() ~= 0 then
            --         if v.vmass then
            --             v.Physics:SetMass(v.vmass)
            --         end
            --         if isproj then
            --             local ospeed = projcomp.origspeed
            --             local mult = math.random(90, 120) / 100
            --             if v.projspeedtask then
            --                 v.projspeedtask:Cancel()
            --                 v.projspeedtask = nil
            --             end
            --             v.projspeedtask = v:DoPeriodicTask(1 / ospeed, function()
            --                 projcomp.speed = projcomp.speed + mult * ospeed / 3
            --                 if projcomp.speed > ospeed then
            --                     projcomp.speed = ospeed
            --                 end
            --                 v.Physics:SetMotorVel(projcomp.speed, 0, 0)
            --                 if projcomp.speed == ospeed and v.projspeedtask then
            --                     v.projspeedtask:Cancel()
            --                     v.projspeedtask = nil
            --                 end
            --             end)
            --         -- if projcomp.speed < projcomp.origspeed / 4 then
            --             --     projcomp.speed = projcomp.origspeed / 4 + 1
            --             --     v.Physics:SetMotorVel(projcomp.origspeed / 4 + 1, 0, 0)
            --             --     v:DoTaskInTime((180 + math.random(0, 60)) * FRAMES / projcomp.origspeed, function()
            --             --         projcomp.speed = projcomp.origspeed
            --             --         v.Physics:SetMotorVel(projcomp.speed, 0, 0)
            --             --     end)
            --             -- end
            --         else
            --             v.Physics:SetActive(true)
            --         end
            --     end
            -- end
            -- if TheWorld.ismastersim then
            --     v:RestartBrain()
            --     if v.sg then
            --         v.sg:Start()
            --     end
            --     if v.components.locomotor then
            --         v.components.locomotor:StartUpdatingInternal()
            --     end
            --     if v.components.playercontroller then
            --         v.components.playercontroller:Enable(true)
            --     end
            --     if TUNING.TIMESTOPPER_INVINCIBLE_FOE then
            --         v.components.health:SetInvincible(false)
            --     end
            -- end
            resume(v)
            -- if v:HasTag("time_stopped") then
            --     v:RemoveTag("time_stopped")
            -- end
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
            -- host:DoTaskInTime(time + 0.1, function()
            --     host:RemoveTag("stoppingtime")
            -- end)
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
    -- if grandhost and grandhost:IsValid() then
    --     grandhost:AddTag("stoppingtime")
    --     -- host:DoTaskInTime(time + 0.1, function()
    --     --     host:RemoveTag("stoppingtime")
    --     -- end)
    --     if not grandhost.components.timer:TimerExists("stoppingtime") then
    --         grandhost.components.timer:StartTimer("stoppingtime", time + 0.1)
    --     elseif grandhost.components.timer:GetTimeLeft("stoppingtime") < time then
    --         grandhost.components.timer:SetTimeLeft("stoppingtime", time + 0.1)
    --     end    
    --     self:ResumeEntity(grandhost, time)
    -- end
    -- host:AddTag("canmoveintime")
    -- if not host.components.timer:TimerExists("canmoveintime") then
    --     host.components.timer:StartTimer("canmoveintime", time + 0.1)
    -- else
    --     host.components.timer:SetTimeLeft("canmoveintime", time + 0.1)
    -- end
    -- if host.AnimState then
    --     host.AnimState:Resume()
    -- end
    -- if host.components.locomotor then
    --     host.components.locomotor:StartUpdatingInternal()
    -- end
    -- if host.components.playercontroller then
    --     host.components.playercontroller:Enable(true)
    -- end
    -- if host:HasTag("time_stopped") then
    --     host:RemoveTag("time_stopped")
    -- end
    -- if host.components.ghostlybond then
    --     local ghost = host.components.ghostlybond.ghost
    --     if not ghost.components.timer then
    --         ghost:AddComponent("timer")
    --     end
    --     if not ghost.components.timer:TimerExists("canmoveintime") then
    --         ghost.components.timer:StartTimer("canmoveintime", time + 0.1)
    --     else
    --         ghost.components.timer:SetTimeLeft("canmoveintime", time + 0.1)
    --     end
    --     if ghost.AnimState then
    --         ghost.AnimState:Resume()
    --     end
    --     if ghost.components.locomotor then
    --         ghost.components.locomotor:StartUpdatingInternal()
    --     end
    --     if ghost:HasTag("time_stopped") then
    --         ghost:RemoveTag("time_stopped")
    --     end
    -- end
    if not TheWorld:HasTag("the_world") then
        TheWorld.twtask = TheWorld:DoPeriodicTask(0.1, function() self:OnPeriod() end)
        for k, v in pairs(AllPlayers) do
            v.instoppedtime:set(nogrey and -math.abs(time) or math.abs(time))
            -- if TUNING.TIMESTOPPER_GREYSCREEN and not nogrey then
            --     v:PushEvent("")
            -- end
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
    -- TheSim:SetTimeScale(0)
        TheWorld.net.components.clock:Stop()
        TheWorld:AddTag("the_world")
        TheWorld:PushEvent("the_world")
        -- if TUNING.TIMESTOPPER_GREYSCREEN and not nogrey then
        --     if time < 1 then
        --          TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/ghost_cc.tex")
        --     else
        --         TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/mole_vision_on_cc.tex")
        --         TheWorld:DoTaskInTime(0.5, function()
        --             TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/ghost_cc.tex")
        --         end)
        --     end
        -- end
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
    -- if host and host.components.timestopper and host.components.timestopper.ontimestoppedfn then 
    --     host.components.timestopper.ontimestoppedfn(true)
    -- end
    if not TheWorld.twlistener then
        TheWorld.twlistener = TheWorld:ListenForEvent("timerdone", function(inst, data)
            if data.name == "the_world" then
                self:BreakTimeStop()
                -- if TheWorld.twtask ~= nil then
                --     TheWorld.twtask:Cancel()
                --     TheWorld.twtask = nil
                -- end
                -- self:OnResume()
                -- -- for k, v in pairs(AllPlayers) do
                -- --     if v.components.timestopper and v.components.timestopper.onresumedfn then 
                -- --         v.components.timestopper.onresumedfn(silent)
                -- --     end
                -- -- end
                -- -- TheSim:SetTimeScale(1)
                -- TheWorld.net.components.clock:Resume()
                -- TheWorld:DoTaskInTime(0.1, function()
                --     if TheWorld:HasTag("the_world") then
                --         TheWorld:RemoveTag("the_world")
                --     end
                -- end)
                -- TheWorld:PushEvent("the_world_end", {silent = silent})
            end
            if data.name == "twreleasing" and self.releasingfn then
                self.releasingfn()
                self.releasingfn = nil
            end
        end)
        -- TheWorld.twlistener = true
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
    -- local projcomp = ent.components.projectile
    -- local isproj = projcomp and projcomp:IsThrown()
    -- if ent.AnimState then
    --     ent.AnimState:Resume()
    -- end
    -- if ent.Physics then
    --     if ent.Physics:GetCollisionGroup() == COLLISION.OBSTACLES then
    --         -- Ignore OBSTACLES            
    --     elseif ent.vmass ~= 0 or ent.Physics:GetMotorVel() ~= 0 then
    --         if ent.vmass then
    --             ent.Physics:SetMass(ent.vmass)
    --         end
    --         if isproj then
    --             local ospeed = projcomp.origspeed
    --             local mult = math.random(90, 120) / 100
    --             if ent.projspeedtask then
    --                 ent.projspeedtask:Cancel()
    --                 ent.projspeedtask = nil
    --             end
    --             ent.projspeedtask = ent:DoPeriodicTask(1 / ospeed, function()
    --                 projcomp.speed = projcomp.speed + mult * ospeed / 3
    --                 if projcomp.speed > ospeed then
    --                     projcomp.speed = ospeed
    --                 end
    --                 ent.Physics:SetMotorVel(projcomp.speed, 0, 0)
    --                 if projcomp.speed == ospeed and ent.projspeedtask then
    --                     ent.projspeedtask:Cancel()
    --                     ent.projspeedtask = nil
    --                 end
    --             end)
    --         else
    --             ent.Physics:SetActive(true)
    --         end
    --     end
    -- end
    -- if TheWorld.ismastersim then
    --     ent:RestartBrain()
    --     if ent.sg then
    --         ent.sg:Start()
    --     end
    --     if ent.components.locomotor then
    --         ent.components.locomotor:StartUpdatingInternal()
    --     end
    --     if ent.components.playercontroller then
    --         ent.components.playercontroller:Enable(true)
    --     end
    --     if ent:HasTag("time_stopped") then
    --         ent:RemoveTag("time_stopped")
    --     end
    --     if TUNING.TIMESTOPPER_INVINCIBLE_FOE then
    --         ent.components.health:SetInvincible(false)
    --     end
    -- end
    if ent.components.ghostlybond and not ent.components.ghostlybond.notsummoned and ent.components.ghostlybond.ghost and ent.components.ghostlybond.ghost:IsValid() then
        -- local ghost = ent.components.ghostlybond.ghost
        -- if not ghost.components.timer then
        --     ghost:AddComponent("timer")
        -- end
        self:ResumeEntity(ent.components.ghostlybond.ghost, time)
    end
end

function TimeStopper_World:BreakTimeStop()
    if TheWorld.components.timer:TimerExists("twreleasing") then
        TheWorld.components.timer:StopTimer("twreleasing")
    end
    if TheWorld.components.timer:TimerExists("the_world") then
        TheWorld.components.timer:StopTimer("the_world")
        -- TheWorld.components.timer:SetTimeLeft("the_world", FRAMES)
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