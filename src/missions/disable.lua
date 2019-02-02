Missions = Missions or {}

--- Disable a ship by destroying its engines and force it to stop.
---
--- Assuming the ship has it, the Impulse Drive, Warp Drive and Jump Drive have to be destroyed.
---
--- @param self
--- @param target CpuShip|function
--- @param config table
---   @field approachDistance (default: `10000`)
---   @field onApproach function(mission)
---   @field damageThreshold number (default: `-0.2`) How far the systems need to be destroyed to count as success. (`1` = full health, `0` = disabled, `-1` = severely damaged)
---   @field distanceToFinish number (default: `1000`) How close the players need to be to the ship so they surrender
---   @field onSurrender function(mission)
---   @field onDestruction function(mission)
--- @return Mission
Missions.disable = function(self, target, config)
    local cronId = Util.randomUuid()

    if not isEeShip(target) and not isFunction(target) then error("Expected target to be a ship or a funcition, but got " .. typeInspect(target), 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end

    local approachDistance = config.approachDistance or 10000
    if not isNumber(approachDistance) or approachDistance < 0 then error("Eypected approachDistance to be a positive number, but got " .. typeInspect(approachDistance), 2) end
    local onApproachTriggered = false
    if not isFunction(config.onApproach) then onApproachTriggered = true end
    config.damageThreshold = config.damageThreshold or -0.2
    if not isNumber(config.damageThreshold) or config.damageThreshold < -1 or config.damageThreshold > 1 then error("Eypected damageThreshold to be a number between -1..1, but got " .. typeInspect(config.damageThreshold), 2) end

    -- the distance the player should have tops when the ship is disabled. If they are too far away the ship might not see a reason to surrender.
    config.distanceToFinish = config.distanceToFinish or 1000
    if not isNumber(config.distanceToFinish) or config.distanceToFinish < 0 then error("Eypected distanceToFinish to be a positive number, but got " .. typeInspect(config.distanceToFinish), 2) end

    local isTargetDisabled = function()
        return
            isEeShip(target) and
            target:getSystemHealth("impulse") <= config.damageThreshold and
            (not target:hasJumpDrive() or target:getSystemHealth("jumpdrive") <= config.damageThreshold) and
            (not target:hasWarpDrive() or target:getSystemHealth("warp") <= config.damageThreshold)
    end

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(target) then
                if isFunction(target) then
                    target = target(self)
                    if not isEeShip(target) then error("Expected function to return a target ship, but got " .. typeInspect(target), 2) end
                end
            end

            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                if not target:isValid() then
                     userCallback(config.onDestruction, mission)
                    mission:fail()
                elseif onApproachTriggered == false and distance(target, self:getPlayer()) < approachDistance then
                    userCallback(config.onApproach, mission)
                    onApproachTriggered = true
                elseif isTargetDisabled() and distance(target, self:getPlayer()) <= config.distanceToFinish then
                    userCallback(config.onSurrender, mission)
                    mission:success()
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

    --- @param self
    --- @return nil|CpuShip
    mission.getTarget = function(self)
        if isEeShip(target) and target:isValid() then return target end
    end

    return mission
end