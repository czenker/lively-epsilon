Missions = Missions or {}

-- Destroy something in order to pick up something that you have to drop at some station.
--
-- Think: "Retrieve stolen plans for a super weapon", "Free prisoners", "Capture Mr. Superbaddy", etc.
--
-- approachDistance
-- onApproach
-- onBearerDestruction
-- onItemDestruction
-- onPickup
Missions.capture = function(self, bearer, config)
    if not isEeShipTemplateBased(bearer) and not isFunction(bearer) then error("Expected bearer to be a shipTemplateBased, but got " .. type(bearer), 2) end

    local cronId = Util.randomUuid()

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. type(config) .. " given.", 2) end

    local approachDistance = config.approachDistance or 10000
    local onApproachTriggered = false
    if not isFunction(config.onApproach) then onApproachTriggered = true end

    local wasItemSpawned = false
    local lastLocationX, lastLocationY = 0, 0

    local itemObject

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(bearer) then
                bearer = bearer()
                if not isEeShipTemplateBased(bearer) then error("Expected bearer to be a shipTemplateBased, but got " .. type(bearer), 2) end
            end

            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                if wasItemSpawned == false then
                    if bearer:isValid() then
                        lastLocationX, lastLocationY = bearer:getPosition()
                        if onApproachTriggered == false and distance(bearer, self:getPlayer()) < approachDistance then
                            config.onApproach(self, bearer)
                            onApproachTriggered = true
                        end
                    else
                        if lastLocationX == 0 and lastLocationY == 0 then
                            logError("The bearer object was never valid, so we could not get the position. We will assume 0, 0.")
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
                        wasItemSpawned = true
                        bearer = nil

                        if isFunction(config.onBearerDestruction) then config.onBearerDestruction(self, itemObject) end
                    end
                else
                    if itemObject:isValid() then
                        lastLocationX, lastLocationY = itemObject:getPosition()
                    else
                        if distance(self:getPlayer(), lastLocationX, lastLocationY) < 500 then
                            logInfo("The player was close enough to the destroyed item, so assume it was destroyed by collision and picked up")

                            if isFunction(config.onPickup) then config.onPickup(self) end
                            self:success()
                        else
                            logInfo("The player was too far away from the destroyed item, so assume it was accidentially destroyed")
                            if isFunction(config.onItemDestruction) then config.onItemDestruction(self, lastLocationX, lastLocationY) end
                            self:fail()
                        end
                    end
                end
            end, 0.2)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function()
            Cron.abort(cronId)

            if isFunction(config.onEnd) then config.onEnd(self) end
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

    return mission
end