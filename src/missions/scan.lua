Missions = Missions or {}

local function validate(thing)
    return isEeObject(thing) and isFunction(thing.isScannedBy)
end

local function validateThings(things, scanLevel)
    if validate(things) then things = {things} end
    if not isTable(things) then error("things needs to be a table of space objects, but " .. typeInspect(things) .. " given", 3) end

    for _,v in pairs(things) do
        if not validate(v) then error("all things need to be spaceObjects, but " .. typeInspect(v) .. " given", 3) end
        if scanLevel ~= "simple" and not isEeShip(v) then error("ScanLevel \"" .. scanLevel .. "\" only works with spaceShips, but " .. typeInspect(v) .. " given.", 3) end
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

--- The players have to scan some ``SpaceShip``s or other ``SpaceObjects``. The mission is successful when all valid targets are scanned.
--- It fails only if **all** targets are destroyed.
---
--- @param self
--- @param things function|table[CpuShip]|CpuShip a CpuShip, a table of ``CpuShip``s or a function returning a table of ``CpuShip``s
--- @param config table
---   @field scan string (default: `simple`) the required scan level (`fof`, `simple` or `full`)
---   @field onScan function function(mission,thing)
---   @field onDestruction function function(mission,thing)
--- @return Mission
Missions.scan = function(self, things, config)
    local cronId = Util.randomUuid()
    local targets
    local knownValidTargets -- this is to keep track which targets where recently destroyed
    local knownScannedTargets

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end
    config.scan = config.scan or "simple"
    if config.scan ~= "fof" and config.scan ~= "simple" and config.scan ~= "full" then error("Expected a valid identifier for config.scan, but got " .. typeInspect(config.scan), 2) end

    local isTargetScannedBy = function(target, player) return target:isScannedBy(player) end
    if config.scan == "fof" then isTargetScannedBy = function(target, player) return target:isFriendOrFoeIdentifiedBy(player) end end
    if config.scan == "full" then isTargetScannedBy = function(target, player) return target:isFullyScannedBy(player) end end

    if not isFunction(things) then
        things = validateThings(things, config.scan)
    end

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(things) then
                things = validateThings(things(), config.scan)
            end
            targets, knownValidTargets, knownScannedTargets = initThings(things, self:getPlayer(), isTargetScannedBy)

            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                for _, target in pairs(targets) do
                    if not target:isValid() and knownValidTargets[target] == true then
                        knownValidTargets[target] = nil
                        if isFunction(config.onDestruction) then
                            config.onDestruction(mission, target)
                        end
                    elseif knownScannedTargets[target] == nil and isTargetScannedBy(target, self:getPlayer()) then
                        knownScannedTargets[target] = true
                        if isFunction(config.onScan) then config.onScan(mission, target) end
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

    ---@param self
    --- @return table[CpuShip]
    mission.getTargets = function(self)
        if isNil(targets) then return nil end

        local ret = {}
        for _, target in pairs(targets) do table.insert(ret, target) end
        return ret
    end
    ---@param self
    --- @return number
    mission.countTargets = function(self)
        if isNil(targets) then return nil end
        return Util.size(targets)
    end
    ---@param self
    --- @return table[CpuShip]
    mission.getScannedTargets = function(self)
        if isNil(knownScannedTargets) then return nil end

        local ret = {}
        for target, _ in pairs(knownScannedTargets) do table.insert(ret, target) end
        return ret
    end
    ---@param self
    --- @return number
    mission.countScannedTargets = function(self)
        if isNil(knownScannedTargets) then return nil end
        return Util.size(knownScannedTargets)
    end
    ---@param self
    --- @return table[CpuShip]
    mission.getUnscannedTargets = function(self)
        if isNil(targets) then return nil end

        local ret = {}
        for _, target in pairs(targets) do if target:isValid() and knownScannedTargets[target] == nil then table.insert(ret, target) end end
        return ret
    end
    ---@param self
    --- @return number
    mission.countUnscannedTargets = function(self)
        if isNil(targets) then return nil end
        return Util.size(self:getUnscannedTargets())
    end

    return mission
end