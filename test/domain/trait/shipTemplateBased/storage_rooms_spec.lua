insulate("ShipTemplateBased", function()
    require "lively_epsilon"
    require "test.mocks"

    describe("withStorageRooms()", function()
        local product = Product:new("Power Cells", "power")
        local station = eeStationMock()

        Station:withStorageRooms(station, {
            [product] = 1000
        })

        it("causes hasStorage() to be true", function()
            assert.is_true(Ship:hasStorage(station))
        end)

        it("remembers which products where stored", function()
            station:modifyProductStorage(product, 100)
            assert.is_same(100, station:getProductStorage(product))

            station:modifyProductStorage(product, 42)
            assert.is_same(142, station:getProductStorage(product))

            station:modifyProductStorage(product, -100)
            assert.is_same(42, station:getProductStorage(product))
        end)

        it("it keeps constraints on the storage capacity without raising an error", function()
            station:modifyProductStorage(product, -9999)
            assert.is_same(0, station:getProductStorage(product))

            station:modifyProductStorage(product, 9999)
            assert.is_same(1000, station:getProductStorage(product))
        end)

        describe("canStoreProduct", function()
            it("should return true if the product was configured", function()
                assert.is_true(station:canStoreProduct(product))
            end)

            it("should return false if the product was not configured", function()
                assert.is_false(station:canStoreProduct(Product:new("Test Mock", "foo")))
            end)

        end)
    end)
end)