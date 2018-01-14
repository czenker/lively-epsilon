insulate("Product", function()
    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("new()", function()
        it("returns a valid Product", function()
            local product = Product:new("Fake")

            assert.is_true(Product.isProduct(product))

            assert.is_same("Fake", product:getName())
            assert.is_string(product:getId())
            assert.not_same("", product:getId())
        end)
        it("fails if first argument is a number", function()
            assert.has_error(function() Product:new(42) end)
        end)
        it("auto generates an id", function()
            local product = Product:new("Fake")

            assert.is_string(product:getId())
            assert.not_same("", product:getId())
        end)
        it("allows to set an id", function()
            local product = Product:new("Fake", "unobtainium")
            assert.is_same("unobtainium", product:getId())
        end)
        it("fails if id is numeric", function()
            assert.has_error(function() Product:new("Fake", 42) end)
        end)
    end)

    describe("toId()", function()
        it("returns string if a string was given", function()
            assert.is_same("foobar", Product:toId("foobar"))
        end)
        it("returns a string if product is given", function()
            local product = Product:new("Product", "theId")

            assert.is_same("theId", Product:toId(product))
        end)
    end)

end)