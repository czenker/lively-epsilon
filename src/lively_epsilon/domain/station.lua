local prototype = {
    isEnriched = true,
}

Station = Station or {}
Station.enrich = function(self, station)
    if not isEeStation(station) then
        error("station given to Station.enrich needs to be a SpaceStation", 2)
    end

    if (station.isEnriched == true) then return station end

    for key, value in pairs(prototype) do
        station[key] = value
    end

    station:setCommsScript("src/lively_epsilon/scripts/comms.lua")

    return station
end

setmetatable(Station,{
    __index = ShipTemplateBased
})