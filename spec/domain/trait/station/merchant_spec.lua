insulate("Station:withMerchant()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local product = Product:new("Power Cells", {id="power"})

    it("throws an error if neither buying nor selling price is set", function()
        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [product] = 1000
        })

        assert.has_error(function()
            Station:withMerchant(station, {
                [product] = {}
            })
        end)
    end)

    describe("when configuring a bought product", function()
        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [product] = 1000
        })
        Station:withMerchant(station, {
            [product] = { buyingPrice = 42 }
        })

        it("causes hasMerchant() to be true", function()
            assert.is_true(Station:hasMerchant(station))
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
            assert.is_same({[product:getId()] = product}, station:getProductsBought(product))
        end)

        it("returns an empty list of sold products", function()
            assert.is_same({}, station:getProductsSold(product))
        end)
    end)

    it("does not buy above the buyingLimit", function()
        local station = SpaceStation()
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
        local station = SpaceStation()
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
        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [product] = 1000
        })
        Station:withMerchant(station, {
            [product] = { sellingPrice = 42 }
        })

        it("causes hasMerchant() to be true", function()
            assert.is_true(Station:hasMerchant(station))
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

        it("returns no buyingPrice", function()
            assert.is_nil(station:getProductBuyingPrice(product))
        end)

        it("returns nil for getMaxProductBuying", function()
            assert.is_nil(station:getMaxProductBuying(product))
        end)

        it("returns a list of sold products", function()
            assert.is_same({[product:getId()] = product}, station:getProductsSold(product))
        end)

        it("returns an empty list of bought products", function()
            assert.is_same({}, station:getProductsBought(product))
        end)
    end)

    it("does not sell below the sellingLimit", function()
        local station = SpaceStation()
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
        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [product] = 1000
        })
        Station:withMerchant(station, {
            [product] = { sellingPrice = function(self) return 42 end }
        })

        assert.is_same(42, station:getProductSellingPrice(product))
    end)
    describe("when configuring a bought and sold product", function()
        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [product] = 1000
        })
        Station:withMerchant(station, {
            [product] = { sellingPrice = 42, buyingPrice = 21 }
        })

        it("causes hasMerchant() to be true", function()
            assert.is_true(Station:hasMerchant(station))
        end)

        it("causes isBuyingProduct() to be true", function()
            assert.is_true(station:isBuyingProduct(product))
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

        it("does not buy above the maxStorage", function()
            station:modifyProductStorage(product, -9999)
            assert.is_same(1000, station:getMaxProductBuying(product))

            station:modifyProductStorage(product, 300)
            assert.is_same(700, station:getMaxProductBuying(product))

            station:modifyProductStorage(product, 700)
            assert.is_same(0, station:getMaxProductBuying(product))
        end)

        it("returns the correct selling price", function()
            assert.is_same(42, station:getProductSellingPrice(product))
        end)

        it("returns the correct buying price", function()
            assert.is_same(21, station:getProductBuyingPrice(product))
        end)

        it("returns a list of bought products", function()
            assert.is_same({[product:getId()] = product}, station:getProductsBought(product))
        end)

        it("returns a list of sold products", function()
            assert.is_same({[product:getId()] = product}, station:getProductsSold(product))
        end)
    end)
    describe("player-dependent offers", function()
        local productForFriends = Product:new("Friendly Item")

        local stationSelling = SpaceStation()
        local stationBuying = SpaceStation()
        local friendlyPlayer = PlayerSpaceship()
        local neutralPlayer = PlayerSpaceship()

        Station:withStorageRooms(stationSelling, {
            [productForFriends] = 1000,
        })
        stationSelling:modifyProductStorage(productForFriends, 1000)
        Station:withMerchant(stationSelling, {
            [productForFriends] = { sellingPrice = function(self, buyer)
                if buyer == friendlyPlayer then return 42 else return nil end
            end }
        })

        Station:withStorageRooms(stationBuying, {
            [productForFriends] = 1000,
        })
        Station:withMerchant(stationBuying, {
            [productForFriends] = { buyingPrice = function(self, seller)
                if seller == friendlyPlayer then return 42 else return nil end
            end }
        })

        it("getProductsSold() filters products", function()
            assert.contains_value(productForFriends, stationSelling:getProductsSold(friendlyPlayer))
            assert.not_contains_value(productForFriends, stationSelling:getProductsSold(neutralPlayer))
        end)

        it("isSellingProduct() filters products", function()
            assert.is_true(stationSelling:isSellingProduct(productForFriends, friendlyPlayer))
            assert.is_false(stationSelling:isSellingProduct(productForFriends, neutralPlayer))
        end)

        it("getMaxProductSelling() filters products", function()
            assert.not_nil(stationSelling:getMaxProductSelling(productForFriends, friendlyPlayer))
            assert.is_nil(stationSelling:getMaxProductSelling(productForFriends, neutralPlayer))
        end)

        it("getProductSellingPrice() filters products", function()
            assert.is_same(42, stationSelling:getProductSellingPrice(productForFriends, friendlyPlayer))
            assert.is_nil(stationSelling:getProductSellingPrice(productForFriends, neutralPlayer))
        end)

        it("getProductsBought() filters products", function()
            assert.contains_value(productForFriends, stationBuying:getProductsBought(friendlyPlayer))
            assert.not_contains_value(productForFriends, stationBuying:getProductsBought(neutralPlayer))
        end)

        it("isBuyingProduct() filters products", function()
            assert.is_true(stationBuying:isBuyingProduct(productForFriends, friendlyPlayer))
            assert.is_false(stationBuying:isBuyingProduct(productForFriends, neutralPlayer))
        end)

        it("getMaxProductBuying() filters products", function()
            assert.not_nil(stationBuying:getMaxProductBuying(productForFriends, friendlyPlayer))
            assert.is_nil(stationBuying:getMaxProductBuying(productForFriends, neutralPlayer))
        end)

        it("getProductBuyingPrice() filters products", function()
            assert.is_same(42, stationBuying:getProductBuyingPrice(productForFriends, friendlyPlayer))
            assert.is_nil(stationBuying:getProductBuyingPrice(productForFriends, neutralPlayer))
        end)
    end)
end)