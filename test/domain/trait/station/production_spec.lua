insulate("Station", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("withProduction()", function()
        local power = Product:new("Power Cells", {id="power"})
        local ore = Product:new("Iron Ore", {id="ore"})
        local glue = Product:new("Super Glue", {id="glue"})
        local herring = Product:new("Red Herring", {id="herring"})

        it("produces products in a interval", function()
            local station = SpaceStation()
            Station:withStorageRooms(station, {
                [power] = 1000,
                [herring] = 1000,
            })
            Station:withProduction(station, {
                {
                    productionTime = 5,
                    produces = {
                        { product = herring, amount = 5 },
                    },
                    consumes = {
                        { product = power, amount = 5 },
                    }
                }
            })
            station:modifyProductStorage(power, 100)

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(100, station:getProductStorage(power))
            assert.is_same(0, station:getProductStorage(herring))
            Cron.tick(1)
            assert.is_same(95, station:getProductStorage(power))
            assert.is_same(5, station:getProductStorage(herring))
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(95, station:getProductStorage(power))
            assert.is_same(5, station:getProductStorage(herring))
            Cron.tick(1)
            assert.is_same(90, station:getProductStorage(power))
            assert.is_same(10, station:getProductStorage(herring))
        end)

        it("does not produce if any of the consumed products is not available", function()
            local station = SpaceStation()
            Station:withStorageRooms(station, {
                [power] = 1000,
                [ore] = 1000,
                [glue] = 1000,
                [herring] = 1000,
            })
            Station:withProduction(station, {
                {
                    productionTime = 1,
                    produces = {
                        { product = herring, amount = 5 },
                    },
                    consumes = {
                        { product = power, amount = 10 },
                        { product = ore, amount = 10 },
                        { product = glue, amount = 10 },
                    }
                }
            })
            station:modifyProductStorage(power, 100)
            station:modifyProductStorage(ore, 5)
            station:modifyProductStorage(glue, 100)

            Cron.tick(5)
            Cron.tick(5)
            Cron.tick(5)
            assert.is_same(100, station:getProductStorage(power))
            assert.is_same(5, station:getProductStorage(ore))
            assert.is_same(100, station:getProductStorage(glue))
            assert.is_same(0, station:getProductStorage(herring))
        end)

        it("does not produce if there is no storage space for products left", function()
            local station = SpaceStation()
            Station:withStorageRooms(station, {
                [power] = 1000,
                [herring] = 1000,
            })
            Station:withProduction(station, {
                {
                    productionTime = 1,
                    produces = {
                        { product = herring, amount = 5 },
                    },
                    consumes = {
                        { product = power, amount = 10 },
                    }
                }
            })
            station:modifyProductStorage(power, 1000)
            station:modifyProductStorage(herring, 1000)

            Cron.tick(5)
            Cron.tick(5)
            Cron.tick(5)
            assert.is_same(1000, station:getProductStorage(power))
            assert.is_same(1000, station:getProductStorage(herring))
        end)

        it("does produce as long as there is any space left", function()
            local station = SpaceStation()
            Station:withStorageRooms(station, {
                [power] = 1000,
                [herring] = 1000,
            })
            Station:withProduction(station, {
                {
                    productionTime = 1,
                    produces = {
                        { product = herring, amount = 5 },
                    },
                    consumes = {
                        { product = power, amount = 10 },
                    }
                }
            })
            station:modifyProductStorage(power, 1000)
            station:modifyProductStorage(herring, 999)

            Cron.tick(5)
            Cron.tick(5)
            Cron.tick(5)
            assert.is_same(990, station:getProductStorage(power))
            assert.is_same(1000, station:getProductStorage(herring))
        end)



        it("produces with callbacks", function()
            local station = SpaceStation()
            local wasProduced = false
            Station:withStorageRooms(station, {
                [power] = 1000,
            })
            Station:withProduction(station, {
                {
                    productionTime = 5,
                    produces = function() wasProduced = true end,
                    consumes = {
                        { product = power, amount = 10 },
                    }
                }
            })
            station:modifyProductStorage(power, 1000)

            Cron.tick(5)
            assert.is_true(wasProduced)
            assert.is_same(990, station:getProductStorage(power))
        end)

        it("stops producing if station is destroyed", function()
            local station = SpaceStation()
            local wasProduced = false
            Station:withStorageRooms(station, {
                [herring] = 1000,
            })
            Station:withProduction(station, {
                {
                    productionTime = 1,
                    produces = function() wasProduced = true end,
                    consumes = {
                        { product = herring, amount = 1 },
                    }
                }
            })
            station:modifyProductStorage(herring, 1000)

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)

            station:destroy()
            wasProduced = false

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)

            assert.is_false(wasProduced)
        end)
    end)
end)