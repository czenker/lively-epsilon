Missions = Missions or {}

local function isValid(thing)
    return isEeSupplyDrop(thing) or isEeArtifact(thing)
end

local function validateAndInitPickUps(things)
    if isValid(things) then things = {things} end
    if not isTable(things) then error("things needs to be a table of space objects, but " .. type(things) .. " given", 2) end

    local pickUps = {}

    for _,v in pairs(things) do
        if isValid(v) and v:isValid() then
            pickUps[v] = v
        else
            error("all things need to be artifacts or supply drops, but " .. type(v) .. " given", 2)
        end
    end
    return pickUps
end

local function validateAndInitStation(thing)

end

-- Pick up artifacts or supplyDrops
-- onPickUp
-- onAllPickedUp
Missions.pickUp = function(self, things, deliveryStation, config)
    local cronId = "pick_up_" .. Util.randomUuid()
    local pickUps, station

    -- make deliveryStation optional
    if isTable(deliveryStation) and not isEeObject(deliveryStation) then
        config = deliveryStation
        deliveryStation = nil
    end
    if not isFunction(things) then
        pickUps = validateAndInitPickUps(things)
    end
    if not isFunction(deliveryStation) then
        station = deliveryStation
        if not isNil(station) and not isEeStation(station) then error("expected station to be a station or nil, but got " .. typeInspect(station), 3) end
    end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. type(config) .. " given.", 2) end

    local mission

    local onPickUp = function(self, player)
        if player ~= mission:getPlayer() then
            logWarning("Pick up with the name " .. self:getCallSign() .. " has been picked up by a different player " .. player:getCallSign())
            mission:fail()
        else
            pickUps[self] = nil
            if isFunction(config.onPickUp) then
                config.onPickUp(mission, self)
            end
            if Util.size(pickUps) == 0 then
                if isFunction(config.onAllPickedUp) then
                    config.onAllPickedUp(mission)
                end
                if station == nil then
                    mission:success()
                end
            end
        end
    end

    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(things) then
                pickUps = validateAndInitPickUps(things())
            end
            if isFunction(deliveryStation) then
                station = deliveryStation(self)
                if not isEeStation(station) then error("expected station to be a station, but got " .. typeInspect(station), 2) end
            end

            if isFunction(config.onStart) then config.onStart(self) end

            for _,thing in pairs(pickUps) do
                if isEeArtifact(thing) then
                    thing:allowPickup(true)
                elseif isEeSupplyDrop(thing) then
                    thing:setFactionId(self:getPlayer():getFactionId())
                end
                thing:onPickUp(onPickUp)
            end

            Cron.regular(cronId, function()
                if isEeStation(station) and not station:isValid() then
                    logWarning("Delivery station was destroyed so there is no way to finish the mission. Fail.")
                    mission:fail()
                elseif Util.size(pickUps) == 0 then
                    if station == nil then
                        -- we should never end here, because the callbacks finish the mission, but just in case...
                        mission:success()
                    elseif mission:getPlayer():isDocked(station) then
                        mission:success()
                    end
                else
                    for _,thing in pairs(pickUps) do
                        if not thing:isValid() then
                            logWarning("Pick up is not valid, but has not been picked up by the player. So the mission can not be accomplished. It fails.")
                            self:fail()
                        end
                    end
                end
            end, 0.2)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)
            if isTable(pickUps) then
                for _,thing in pairs(pickUps) do
                    thing:onPickUp(nil)
                end
            end

            if isFunction(config.onEnd) then config.onEnd(self) end
        end,
    })

    Mission:forPlayer(mission)

    mission.getPickUps = function(self)
        if isNil(pickUps) then return nil end

        local ret = {}
        for _, pickUp in pairs(pickUps) do table.insert(ret, pickUp) end
        return ret
    end
    mission.countPickUps = function(self)
        if isNil(pickUps) then
            return nil
        else
            return Util.size(pickUps)
        end
    end
    mission.getDeliveryStation = function(self)
        return station
    end

    return mission
end