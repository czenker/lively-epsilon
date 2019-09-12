Missions = Missions or {}

--- Lend someone part of your repair crew for a limited time
---
--- @param self
--- @param needy ShipTemplateBased
--- @param config table
---   @field distance number (default: `1000`) range to beam the crew
---   @field crewCount number (default: `1`)
---   @field duration number (default: `60`) how long the crew is occupied
---   @field sendCrewLabel string
---   @field sendCrewFailed function
---   @field onCrewArrived function
---   @field onCrewReady function
---   @field returnCrewLabel string
---   @field onCrewReturned function
---   @field onDestruction function
--- @return Mission
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
        onAccept = function(self)
            if not Player:hasMenu(self:getPlayer()) then error("Expected player for crew_for_rent mission to have Player:withMenu(), but they don't.") end
            if isFunction(config.onAccept) then config.onAccept(self) end
        end,
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
                    self:getPlayer():addEngineeringMenuItem(buttonId, Menu:newItem(sendCrewLabel, function()
                        if self:getPlayer():getRepairCrewCount() >= crewCount then
                            self:getPlayer():setRepairCrewCount(self:getPlayer():getRepairCrewCount() - crewCount)
                            currentRepairCrewCount = crewCount
                            self:getPlayer():removeEngineeringMenuItem(buttonId)
                            Cron.once(cronId, step2WaitForCrewReady, duration)
                            if isFunction(config.onCrewArrived) then config.onCrewArrived(mission) end
                        else
                            if isFunction(config.sendCrewFailed) then config.sendCrewFailed(mission) end
                        end
                    end))
                    inRange = true
                elseif inRange and distance(self:getPlayer(), needy) > maxDistance then
                    self:getPlayer():removeEngineeringMenuItem(buttonId)
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
                    self:getPlayer():addEngineeringMenuItem(buttonId, Menu:newItem(returnCrewLabel, function()
                        self:getPlayer():setRepairCrewCount(self:getPlayer():getRepairCrewCount() + currentRepairCrewCount)
                        currentRepairCrewCount = 0
                        if isFunction(config.onCrewReturned) then config.onCrewReturned(mission) end
                        self:success()
                    end))
                    inRange = true
                elseif inRange and distance(self:getPlayer(), needy) > maxDistance then
                    self:getPlayer():removeEngineeringMenuItem(buttonId)
                    inRange = false
                end
            end

            Cron.regular(cronId, step1SendCrew, 1)
        end,

        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)
            self:getPlayer():removeEngineeringMenuItem(buttonId)

            if isFunction(config.onEnd) then config.onEnd(self) end
        end,

    })

    Mission:forPlayer(mission)

    --- @param self
    --- @return ShipTemplateBased
    mission.getNeedy = function(self)
        if isEeShipTemplateBased(needy) then
            return needy
        else
            return nil
        end
    end

    --- the number of crew members currently away
    --- @param self
    --- @return number
    mission.getRepairCrewCount = function(self)
        return currentRepairCrewCount
    end

    --- the time it still takes before the crew returns
    --- @param self
    --- @return number|nil
    mission.getTimeToReady = function(self)
        if crewReady == true then return 0
        elseif currentRepairCrewCount > 0 then
            return Cron.getDelay(cronId) or 0
        else
            return nil
        end
    end

    return mission
end