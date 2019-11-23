Missions = Missions or {}

local function isValid(thing)
    return isEeShipTemplateBased(thing) or isEeWarpJammer(thing) or isEeScanProbe(thing)
end

local function validateAndInitEnemies(things)
    if isValid(things) then things = {things} end
    if not isTable(things) then error("things needs to be a table of space objects, but " .. typeInspect(things) .. " given", 2) end

    local enemies = {}
    local knownValidEnemies = {}

    for _,v in pairs(things) do
        if isValid(v) then
            table.insert(enemies, v)
            if v:isValid() then
                knownValidEnemies[v] = true
            end
        else
            error("all things need to be space objects, but " .. typeInspect(v) .. " given", 2)
        end
    end
    return enemies, knownValidEnemies
end

--- Destroy stuff - pretty simple, huh?
---
--- @param self
--- @param things ShipTemplateBased|WarpJammer|ScanProbe|table[ShipTemplateBased|WarpJammer|ScanProbe]|function what to destroy
--- @param config table
---   @field approachDistance number (default: `10000`)
---   @field onApproach function(mission,closestEnemy) called when the player first approach one of the enemies
---   @field onDestruction function(mission,enemy) called when an enemy was destroyed
Missions.destroy = function(self, things, config)
    if isValid(things) then things = {things} end

    local cronId = Util.randomUuid()
    local enemies
    local knownValidEnemies -- this is to keep track which enemies where recently destroyed

    if not isFunction(things) then
        enemies, knownValidEnemies = validateAndInitEnemies(things)
    end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end

    local approachDistance = config.approachDistance or 10000
    local onApproachTriggered = false
    if not isFunction(config.onApproach) then onApproachTriggered = true end

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(things) then
                enemies, knownValidEnemies = validateAndInitEnemies(things())
            end

            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                for _, enemy in pairs(enemies) do
                    if not enemy:isValid() then
                        if isFunction(config.onDestruction) and knownValidEnemies[enemy] == true then
                            userCallback(config.onDestruction, mission, enemy)
                        end
                        knownValidEnemies[enemy] = nil
                    elseif onApproachTriggered == false then
                        if distance(enemy, self:getPlayer()) < approachDistance then
                            userCallback(config.onApproach, self, enemy)
                            onApproachTriggered = true
                        end
                    end
                end
                if mission:countValidEnemies() == 0 then
                    mission:success()
                end
            end, 0.2)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)

            if isFunction(config.onEnd) then userCallback(config.onEnd, self) end
        end,
    })

    Mission:forPlayer(mission)

    --- get all enemy targets - alive or dead
    --- @param self
    --- @return nil|table[ShipTemplateBased|WarpJammer|ScanProbe]
    mission.getEnemies = function(self)
        if isNil(enemies) then return nil end

        local ret = {}
        for _,enemy in pairs(enemies) do table.insert(ret, enemy) end
        return ret
    end
    --- count all enemy targets - alive or dead
    --- @param self
    --- @return number
    mission.countEnemies = function(self)
        if isNil(enemies) then return nil end
        return Util.size(enemies)
    end

    --- get enemies that are still alive
    --- @param self
    --- @return nil|table[ShipTemplateBased|WarpJammer|ScanProbe]
    mission.getValidEnemies = function(self)
        if isNil(enemies) then return nil end

        local ret = {}
        for _,enemy in pairs(enemies) do if enemy:isValid() then table.insert(ret, enemy) end end
        return ret
    end
    --- count enemies that are still alive
    --- @param self
    --- @return number
    mission.countValidEnemies = function(self)
        if isNil(enemies) then return nil end
        return Util.size(self:getValidEnemies())
    end

    --- get enemies that were killed
    --- @param self
    --- @return nil|table[ShipTemplateBased|WarpJammer|ScanProbe]
    mission.getInvalidEnemies = function(self)
        if isNil(enemies) then return nil end

        local ret = {}
        for _,enemy in pairs(enemies) do if not enemy:isValid() then table.insert(ret, enemy) end end
        return ret
    end

    --- count enemies that were killed
    --- @param self
    --- @return number
    mission.countInvalidEnemies = function(self)
        if isNil(enemies) then return nil end
        return Util.size(self:getInvalidEnemies())
    end

    return mission
end