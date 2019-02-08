insulate("documentation on Tags", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        -- tag::basic[]
        local ship = CpuShip()
        Ship:withTags(ship, "fighter")
        ship:addTag("blue")
        ship:removeTag("fighter")

        local person = Person:byName("John")
        Generic:withTags(person)
        person:addTag("male")

        if person:hasTag("male") then
            print("Hello Mr. " .. person:getFormalName())
        else
            print("Hello Mrs. " .. person:getFormalName())
        end
        -- end::basic[]
    end)
    it("generic", function()
        -- tag::object[]
        local object = {
            title = "Foobar",
            message = "Hello World",
        }
        Generic:withTags(object)
        object:addTag("english")
        -- end::object[]
    end)
end)