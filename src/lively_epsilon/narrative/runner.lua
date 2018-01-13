Narrative = Narrative or {}

Narrative.run = function(self, config)
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if not isEeStation(config.from) then error("Expected config.from to be a station, but got " .. type(config.from), 2) end
    if not isEeStation(config.to) then error("Expected config.to to be a station, but got " .. type(config.to), 2) end

    local ship = CpuShip()
    if isFunction(config.onCreation) then config.onCreation(ship, config.from, config.to) end
    Util.spawnAtStation(config.from, ship)

    Ship:patrol(ship, {
        {
            target = config.to,
            onArrival = function()
                ship:destroy()
            end
        }
    })
end