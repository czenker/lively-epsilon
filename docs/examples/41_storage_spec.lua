insulate("documentation on Storage", function()

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
            ore = Product:new("Iron Ore"),
        }

        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [products.power] = 1000,
            [products.o2] = 500,
        })

        local function printStorage(station, product)
            if station:canStoreProduct(product) then
                print(string.format(
                    "Station stores %d/%d units of %s. There is space for %d more.",
                    station:getProductStorage(product),
                    station:getMaxProductStorage(product),
                    product:getName(),
                    station:getEmptyProductStorage(product)
                ))
            else
                print("Station can not store " .. product:getName() .. ".")
            end
        end

        printStorage(station, products.power)
        printStorage(station, products.ore)

        station:modifyProductStorage(products.power, 700)
        printStorage(station, products.power)

        -- will print:
        -- end::basic[]
        local expected = split([[
        -- tag::basic[]
        -- Station stores 0/1000 units of Energy Cell. There is space for 1000 more.
        -- Station can not store Iron Ore.
        -- Station stores 700/1000 units of Energy Cell. There is space for 300 more.
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