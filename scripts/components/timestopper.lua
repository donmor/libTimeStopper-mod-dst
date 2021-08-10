local TimeStopper = Class(function(self, inst)
    self.inst = inst
    self.ontimestoppedfn = nil
    self.onresumingtime = 0
    self.onresumingfn = nil
    self.onresumedfn = nil
end,
nil,
{

})

local function gethost(inst)
    if inst.components.inventoryitem then
        return inst.components.inventoryitem:GetGrandOwner()
    else
        return inst
    end
end

function TimeStopper:DoTimeStop(time, silent, nogrey)
    local host = gethost(self.inst)
    TheWorld.components.timestopper_world:DoTimeStop(host, time, silent, nogrey)
    -- host:AddTag("stoppingtime")
    -- host:DoTaskInTime(time + 0.1, function()
    --     host:RemoveTag("stoppingtime")
    -- end)
end

function TimeStopper:StopTimeFor(host, time, silent, nogrey)
    TheWorld.components.timestopper_world:DoTimeStop(host, time, silent, nogrey)
    TheWorld.components.timestopper_world:ResumeEntity(self.inst, time)
    -- host:AddTag("stoppingtime")
    -- host:DoTaskInTime(time + 0.1, function()
    --     host:RemoveTag("stoppingtime")
    -- end)
end

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

-- function TimeStopper:OnRemoveFromEntity()
--     self.inst:RemoveTag("stoppingtime")
-- end

return TimeStopper