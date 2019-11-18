Mission = Mission or {}

--- A mission container where all submissions have to be finished successfully
--- @param self
--- @param ... Mission
--- @param config table
---   @field acceptCondition function gets `self` as arguments. should return `true` or `false` whether the mission can be accepted
---   @field onAccept function gets `self` as argument
---   @field onDecline function gets `self` as argument
---   @field onStart function gets `self` as argument
---   @field onSuccess function gets `self` as argument
---   @field onFailure function gets `self` as argument
---   @field onEnd function gets `self` as argument
Mission.allOf = function(self, ...)
    local config = nil
    local subMissions = {}

    for _, arg in pairs({...}) do
        if Mission:isMission(arg) then
            if Mission:isSubMission(arg) then error("Submissions can not be part of other mission containers, but " .. arg:getId() " is already part of " .. arg:getParentMission():getId() .. ".", 2) end
            if arg:getState() ~= "new" then error("Expected all missions for allOf, to be new, but " .. arg:getId() .. " is " .. arg:getState(), 2) end
            table.insert(subMissions, arg)
        elseif isTable(arg) then
            if not isNil(config) then
                error("Already got a config " .. typeInspect(config) .. ". Invalid argument " .. typeInspect(arg), 4)
            end
            config = arg
        else
            error("Invalid mission. Expected mission or config, but got " .. typeInspect(arg), 3)
        end
    end

    config = config or {}

    if not subMissions[1] then error("Expected at least one submission, but got 0", 2) end
    local mission = Mission:new(config)

    local unfinishedMissionCount = Util.size(subMissions)

    for _, subMission in pairs(subMissions) do
        subMission.getParentMission = function() return mission end
        subMission:addSuccessListener(function()
            unfinishedMissionCount = unfinishedMissionCount - 1
            if unfinishedMissionCount == 0 and mission:getState() == "started" then
                mission:success()
            end
        end)
        subMission:addFailureListener(function()
            if mission:getState() == "started" then
                mission:fail()
            end
        end)
    end

    local parentAccept = mission.accept
    mission.accept = function(self)
        parentAccept(self)
        for _, subMission in pairs(subMissions) do
            if subMission:getState() == "new" then subMission:accept() end
        end
    end

    local parentStart = mission.start
    mission.start = function(self)
        parentStart(self)
        for _, subMission in pairs(subMissions) do
            if subMission:getState() == "accepted" then subMission:start() end
        end
    end

    local parentSuccess = mission.success
    mission.success = function(self)
        parentSuccess(self)
        for _, subMission in pairs(subMissions) do
            if subMission:getState() == "started" then subMission:success() end
        end
    end

    local parentFail = mission.fail
    mission.fail = function(self)
        parentFail(self)
        for _, subMission in pairs(subMissions) do
            if subMission:getState() == "started" then subMission:fail() end
        end
    end

    return mission
end