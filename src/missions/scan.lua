Missions = Missions or {}

local function validateThings(things)
    if isEeShip(things) then things = {things} end
    if not isTable(things) then error("things needs to be a table of space ships, but " .. type(things) .. " given", 3) end

    for _,v in pairs(things) do
        if not isEeShip(v) then error("all things need to be space ships, but " .. type(v) .. " given", 3) end
    end

    return things
end

local function initThings(things, player, isTargetScannedBy)
    local targets = {}
    local knownValidTargets = {}
    local knownScannedTargets = {}

    for _,v in pairs(things) do
        table.insert(targets, v)
        if v:isValid() then
            knownValidTargets[v] = true
            if isTargetScannedBy(v, player) then
                knownScannedTargets[v] = true
            end
        end
    end
    return targets, knownValidTargets, knownScannedTargets
end

-- Scan stuff
-- onScan
-- onDestruction
Missions.scan = function(self, things, config)
    local cronId = Util.randomUuid()
    local targets
    local knownValidTargets -- this is to keep track which targets where recently destroyed
    local knownScannedTargets

    if not isFunction(things) then
        things = validateThings(things)
    end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. type(config) .. " given.", 2) end
    local isTargetScannedBy = function(target, player) return target:isFriendOrFoeIdentifiedBy(player) end
    if config.scan == "full" then isTargetScannedBy = function(target, player) return target:isFullyScannedBy(player) end end

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(things) then
                things = validateThings(things())
            end
            targets, knownValidTargets, knownScannedTargets = initThings(things, self:getPlayer(), isTargetScannedBy)

            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                for _, target in pairs(targets) do
                    if not target:isValid() then
                        if isFunction(config.onDestruction) and knownValidTargets[target] == true then
                            config.onDestruction(mission, target)
                        end
                        knownValidTargets[target] = nil
                    elseif knownScannedTargets[target] == nil and isTargetScannedBy(target, self:getPlayer()) then
                        if isFunction(config.onScan) then config.onScan(mission, target) end
                        knownScannedTargets[target] = true
                    end
                end
                if mission:countUnscannedTargets() == 0 then
                    if mission:countScannedTargets() > 0 then mission:success() else mission:fail() end
                end
            end, 0.2)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)

            if isFunction(config.onEnd) then config.onEnd(self) end
        end,
    })

    Mission:forPlayer(mission)

    mission.getTargets = function(self)
        if isNil(targets) then return nil end

        local ret = {}
        for _, target in pairs(targets) do table.insert(ret, target) end
        return ret
    end
    mission.countTargets = function(self)
        if isNil(targets) then return nil end
        return Util.size(targets)
    end
    mission.getScannedTargets = function(self)
        if isNil(knownScannedTargets) then return nil end

        local ret = {}
        for target, _ in pairs(knownScannedTargets) do table.insert(ret, target) end
        return ret
    end
    mission.countScannedTargets = function(self)
        if isNil(knownScannedTargets) then return nil end
        return Util.size(knownScannedTargets)
    end
    mission.getUnscannedTargets = function(self)
        if isNil(targets) then return nil end

        local ret = {}
        for _, target in pairs(targets) do if target:isValid() and knownScannedTargets[target] == nil then table.insert(ret, target) end end
        return ret
    end
    mission.countUnscannedTargets = function(self)
        if isNil(targets) then return nil end
        return Util.size(self:getUnscannedTargets())
    end

    return mission
end