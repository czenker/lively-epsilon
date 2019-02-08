insulate("documentation on EventHandler", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("register, fire", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::basic[]
        local eh = EventHandler:new()
        eh:register("newPlayer", function(thePlayer)
            thePlayer:addToShipLog("Hello World.")
        end)
        eh:register("newPlayer", function(thePlayer)
            local x,y = thePlayer:getPosition()
            CpuShip():setFaction("Kraylor"):setPostion(x + 4000, y):orderAttack(thePlayer)
        end)

        Cron.regular(function()
            if not player:isValid() then
                player = PlayerSpaceship():setCallSign("Reborn")
                eh:fire("newPlayer", player)
            end
        end)
        -- end::basic[]

        -- tag::allowed-events[]
        local eh = EventHandler:new({
            allowedEvents = {"foo", "bar"}
        })
        eh:register("bar", function() --[[ your code goes here]] end) -- this works

        -- end::allowed-events[]
        assert.has_error(function()
        -- tag::allowed-events[]
        eh:register("baz", function() --[[ your code goes here]] end) -- this will fail with an error
        -- end::allowed-events[]
        end)
        -- tag::allowed-events[]

        eh:fire("bar") -- this works
        -- end::allowed-events[]
        assert.has_error(function()
        -- tag::allowed-events[]
        eh:fire("baz") -- this will fail with an error
        -- end::allowed-events[]
        end)

        -- tag::unique[]
        local eh = EventHandler:new({ unique = true })
        eh:register("bar", function() --[[ your code goes here]] end)
        eh:fire("bar") -- this works
        eh:register("bar", function() --[[ your code goes here]] end) -- this will cause a warning
        eh:fire("bar") -- this will cause a warning
        -- end::unique[]
    end)
    it("priority", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::priority[]
        local eh = EventHandler:new()
        eh:register("count", function() print("2") end)
        eh:register("count", function() print("3") end, 10)
        eh:register("count", function() print("1") end, -10)

        eh:fire("count") -- will print "123"
        -- end::priority[]
    end)
end)