Missions = Missions or {}

-- A mission engaging all crew members and allowing different ways to solve.
--
-- Here is the basic run through that should also explain its name
-- A mining ship got out of control. It is roaming around trying to shoot everything that moves and the crew has to
-- destroy it. Unfortunately it has a very strong, but slow firing, laser and a malfunctioning shield that will emit
-- EMP bursts regularily. The good thing is, it is very slow and clumsy.
--
-- Possible ways to defeat it.
--   * a good helms can outmanouver its laser
--   * weapons can target specific systems to support the strategy
--   * comms can hack specific systems to achieve the same
--   * relay sees when EMP burst occur, so the crew may lower the shields to avoid damage
--   * engineering won't get bored during fights anyways
--
-- As a GM, if you really want to challenge your crew, take a faster and more agile ship or add more lasers. :)
--
-- onDestruction
-- onPlayerHitByEmpBurst
Missions.destroyRagingMiner = function(self, things, config)
    local cronId = "raging_miner_" .. Util.randomUuid()

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. type(config) .. " given.", 2) end

    local explosionSize = 2000
    local shieldDropAfterEmp = 0.5

    local mission
    mission = Missions:destroy(things, {
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        approachDistance = config.approachDistance,
        onApproach = config.onApproach,
        onStart = function(self)
            if isFunction(config.onStart) then config.onStart(self) end

            -- set initial shields to broken
            for _,ship in pairs(self:getValidEnemies()) do
                local initialEmpDelay = math.random() * 0.5
                ship.originalFrontShieldHealth = ship:getShieldMax(0)
                ship:setSystemHealth("frontshield", -1 * initialEmpDelay)

                if ship:getShieldCount() > 1 then
                    ship.originalBackShieldHealth = ship:getShieldMax(1)
                    ship:setSystemHealth("rearshield", -1 * (initialEmpDelay + shieldDropAfterEmp / 2))
                end
                ship:setShieldsMax(0) -- the ship has malfunctioning shields
                ship:setShields(0)
            end

            local function empBurst(ship, empDamage)
                ElectricExplosionEffect():setPosition(ship:getPosition()):setSize(explosionSize)
                for _, thing in pairs(ship:getObjectsInRange(explosionSize)) do
                    if thing ~= ship and isEeShipTemplateBased(thing) then

                        if isFunction(config.onPlayerHitByEmpBurst) and isEePlayer(thing) then
                            local shieldBefore = Util.totalShieldLevel(thing)
                            thing:takeDamage(empDamage, "emp")
                            local shieldAfter = Util.totalShieldLevel(thing)
                            config.onPlayerHitByEmpBurst(self, thing, ship, shieldAfter - shieldBefore)
                        else
                            thing:takeDamage(empDamage, "emp")
                        end
                    end
                end
            end

            Cron.regular(cronId, function()
                for _,ship in pairs(self:getValidEnemies()) do
                    -- EMP damage
                    if ship.originalFrontShieldHealth ~= nil and ship:getSystemHealth("frontshield") > 0 then
                        ship:setSystemHealth("frontshield", ship:getSystemHealth("frontshield") - shieldDropAfterEmp)
                        empBurst(ship, ship.originalFrontShieldHealth)
                    elseif ship.originalBackShieldHealth ~= nil and ship:getSystemHealth("rearshield") > 0 then
                        ship:setSystemHealth("rearshield", ship:getSystemHealth("rearshield") - shieldDropAfterEmp)
                        empBurst(ship, ship.originalBackShieldHealth)
                    end
                end
            end, 0.5)
        end,
        onDestruction = config.onDestruction,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)

            if isFunction(config.onEnd) then config.onEnd(self) end
        end,
    })

    return mission
end