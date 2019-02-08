insulate("documentation on Cron", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    local function victory() end

    it("regular", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::regular[]
        Cron.regular(function()
            if not station:isValid() then
                -- you won
                victory("Human Navy")
            end
        end)
        -- end::regular[]
        -- tag::regular-interval[]
        Cron.regular(function(self)
            if distance(player, station) > 20000 then
                player:addToShipLog("You did not guard the station as you were supposed to.")
                victory("Kraylor")
            end
        end, 1)
        -- end::regular-interval[]

        for _=1,60 do Cron.tick(1) end
    end)

    it("once", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::once[]
        Cron.once(function()
            station:sendCommsMessage(player, "Do not forget my assignment.")
        end, 60)
        -- end::once[]

        for _=1,60 do Cron.tick(1) end
    end)
    it("abort", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::abort-inside[]
        Cron.regular(function(self)
            if player:isDocked(station) then
                Cron.abort(self)
            end
        end, 60)
        -- end::abort-inside[]
        -- tag::abort-outside[]
        Cron.once("timeout", function()
            player:addToShipLog("You were not fast enough.")
            victory("Kraylor")
        end, 5 * 60)
        Cron.regular(function(self)
            if player:isDocked(station) then
                Cron.abort("timeout")
                Cron.abort(self)
            end
        end)
        -- end::abort-outside[]
        -- tag::abort-outside2[]
        local cronId = Cron.once(function()
            player:addToShipLog("You were not fast enough.")
            victory("Kraylor")
        end, 5 * 60)
        Cron.regular(function(self)
            if player:isDocked(station) then
                Cron.abort(cronId)
                Cron.abort(self)
            end
        end)
        -- end::abort-outside2[]

        for _=1,60 do Cron.tick(1) end
    end)
    it("delta", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::delta[]
        local repairPerSecond = 2
        Cron.regular(function(self, delta)
            local hull = player:getHull() + delta * repairPerSecond
            player:setHull(hull)
            if hull > player:getHullMax() then
                Cron.abort(self)
            end
        end)
        -- end::delta[]

        for _=1,60 do Cron.tick(1) end
    end)
    it("now", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::now[]
        print("It is now " .. Cron.now())
        -- end::now[]

        for _=1,60 do Cron.tick(1) end
    end)
    it("addDelay", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::add-delay[]
        Cron.once("timeout", function()
            player:addToShipLog("You were not fast enough.")
            victory("Kraylor")
        end, 5 * 60)
        Cron.regular(function(self)
            if distance(player, 1000, 2000) < 500 then
                player:addToShipLog("You reached the waypoint and got 30 bonus seconds.")
                Cron.addDelay("timeout", 30)
                Cron.abort(self)
            end
        end)
        -- end::add-delay[]

        -- tag::get-delay[]
        Cron.once("timeout", function()
            player:addToShipLog("You were not fast enough.")
            victory("Kraylor")
        end, 5 * 60)
        Cron.regular(function(self)
            player:addToShipLog(string.format("Hurry up! Only %0.1f seconds left.", Cron.getDelay("timeout")))
        end, 10)
        -- end::get-delay[]

        for _=1,60 do Cron.tick(1) end
    end)
end)