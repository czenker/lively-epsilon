insulate("Product", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe("new()", function()
        it("returns a valid Product", function()
            local product = Product:new("Fake")

            assert.is_true(Product:isProduct(product))

            assert.is_same("Fake", product:getName())
            assert.is_string(product:getId())
            assert.not_same("", product:getId())
            assert.is_same(1, product:getSize())
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
            local product = Product:new("Fake", {id = "unobtainium"})
            assert.is_same("unobtainium", product:getId())
        end)
        it("allows to set size", function()
            local product = Product:new("Fake", {size = 42})
            assert.is_same(42, product:getSize())
        end)
        it("fails if size is non-numeric", function()
            assert.has_error(function() Product:new("Fake", {size = "foo"}) end)
        end)
        it("fails if second argument is numeric", function()
            assert.has_error(function() Product:new("Fake", 42) end)
        end)
    end)

    describe("toId()", function()
        it("returns string if a string was given", function()
            assert.is_same("foobar", Product:toId("foobar"))
        end)
        it("returns a string if product is given", function()
            local product = Product:new("Product", {id = "theId"})

            assert.is_same("theId", Product:toId(product))
        end)
    end)

end)