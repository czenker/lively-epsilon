Missions = Missions or {}

-- Destroy something in order to pick up something that you have to drop at some station.
--
-- Think: "Retrieve plans for a super weapon", "Free prisoners", "Capture Mr. Superbaddy", etc.
--
-- approachDistance
-- onApproach
-- onBearerDestruction
-- onItemDestruction
-- onPickup
-- dropOffTarget
-- onDropOff
-- onDropOffTargetDestroyed
Missions.capture = function(self, bearer, config)
    if not isEeShipTemplateBased(bearer) and not isFunction(bearer) then error("Expected bearer to be a shipTemplateBased, but got " .. typeInspect(bearer), 2) end

    local cronId = Util.randomUuid()

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end

    local approachDistance = config.approachDistance or 10000
    local onApproachTriggered = false
    if not isFunction(config.onApproach) then onApproachTriggered = true end

    local lastLocationX, lastLocationY

    local itemObject
    local dropOffTarget = config.dropOffTarget
    if not isNil(dropOffTarget) and not isEeStation(dropOffTarget) then error("Expected dropOffTarget to be a station, but got " .. typeInspect(dropOffTarget), 2) end

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(bearer) then
                bearer = bearer()
                if not isEeShipTemplateBased(bearer) then error("Expected bearer to be a shipTemplateBased, but got " .. typeInspect(bearer), 2) end
            end

            if isFunction(config.onStart) then config.onStart(self) end

            local step1DestroyBearer
            local step2CollectItem
            local step3DropOff

            step1DestroyBearer = function()
                if bearer:isValid() then
                    lastLocationX, lastLocationY = bearer:getPosition()
                    if onApproachTriggered == false and distance(bearer, self:getPlayer()) < approachDistance then
                        config.onApproach(self, bearer)
                        onApproachTriggered = true
                    end
                else
                    if lastLocationX == nil and lastLocationY == nil then
                        logError("The bearer object was never valid, so we could not get the position. We will assume 0, 0.")
                        lastLocationX, lastLocationY = 0, 0
                    end
                    if isFunction(config.onBearerDestruction) then
                        itemObject = config.onBearerDestruction(self, lastLocationX, lastLocationY)
                        if not isNil(itemObject) and not isEeObject(itemObject) then
                            logWarning("The onBearerDestruction callback did not return a valid space object, so the return value will be discarded")
                            itemObject = nil
                        end
                    end
                    if itemObject == nil then
                        itemObject = Artifact():setModel("ammo_box"):allowPickup(true):setPosition(lastLocationX, lastLocationY)
                    end
                    Cron.regular(cronId, step2CollectItem, 0.2)
                    bearer = nil
                end
            end

            step2CollectItem = function()
                if itemObject:isValid() then
                    lastLocationX, lastLocationY = itemObject:getPosition()
                else
                    if distance(self:getPlayer(), lastLocationX, lastLocationY) < 500 then
                        logInfo("The player was close enough to the destroyed item, so assume it was destroyed by collision and picked up")

                        if isFunction(config.onPickup) then config.onPickup(self) end

                        Cron.regular(cronId, step3DropOff, 1)
                        if not isEeStation(dropOffTarget) then self:success() end
                    else
                        logInfo("The player was too far away from the destroyed item, so assume it was accidentially destroyed")
                        if isFunction(config.onItemDestruction) then config.onItemDestruction(self, lastLocationX, lastLocationY) end
                        self:fail()
                    end
                end
            end

            step3DropOff = function()
                if not dropOffTarget:isValid() then
                    if isFunction(config.onDropOffTargetDestroyed) then config.onDropOffTargetDestroyed(self) end
                    self:fail()
                elseif self:getPlayer():isDocked(dropOffTarget) then
                    if isFunction(config.onDropOff) then config.onDropOff(self) end
                    self:success()
                end
            end

            Cron.regular(cronId, step1DestroyBearer, 0.2)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)

            if isFunction(config.onEnd) then config.onEnd() end
        end,
    })

    Mission:forPlayer(mission)

    -- @return nil|ShipTemplateBased
    mission.getBearer = function(self)
        if isEeShipTemplateBased(bearer) then return bearer else return nil end
    end

    -- @return nil|SpaceObject
    mission.getItemObject = function(self)
        if isEeObject(itemObject) then return itemObject else return nil end
    end

    -- @return nil|SpaceStation
    mission.getDropOffTarget = function(self)
        if isEeStation(dropOffTarget) then return dropOffTarget else return nil end
    end

    return mission
end