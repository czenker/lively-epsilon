insulate("ShipTemplateBased", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("withCrew()", function()
        it("should create a crew", function()
            local station = SpaceStation()

            ShipTemplateBased:withCrew(station)

            assert.is_true(ShipTemplateBased:hasCrew(station))
        end)

        it("should fail when the position is not a string", function()
            local person = personMock()
            local station = SpaceStation()

            assert.has_error(function () ShipTemplateBased:withCrew(station, {person}) end)
        end)

        it("should fail when the position is not a person", function()
            local station = SpaceStation()

            assert.has_error(function () ShipTemplateBased:withCrew(station, {captain = {}}) end)
        end)

        it("can be called multiple times to add different persons", function()
            local person1 = personMock()
            local person2 = personMock()
            local station = SpaceStation()

            ShipTemplateBased:withCrew(station, {commander = person1})
            ShipTemplateBased:withCrew(station, {relay = person2})

            assert.is_same(person1, station:getCrewAtPosition("commander"))
            assert.is_same(person2, station:getCrewAtPosition("relay"))
        end)

        it("can be called multiple times to override a position", function()
            local person1 = personMock()
            local person2 = personMock()
            local station = SpaceStation()

            ShipTemplateBased:withCrew(station, {commander = person1})
            ShipTemplateBased:withCrew(station, {commander = person2})

            assert.is_same(person2, station:getCrewAtPosition("commander"))
        end)
    end)
end)