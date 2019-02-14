insulate("documentation on Trader", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        withUniverse(function()
            -- tag::basic[]
            local products = {
                power = Product:new("Energy Cell"),
            }

            local sellingStation = SpaceStation():setPosition(0, 0)
            Station:withStorageRooms(sellingStation, {
                [products.power] = 1000
            })
            Station:withMerchant(sellingStation, {
                [products.power] = { sellingPrice = 1 },
            })

            local buyingStation = SpaceStation():setPosition(10000, 0)
            Station:withStorageRooms(buyingStation, {
                [products.power] = 1000
            })
            Station:withMerchant(buyingStation, {
                [products.power] = { buyingPrice = 1 },
            })

            local ship = CpuShip():setPosition(11000, 0)
            Ship:withStorageRooms(ship, {
                [products.power] = 1000,
            })
            Ship:behaveAsBuyer(ship, buyingStation, products.power)
            -- end::basic[]

            sellingStation:modifyProductStorage(products.power, 1000)
            for _=1,10 do Cron.tick(1) end
            assert.is_same("Dock", ship:getOrder())
            assert.is_same(sellingStation, ship:getOrderTarget())
        end)
    end)
end)