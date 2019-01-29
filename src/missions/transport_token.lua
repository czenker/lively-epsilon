Missions = Missions or {}

-- Bring something or someone from one station to another
-- This does not fill any storage on the ship.

-- config:
--   * onLoad
--   * onUnload
Missions.transportToken = function(self, from, to, config)
    if not isEeStation(from) then error("from needs to be a Station, but got " .. typeInspect(from), 2) end
    if not isEeStation(to) then error("to needs to be a Station, but got " .. typeInspect(to), 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end

    local isLoaded = false
    local cronId = Util.randomUuid()

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                if isLoaded == false and mission:getPlayer():isDocked(from) then
                    if isFunction(config.onLoad) then config.onLoad(mission) end
                    isLoaded = true
                end
                if isLoaded == true and mission:getPlayer():isDocked(to) then
                    if isFunction(config.onUnload) then config.onUnload(mission) end
                    isLoaded = false
                    self:success()
                end
            end, 0.5)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)

            if isFunction(config.onEnd) then config.onEnd(self) end
        end,
    })
    Mission:forPlayer(mission)

    mission.isTokenLoaded = function(self) return isLoaded end

    return mission
end