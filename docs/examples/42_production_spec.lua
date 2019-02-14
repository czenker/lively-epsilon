insulate("documentation on Production", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        -- tag::basic[]
        local products = {
            power = Product:new("Energy Cell"),
            o2 = Product:new("Oxygen"),
        }

        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [products.power] = 1000,
            [products.o2] = 500,
        })
        -- give the station something to start with
        station:modifyProductStorage(products.power, 1000)

        Station:withProduction(station, {
            {
                productionTime = 30,
                consumes = {
                    { product = products.power, amount = 10 }
                },
                produces = {
                    { product = products.o2, amount = 10 },
                }
            },
        })
        -- end::basic[]

        assert.is_same(0, station:getProductStorage(products.o2))
        for _=1,29 do Cron.tick(1) end
        assert.is_same(0, station:getProductStorage(products.o2))
        Cron.tick(1.1)
        assert.is_same(10, station:getProductStorage(products.o2))
        assert.is_same(990, station:getProductStorage(products.power))
    end)
end)