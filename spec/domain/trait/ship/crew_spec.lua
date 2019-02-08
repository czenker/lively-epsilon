insulate("Ship", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":withCrew()", function()
        it("should create a crew", function()
            local ship = CpuShip()

            Ship:withCrew(ship)

            assert.is_true(Ship:hasCrew(ship))
        end)

        it("should create a crew with a certain position", function()
            local person = personMock()
            local ship = CpuShip()

            Ship:withCrew(ship, {captain = person})

            assert.is_true(ship:hasCrewAtPosition("captain"))
            assert.is_same(person, ship:getCrewAtPosition("captain"))
            assert.is_false(ship:hasCrewAtPosition("science"))
        end)

        it("should fail when the position is not a string", function()
            local person = personMock()
            local ship = CpuShip()

            assert.has_error(function () Ship:withCrew(ship, {person}) end)
        end)

        it("should fail when the position is not a person", function()
            local person = {}
            local ship = CpuShip()

            assert.has_error(function () Ship:withCrew(ship, {captain = person}) end)
        end)

        it("can be called multiple times to add different persons", function()
            local person1 = personMock()
            local person2 = personMock()
            local ship = CpuShip()

            Ship:withCrew(ship, {captain = person1})
            Ship:withCrew(ship, {science = person2})

            assert.is_same(person1, ship:getCrewAtPosition("captain"))
            assert.is_same(person2, ship:getCrewAtPosition("science"))
        end)

        it("can be called multiple times to override a position", function()
            local person1 = personMock()
            local person2 = personMock()
            local ship = CpuShip()

            Ship:withCrew(ship, {captain = person1})
            Ship:withCrew(ship, {captain = person2})

            assert.is_same(person2, ship:getCrewAtPosition("captain"))
        end)
    end)
    describe(":withCaptain(), getCaptain()", function()
        it("sets the captain", function()
            local person = personMock()
            local ship = CpuShip()

            Ship:withCaptain(ship, person)
            assert.is_true(ship:hasCrewAtPosition("captain"))
            assert.is_true(ship:hasCaptain())
            assert.is_same(person, ship:getCrewAtPosition("captain"))
            assert.is_same(person, ship:getCaptain())
        end)
    end)
    describe(":withHelmsOfficer()", function()
        it("sets the helms officer", function()
            local person = personMock()
            local ship = CpuShip()

            Ship:withHelmsOfficer(ship, person)
            assert.is_true(ship:hasCrewAtPosition("helms"))
            assert.is_true(ship:hasHelmsOfficer())
            assert.is_same(person, ship:getCrewAtPosition("helms"))
            assert.is_same(person, ship:getHelmsOfficer())
        end)
    end)
    describe(":withRelayOfficer()", function()
        it("sets the relay officer", function()
            local person = personMock()
            local ship = CpuShip()

            Ship:withRelayOfficer(ship, person)
            assert.is_true(ship:hasCrewAtPosition("relay"))
            assert.is_true(ship:hasRelayOfficer())
            assert.is_same(person, ship:getCrewAtPosition("relay"))
            assert.is_same(person, ship:getRelayOfficer())
        end)
    end)
    describe(":withScienceOfficer()", function()
        it("sets the science officer", function()
            local person = personMock()
            local ship = CpuShip()

            Ship:withScienceOfficer(ship, person)
            assert.is_true(ship:hasCrewAtPosition("science"))
            assert.is_true(ship:hasScienceOfficer())
            assert.is_same(person, ship:getCrewAtPosition("science"))
            assert.is_same(person, ship:getScienceOfficer())
        end)
    end)
    describe(":withWeaponsOfficer()", function()
        it("sets the weapons officer", function()
            local person = personMock()
            local ship = CpuShip()

            Ship:withWeaponsOfficer(ship, person)
            assert.is_true(ship:hasCrewAtPosition("weapons"))
            assert.is_true(ship:hasWeaponsOfficer())
            assert.is_same(person, ship:getCrewAtPosition("weapons"))
            assert.is_same(person, ship:getWeaponsOfficer())
        end)
    end)
    describe(":withEngineeringOfficer()", function()
        it("sets the engineering officer", function()
            local person = personMock()
            local ship = CpuShip()

            Ship:withEngineeringOfficer(ship, person)
            assert.is_true(ship:hasCrewAtPosition("engineering"))
            assert.is_true(ship:hasEngineeringOfficer())
            assert.is_same(person, ship:getCrewAtPosition("engineering"))
            assert.is_same(person, ship:getEngineeringOfficer())
        end)
    end)
end)