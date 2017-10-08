--
--


local missions = {}
local activeMissions = {}

local function isMission(mission)
    return type(mission) == "table" and mission.id ~= nil and mission.title ~= nil and isEeStation(mission.giver) and type(mission.activate) == "function"
end

SideMissions = {
    addMission = function(mission)
        if not isMission(mission) then
            error("InvalidArgument: mission needs to be a Mission in addMission", 2)
        end
    end,

    getMissionsByStation = function(station)
        if not isEeStation(station) then
            error("InvalidArgument: station needs to be SpaceStation to call getMissionsByStation", 2)
        end

        -- @TODO
    end

}