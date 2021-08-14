local TimeStopper = Class(function(self, inst)
    self.inst = inst
    self.host = nil
    self.ontimestoppedfn = nil
    self.onresumingtime = 0
    self.onresumingfn = nil
    self.onresumedfn = nil
    self.resumedlistener = self.inst:ListenForEvent("the_world_end", self.onresumedfn, TheWorld)
end,
nil,
{

})

function TimeStopper:GetHost()
    return self.host or self.inst
end

function TimeStopper:SetHost(host)
    self.host = host
end

function TimeStopper:DoTimeStop(time, silent, nogrey)
    TheWorld.components.timestopper_world:DoTimeStop(time, self.inst, silent, nogrey)
    -- if self.host and self.host ~= self.inst then
    --     TheWorld.components.timestopper_world:ResumeEntity(self.inst, time)
    -- end
    -- host:AddTag("stoppingtime")
    -- host:DoTaskInTime(time + 0.1, function()
    --     host:RemoveTag("stoppingtime")
    -- end)
end

-- function TimeStopper:StopTimeFor(time, host, silent, nogrey)
--     TheWorld.components.timestopper_world:DoTimeStop(time, host or self:GetHost(), silent, nogrey)
--     if host and host ~= self.inst then
--         TheWorld.components.timestopper_world:ResumeEntity(self.inst, time)
--     end
--     -- host:AddTag("stoppingtime")
--     -- host:DoTaskInTime(time + 0.1, function()
--     --     host:RemoveTag("stoppingtime")
--     -- end)
-- end

function TimeStopper:SetOnTimeStoppedFn(fn)
    self.ontimestoppedfn = fn
end

function TimeStopper:SetOnResumingFn(time, fn)
    self.onresumingtime = time
    self.onresumingfn = fn
end

function TimeStopper:SetOnResumedFn(fn)
    self.onresumedfn = fn
end

function TimeStopper:OnRemoveFromEntity()
    -- self.inst:RemoveTag("stoppingtime")
	if self.resumedlistener then
		self.resumedlistener:Cancel()
		self.resumedlistener = nil
	end
end

return TimeStopper