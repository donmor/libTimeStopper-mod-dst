local timestopper = Class(function(self, inst)
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

function timestopper:DoTimeStop(time)
    TheWorld.components.timestopper_world:DoTimeStop(gethost(self.inst), time)
    self.stoppingtime = true
    gethost(self.inst):DoTaskInTime(time + 0.1, function()
        self.stoppingtime = false
    end)
end

function timestopper:IsStoppingTime()
    return self.stoppingtime
end

function timestopper:SetOnTimeStoppedFn(fn) -- = function(silent)
    self.ontimestoppedfn = fn
end

function timestopper:SetOnResumingFn(time, fn) -- = function(silent)
    self.onresumingtime = time
    self.onresumingfn = fn
end

function timestopper:SetOnResumedFn(fn) -- = function(silent)
    self.onresumedfn = fn
end

function timestopper:GetOnResumingFn() -- = function(silent)
    return self.onresumingfn
end


function timestopper:OnTimeStopped(silent)
    if self.ontimestoppedfn then
        self.ontimestoppedfn(silent)
    end
end

function timestopper:OnResumed(silent)
    if self.onresumedfn then
        self.onresumedfn(silent)
    end
end

function timestopper:GetResumingTimer()
    return self.onresumingtime
end

return timestopper