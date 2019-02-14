insulate("documentation on Merchant", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        local printedLines = {}
        local print = function(string)
            table.insert(printedLines, string)
        end

        local split = function(input)
            local t={}
            for str in string.gmatch(input, "([^\n]+)") do
                table.insert(t, str)
            end
            return t
        end
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

        Station:withMerchant(station, {
            [products.power] = { buyingPrice = 1, buyingLimit = 420 },
            [products.o2] = { sellingPrice = 5, sellingLimit = 42 },
        })

        station:modifyProductStorage(products.power, 100)
        station:modifyProductStorage(products.o2, 100)

        local function printMerchant(station, product)
            if station:isBuyingProduct(product) then
                print(string.format(
                    "Station buys a maximum of %d units of %s at a price of %d.",
                    station:getMaxProductBuying(product),
                    product:getName(),
                    station:getProductBuyingPrice(product)
                ))
            elseif station:isSellingProduct(product) then
                print(string.format(
                    "Station sells a maximum of %d units of %s at a price of %d.",
                    station:getMaxProductSelling(product),
                    product:getName(),
                    station:getProductSellingPrice(product)
                ))
            end
        end

        printMerchant(station, products.power)
        printMerchant(station, products.o2)

        -- will print:
        -- end::basic[]
        local expected = split([[
        -- tag::basic[]
        -- Station buys a maximum of 320 units of Energy Cell at a price of 1.
        -- Station sells a maximum of 58 units of Oxygen at a price of 5.
        -- end::basic[]
        ]])

        table.remove(expected, #expected)
        table.remove(expected, #expected)
        table.remove(expected, 1)

        assert.is_same(#expected, #printedLines)

        for i=1,#expected do
            local exp = expected[i]:gsub("^[%s%-]+", "")
            assert.is_same(exp, printedLines[i])
        end
    end)
end)