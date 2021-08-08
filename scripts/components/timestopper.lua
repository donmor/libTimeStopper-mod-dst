local TimeStopper = Class(function(self, inst)
    self.inst = inst
    self.ontimestoppedfn = nil
    self.onresumingtime = 0
    self.onresumingfn = nil
    self.onresumedfn = nil
    self.stoppingtime = false
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

function TimeStopper:DoTimeStop(time, silent)
    TheWorld.components.timestopper_world:DoTimeStop(gethost(self.inst), time, silent)
    self.stoppingtime = true
    gethost(self.inst):DoTaskInTime(time + 0.1, function()
        self.stoppingtime = false
    end)
end

function TimeStopper:IsStoppingTime()
    return self.stoppingtime
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

function TimeStopper:GetOnResumingFn()
    return self.onresumingfn
end


function TimeStopper:OnTimeStopped(silent)
    if self.ontimestoppedfn then
        self.ontimestoppedfn(silent)
    end
end

function TimeStopper:OnResumed(silent)
    if self.onresumedfn then
        self.onresumedfn(silent)
    end
end

function TimeStopper:GetResumingTimer()
    return self.onresumingtime
end

return TimeStopper