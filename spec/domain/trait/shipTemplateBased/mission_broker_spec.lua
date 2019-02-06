insulate("ShipTemplateBased", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":withMissionBroker()", function()
        it("causes hasMissionBroker() to be true", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            assert.is_true(ShipTemplateBased:hasMissionBroker(station))
        end)

        it("fails if first argument is not a SpaceObject", function()
            assert.has_error(function() ShipTemplateBased:withMissionBroker(42) end)
        end)

        it("fails if first argument is already a SpaceObject with broker", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            assert.has_error(function() ShipTemplateBased:withMissionBroker(station) end)
        end)

        it("fails if second argument is not a table", function()
            local station = SpaceStation()

            assert.has_error(function() ShipTemplateBased:withMissionBroker(station, 42) end)
        end)

        it("allows to set missions", function()
            local station = SpaceStation()

            ShipTemplateBased:withMissionBroker(station, {missions = {missionWithBrokerMock(), missionWithBrokerMock(), missionWithBrokerMock()}})
            assert.is_same(3, Util.size(station:getMissions()))
        end)

        it("fails if missions is a number", function()
            local station = SpaceStation()

            assert.has_error(function() ShipTemplateBased:withMissionBroker(station, {missions = 42}) end)
        end)

        it("fails if any of the missions is not a mission with broker", function()
            local station = SpaceStation()

            assert.has_error(function() ShipTemplateBased:withMissionBroker(station, {missions = {missionMock}}) end)
        end)
    end)

    describe(":addMission()", function()
        it("allows to add missions", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            station:addMission(missionWithBrokerMock())
            assert.is_same(1, Util.size(station:getMissions()))
            station:addMission(missionWithBrokerMock())
            assert.is_same(2, Util.size(station:getMissions()))
            station:addMission(missionWithBrokerMock())
            assert.is_same(3, Util.size(station:getMissions()))
        end)

        it("fails if the mission is not a brokerMission", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            assert.has_error(function() station:addMission(missionMock()) end)
        end)

        it("fails if the argument is a number", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            assert.has_error(function() station:addMission(42) end)
        end)
    end)

    describe(":removeMission()", function()
        it("allows to remove a mission object", function()
            local station = SpaceStation()
            local mission = missionWithBrokerMock()
            ShipTemplateBased:withMissionBroker(station, {missions = {mission}})

            assert.is_same(1, Util.size(station:getMissions()))
            station:removeMission(mission)
            assert.is_same(0, Util.size(station:getMissions()))
        end)

        it("allows to remove a mission by its id", function()
            local station = SpaceStation()
            local mission = missionWithBrokerMock()
            ShipTemplateBased:withMissionBroker(station, {missions = {mission}})

            assert.is_same(1, Util.size(station:getMissions()))
            station:removeMission(mission:getId())
            assert.is_same(0, Util.size(station:getMissions()))
        end)

        it("fails if the argument is a number", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            assert.has_error(function() station:removeMission(42) end)
        end)

        it("fails silently if the mission is unknown", function()
            local station = SpaceStation()
            local mission1 = missionWithBrokerMock()
            local mission2 = missionWithBrokerMock()
            ShipTemplateBased:withMissionBroker(station, {missions={mission1}})

            station:removeMission(mission2)
            assert.is_same(1, Util.size(station:getMissions()))
        end)
    end)

    describe(":getMissions()", function()
        it("returns an empty table if no missions where added", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            assert.is_same(0, Util.size(station:getMissions()))
        end)

        it("returns any missions added via withMissionBroker() and addMission()", function()
            local station = SpaceStation()
            local mission1 = missionWithBrokerMock()
            local mission2 = missionWithBrokerMock()
            ShipTemplateBased:withMissionBroker(station, {missions = {mission1}})
            station:addMission(mission2)

            local mission1Found = false
            local mission2Found = false

            for _, mission in pairs(station:getMissions()) do
                if mission == mission1 then mission1Found = true end
                if mission == mission2 then mission2Found = true end
            end

            assert.is_true(mission1Found)
            assert.is_true(mission2Found)
        end)

        it("should not allow to manipulate the mission table", function()
            local station = SpaceStation()
            local mission1 = missionWithBrokerMock()
            local mission2 = missionWithBrokerMock()
            ShipTemplateBased:withMissionBroker(station, {missions = {mission1}})

            table.insert(station:getMissions(), mission2)

            assert.is_same(1, Util.size(station:getMissions()))
        end)
    end)

    describe(":hasMissions()", function()
        it("returns false if no missions where added", function()
            local station = SpaceStation()
            ShipTemplateBased:withMissionBroker(station)

            assert.is_false(station:hasMissions())
        end)

        it("returns true if a mission has been added via withMissionBroker()", function()
            local station = SpaceStation()
            local mission = missionWithBrokerMock()
            ShipTemplateBased:withMissionBroker(station, {missions = {mission}})

            assert.is_true(station:hasMissions())
        end)

        it("returns true if a mission has been added via addMission()", function()
            local station = SpaceStation()
            local mission = missionWithBrokerMock()
            ShipTemplateBased:withMissionBroker(station)
            station:addMission(mission)

            assert.is_true(station:hasMissions())
        end)
    end)
end)