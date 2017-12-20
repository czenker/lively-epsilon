insulate("Station", function()
    require "lively_epsilon"
    require "test.mocks"

    describe("withMerchant()", function()
        local product = { id = "power", name = "Power Cells" }

        describe("when configuring a bought product", function()
            local station = eeStationMock()
            Station:withStorageRooms(station, {
                [product] = 1000
            })
            Station:withMerchant(station, {
                [product] = { buyingPrice = 42 }
            })

            it("causes hasMerchant() to be true", function()
                assert.is_true(hasMerchant(station))
            end)

            it("causes isBuyingProduct() to be true", function()
                assert.is_true(station:isBuyingProduct(product))
            end)

            it("causes isSellingProduct() to be false", function()
                assert.is_false(station:isSellingProduct(product))
            end)

            it("does not buy above the maxStorage", function()
                station:modifyProductStorage(product, -9999)
                assert.is_same(1000, station:getMaxProductBuying(product))

                station:modifyProductStorage(product, 300)
                assert.is_same(700, station:getMaxProductBuying(product))

                station:modifyProductStorage(product, 700)
                assert.is_same(0, station:getMaxProductBuying(product))
            end)

            it("returns the correct buying price", function()
                assert.is_same(42, station:getProductBuyingPrice(product))
            end)

            it("returns no sellingPrice", function()
                assert.is_nil(station:getProductSellingPrice(product))
            end)

            it("returns nil for getMaxProductSelling", function()
                assert.is_nil(station:getMaxProductSelling(product))
            end)

            it("returns a list of bought products", function()
                assert.is_same({[product.id] = product}, station:getProductsBought(product))
            end)

            it("returns an empty list of sold products", function()
                assert.is_same({}, station:getProductsSold(product))
            end)
        end)

        it("does not buy above the buyingLimit", function()
            local station = eeStationMock()
            Station:withStorageRooms(station, {
                [product] = 1000
            })
            Station:withMerchant(station, {
                [product] = { buyingPrice = 42, buyingLimit = 100 }
            })

            station:modifyProductStorage(product, -9999)
            assert.is_same(100, station:getMaxProductBuying(product))

            station:modifyProductStorage(product, 30)
            assert.is_same(70, station:getMaxProductBuying(product))

            station:modifyProductStorage(product, 670)
            assert.is_same(0, station:getMaxProductBuying(product))

            station:modifyProductStorage(product, 300)
            assert.is_same(0, station:getMaxProductBuying(product))
        end)

        it("can use a function for the buying price", function()
            local station = eeStationMock()
            Station:withStorageRooms(station, {
                [product] = 1000
            })
            Station:withMerchant(station, {
                [product] = { buyingPrice = function(self) return 42 end }
            })

            assert.is_same(42, station:getProductBuyingPrice(product))
        end)

        -- ----------
        -- selling
        -- ----------
        describe("when configuring a sold product", function()
            local station = eeStationMock()
            Station:withStorageRooms(station, {
                [product] = 1000
            })
            Station:withMerchant(station, {
                [product] = { sellingPrice = 42 }
            })

            it("causes hasMerchant() to be true", function()
                assert.is_true(hasMerchant(station))
            end)

            it("causes isBuyingProduct() to be false", function()
                assert.is_false(station:isBuyingProduct(product))
            end)

            it("causes isSellingProduct() to be true", function()
                assert.is_true(station:isSellingProduct(product))
            end)

            it("does not sell below 0", function()
                station:modifyProductStorage(product, -9999)
                assert.is_same(0, station:getMaxProductSelling(product))

                station:modifyProductStorage(product, 300)
                assert.is_same(300, station:getMaxProductSelling(product))

                station:modifyProductStorage(product, 700)
                assert.is_same(1000, station:getMaxProductSelling(product))
            end)

            it("returns the correct selling price", function()
                assert.is_same(42, station:getProductSellingPrice(product))
            end)

            it("returns no buingPrice", function()
                assert.is_nil(station:getProductBuyingPrice(product))
            end)

            it("returns nil for getMaxProductBuying", function()
                assert.is_nil(station:getMaxProductBuying(product))
            end)

            it("returns a list of sold products", function()
                assert.is_same({[product.id] = product}, station:getProductsSold(product))
            end)

            it("returns an empty list of bought products", function()
                assert.is_same({}, station:getProductsBought(product))
            end)
        end)

        it("does not sell below the sellingLimit", function()
            local station = eeStationMock()
            Station:withStorageRooms(station, {
                [product] = 1000
            })
            Station:withMerchant(station, {
                [product] = { sellingPrice = 42, sellingLimit = 100 }
            })

            station:modifyProductStorage(product, -9999)
            assert.is_same(0, station:getMaxProductSelling(product))

            station:modifyProductStorage(product, 30)
            assert.is_same(0, station:getMaxProductSelling(product))

            station:modifyProductStorage(product, 670)
            assert.is_same(600, station:getMaxProductSelling(product))

            station:modifyProductStorage(product, 300)
            assert.is_same(900, station:getMaxProductSelling(product))
        end)

        it("can use a function for the selling price", function()
            local station = eeStationMock()
            Station:withStorageRooms(station, {
                [product] = 1000
            })
            Station:withMerchant(station, {
                [product] = { sellingPrice = function(self) return 42 end }
            })

            assert.is_same(42, station:getProductSellingPrice(product))
        end)
    end)
end)