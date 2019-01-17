-- a Narrative is CpuShip starting a certain station and doing stuff
Narrative = Narrative or {}

local function hasAllTags(station, tags)
    if not Station:hasTags(station) then return false end
    for _, tag in pairs(tags) do
        if not station:hasTag(tag) then return false end
    end
    return true
end

local function findFromAndTo(fromCandidates, toCandidates, narrative)
    for _,from in ipairs(Util.randomSort(fromCandidates)) do
        for _,to in ipairs(Util.randomSort(toCandidates)) do
            if from ~= to then return from, to end
        end
    end
    return nil, nil
end


Narrative.newRepository = function(self)
    local stations = {}
    local narratives = {}

    local filter = function(conf)
        if isTable(conf) then
            local ret = {}
            for _, station in pairs(stations) do
                if conf.tags and not hasAllTags(station, conf.tags) then
                    -- continue
                else
                    table.insert(ret, station)
                end
            end
            return ret
        else return stations
        end
    end

    local function findNarrative(narrativeCandidates)
        for _, narrative in ipairs(Util.randomSort(narrativeCandidates)) do
            local filteredFroms = filter(narrative.from)
            local filteredTos = filter(narrative.to)

            local from, to = findFromAndTo(filteredFroms, filteredTos, narrative)
            if from ~=nil and to ~= nil then return narrative, from, to end
        end
        return nil
    end

    return {
        addNarrative = function(self, config, id)
            config = config or {}
            if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
            config = Util.deepCopy(config)

            -- @TODO: validation

            config.from = config.from or {}
            if isString(config.from.tags) then config.from.tags = {config.from.tags} end
            config.to = config.to or {}
            if isString(config.to.tags) then config.to.tags = {config.to.tags} end

            id = id or Util.randomUuid()
            if not isString(id) then error("Expected id to be a string, but got " .. typeInspect(id), 2) end

            narratives[id] = config

            return id
        end,
        countNarratives = function(self)
            return Util.size(narratives)
        end,
        addStation = function(self, station)
            if not isEeStation(station) then error("Expected a Station, but got " .. typeInspect(station)) end
            stations[station] = station
        end,
        countStations = function(self)
            return Util.size(stations)
        end,
        findOne = function()
            if Util.size(narratives) == 0 then return nil end
            if Util.size(stations) == 0 then return nil end

            local filteredNarratives = narratives -- @TODO

            local narrative, from, to = findNarrative(filteredNarratives)

            if narrative ~= nil and from ~= nil and to ~= nil then
                narrative = Util.deepCopy(narrative)
                narrative.from = from
                narrative.to = to
                return narrative
            end
        end,
    }
end

Narrative.isRepository = function(self, thing)
    return isTable(thing) and
            isFunction(thing.addNarrative) and
            isFunction(thing.countNarratives) and
            isFunction(thing.addStation) and
            isFunction(thing.countStations) and
            isFunction(thing.findOne)
end