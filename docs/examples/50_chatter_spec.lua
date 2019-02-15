insulate("documentation on Chatter", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        withUniverse(function()
            -- tag::basic[]
            local chatter = Chatter:new({
                maxRange = 50000,
            })

            local ship = CpuShip()
            chatter:say(ship, "Carpe Diem")
            -- end::basic[]

            -- it should not error
            PlayerSpaceship()
            for _=1,50 do Cron.tick(1) end
        end)
    end)
    it("converse", function()
        withUniverse(function()
            -- tag::converse[]
            local chatter = Chatter:new()

            local ship1 = CpuShip()
            local ship2 = CpuShip()
            chatter:converse({
                {ship1, "Hey. What are you doing?"},
                {ship2, "Staring at the emptiness of space."},
                {ship1, "Wow. This sounds pretty boring."},
            })
            -- end::converse[]

            -- it should not error
            PlayerSpaceship()
            for _=1,50 do Cron.tick(1) end
        end)
    end)
    it("noise", function()
        withUniverse(function()
            -- tag::noise-intro[]
            local chatter = Chatter:new()
            local noise = Chatter:newNoise(chatter)

            noise:addChatFactory(Chatter:newFactory(1, function(stationOrShip) -- <1>
                return { -- <2>
                    { stationOrShip, "I'm so bored. Nothing is happening..."},
                }
            end))
            -- end::noise-intro[]
            -- tag::noise-two[]
            noise:addChatFactory(Chatter:newFactory(2, function(stationOrShip1, stationOrShip2)
                return {
                    { stationOrShip1, "I'm so bored. Nothing is happening..."},
                    { stationOrShip2, "Wanna play some \"I spy with my little eye\"?"},
                    { stationOrShip1, "Nah. I know you would pick black as space."},
                }
            end))
            -- end::noise-two[]
            -- tag::noise-filter[]
            noise:addChatFactory(Chatter:newFactory(2, function(station, ship)
                return {
                    { station, "Want to buy some engine oil from our station?"},
                    { ship, "No thanks, I'm fine."},
                }
            end, {
                filters = {
                    function(thing) return isEeStation(thing) end,
                    function(thing, station) return isEeShip(thing) and thing:isFriendly(station) end, -- <1>
                },
            }))
            -- end::noise-filter[]

            -- it should not error
            PlayerSpaceship()
            CpuShip()
            CpuShip()
            CpuShip()
            CpuShip()
            for _=1,600 do Cron.tick(1) end
        end)
    end)
end)