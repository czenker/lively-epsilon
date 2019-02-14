insulate("documentation on Trader", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        withUniverse(function()
            -- tag::basic[]
            local products = {
                ore = Product:new("Iron Ore"),
            }

            local factory = SpaceStation():setPosition(0, 0)
            Station:withStorageRooms(factory, {
                [products.ore] = 1000
            })

            local ship = CpuShip():setPosition(1000, 0)
            Ship:withStorageRooms(ship, {
                [products.ore] = 1000,
            })
            Ship:behaveAsMiner(ship, factory, function(asteroid, ship, station)
                return {
                    [products.ore] = math.random(10, 50)
                }
            end)
            -- end::basic[]

            local asteroid = Asteroid():setPostion(5000, 0)
            for _=1,10 do Cron.tick(1) end
            assert.is_same("Attack", ship:getOrder())
            assert.is_same(asteroid, ship:getOrderTarget())
        end)
    end)
end)