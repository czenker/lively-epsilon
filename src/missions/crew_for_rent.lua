Missions = Missions or {}

-- Lend someone part of your repair crew for a limited time
--
-- distance
-- crewCount
-- duration
-- sendCrewLabel
-- sendCrewFailed
-- onCrewArrived
-- onCrewReady
-- returnCrewLabel
-- onCrewReturned
-- onDestruction
Missions.crewForRent = function(self, needy, config)
    if not isEeShipTemplateBased(needy) and not isFunction(needy) then error("Expected needy to be a shipTemplateBased, but got " .. typeInspect(needy), 2) end

    local cronId = Util.randomUuid()
    local buttonId = Util.randomUuid()

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end

    local maxDistance = config.distance or 1000
    local inRange = false
    local sendCrewLabel = config.sendCrewLabel or "Send Crew"
    if not isString(sendCrewLabel) then error("Expected sendCrewLabel to be a string, but got " .. typeInspect(sendCrewLabel), 2) end
    local returnCrewLabel = config.returnCrewLabel or "Return Crew"
    if not isString(returnCrewLabel) then error("Expected returnCrewLabel to be a string, but got " .. typeInspect(returnCrewLabel), 2) end
    local crewCount = config.crewCount or 1
    local duration = config.duration or 60
    local currentRepairCrewCount = 0
    local crewReady = false

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(needy) then
                needy = needy()
                if not isEeShipTemplateBased(needy) then error("Expected needy to be a shipTemplateBased, but got " .. typeInspect(needy), 2) end
            end

            if isFunction(config.onStart) then config.onStart(self) end

            local function failOnDestruction()
                if not needy:isValid() then
                    if isFunction(config.onDestruction) then config.onDestruction(mission) end
                    mission:fail()
                    return true
                end
                return false
            end

            local step1SendCrew
            local step2WaitForCrewReady
            local step3ReturnCrew

            step1SendCrew = function()
                if failOnDestruction() then
                    return
                elseif not inRange and distance(self:getPlayer(), needy) <= maxDistance then
                    self:getPlayer():addCustomButton("engineering", buttonId, sendCrewLabel, function()
                        if self:getPlayer():getRepairCrewCount() >= crewCount then
                            self:getPlayer():setRepairCrewCount(self:getPlayer():getRepairCrewCount() - crewCount)
                            currentRepairCrewCount = crewCount
                            self:getPlayer():removeCustom(buttonId)
                            Cron.once(cronId, step2WaitForCrewReady, duration)
                            if isFunction(config.onCrewArrived) then config.onCrewArrived(mission) end
                        else
                            if isFunction(config.sendCrewFailed) then config.sendCrewFailed(mission) end
                        end
                    end)
                    inRange = true
                elseif inRange and distance(self:getPlayer(), needy) > maxDistance then
                    self:getPlayer():removeCustom(buttonId)
                    inRange = false
                end
            end

            step2WaitForCrewReady = function()
                if failOnDestruction() then
                    return
                else
                    inRange = false
                    crewReady = true
                    Cron.regular(cronId, step3ReturnCrew, 1)
                    if isFunction(config.onCrewReady) then config.onCrewReady(mission) end
                end
            end

            step3ReturnCrew = function()
                if failOnDestruction() then
                    return
                elseif not inRange and distance(self:getPlayer(), needy) <= maxDistance then
                    self:getPlayer():addCustomButton("engineering", buttonId, returnCrewLabel, function()
                        self:getPlayer():setRepairCrewCount(self:getPlayer():getRepairCrewCount() + currentRepairCrewCount)
                        currentRepairCrewCount = 0
                        if isFunction(config.onCrewReturned) then config.onCrewReturned(mission) end
                        self:success()
                    end)
                    inRange = true
                elseif inRange and distance(self:getPlayer(), needy) > maxDistance then
                    self:getPlayer():removeCustom(buttonId)
                    inRange = false
                end
            end

            Cron.regular(cronId, step1SendCrew, 1)
        end,

        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)
            self:getPlayer():removeCustom(buttonId)

            if isFunction(config.onEnd) then config.onEnd(self) end
        end,

    })

    Mission:forPlayer(mission)

    mission.getNeedy = function()
        if isEeShipTemplateBased(needy) then
            return needy
        else
            return nil
        end
    end

    mission.getRepairCrewCount = function()
        return currentRepairCrewCount
    end

    mission.getTimeToReady = function()
        if crewReady == true then return 0
        elseif currentRepairCrewCount > 0 then
            return Cron.getDelay(cronId) or 0
        else
            return nil
        end
    end

    return mission
end