GlobalNarrative = Narrative:newRepository()

GlobalNarrative:addNarrative({
    name = "Miners going to work",
    from = {
        tags = "residual",
    },
    to = {
        tags = "mining"
    },
    onCreation = function(ship, from, to)
        ship:setTemplate("Personnel Freighter " .. math.random(1, 5)):setFactionId(Util.random({from:getFactionId(), to:getFactionId()}))
        MyCpuShip(ship)

        local persons = {}

        for i=1,math.random(1, 5) do
            persons[i] = Person:newHuman()
        end

        local amountLabel
        if Util.size(persons) == 1 then
            amountLabel = Util.random({
                "a",
                "one",
            }) .. " " .. Util.random({
                "passenger",
                "person",
            })
        else
            amountLabel = Util.size(persons) .. " " .. Util.random({
                "passengers",
                "persons",
                "people",
            })
        end
        local description = Util.random({
            ship:getCallSign(),
            "This ship",
            "This space ship",
            "This freighter",
            "This personnel freighter",
        }) .. " " .. Util.random({
            "brings",
            "is carrying",
        }) .. " " .. amountLabel .. " to " .. Util.random({
            to:getCallSign(),
            "a station in sector " .. to:getSectorName()
        }) .. "."

        ship:setDescription(description)
    end
})