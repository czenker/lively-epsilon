insulate("Narrative", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("newRepository()", function()
        it("creates a valid repository", function()
            local repo = Narrative:newRepository()
            assert.is_true(Narrative:isRepository(repo))
        end)
    end)

    describe("addNarrative(narrativeMock())", function()
        it("allows to add a new narrative", function()
            local repo = Narrative:newRepository()
            repo:addNarrative(narrativeMock())
        end)
        it("fails if the config is a number", function()
            local repo = Narrative:newRepository()

            assert.has_error(function()
                repo:addNarrative(42)
            end)
        end)
        it("generates an id for the narrative", function()
            local repo = Narrative:newRepository()
            local id = repo:addNarrative(narrativeMock())

            assert.is_true(isString(id))
            assert.not_same("", id)
        end)
        it("allows to give an id", function()
            local repo = Narrative:newRepository()
            local id = repo:addNarrative(narrativeMock(), "foobar")

            assert.is_same("foobar", id)
        end)
        it("fails if the id is a number", function()
            local repo = Narrative:newRepository()

            assert.has_error(function()
                repo:addNarrative(narrativeMock(), 42)
            end)
        end)
    end)

    describe("countNarratives()", function()
        it("returns 0 if a repo has no narratives", function()
            local repo = Narrative:newRepository()

            assert.is_same(0, repo:countNarratives())
        end)
        it("correctly counts the narratives", function()
            local repo = Narrative:newRepository()
            repo:addNarrative(narrativeMock())
            repo:addNarrative(narrativeMock())
            repo:addNarrative(narrativeMock())

            assert.is_same(3, repo:countNarratives())
        end)
    end)

    describe("addStation()", function()
        it("allows to add a station", function()
            local repo = Narrative:newRepository()
            local station = eeStationMock()

            repo:addStation(station)
        end)
        it("fails if no station is given", function()
            local repo = Narrative:newRepository()

            assert.has_error(function()
                repo:addStation()
            end)
        end)
        it("fails if station is a number", function()
            local repo = Narrative:newRepository()

            assert.has_error(function()
                repo:addStation(42)
            end)
        end)
    end)

    describe("countStations()", function()
        it("returns 0 if a repo has no stations assigned", function()
            local repo = Narrative:newRepository()

            assert.is_same(0, repo:countStations())
        end)
        it("correctly counts the stations", function()
            local repo = Narrative:newRepository()
            repo:addStation(eeStationMock())
            repo:addStation(eeStationMock())
            repo:addStation(eeStationMock())

            assert.is_same(3, repo:countStations())
        end)
    end)

    describe("findOne()", function()
        it("returns a narrative with concrete sources and destinations", function()
            local repo = Narrative:newRepository()
            repo:addNarrative(narrativeMock())
            repo:addStation(eeStationMock())
            repo:addStation(eeStationMock())

            for i=1,10 do
                -- algorithm is randomized - so do it multiple times
                local narrative = repo:findOne()
                assert.is_table(narrative)
                assert.is_true(isEeStation(narrative.from))
                assert.is_true(isEeStation(narrative.to))
                assert.not_same(narrative.from, narrative.to)
            end

        end)
        it("returns nil if no narratives are set", function()
            local repo = Narrative:newRepository()
            repo:addStation(eeStationMock())
            repo:addStation(eeStationMock())

            assert.is_nil(repo:findOne())
        end)
        it("returns nil if no stations are set", function()
            local repo = Narrative:newRepository()
            repo:addNarrative(narrativeMock())

            assert.is_nil(repo:findOne())
        end)
        it("returns different narratives with different stations selected", function()
            local narrative1 = narrativeMock("Narrative One")
            local narrative2 = narrativeMock("Narrative Two")
            local narrative3 = narrativeMock("Narrative Three")
            local station1 = eeStationMock()
            local station2 = eeStationMock()
            local station3 = eeStationMock()

            local repo = Narrative:newRepository()
            repo:addNarrative(narrative1)
            repo:addNarrative(narrative2)
            repo:addNarrative(narrative3)
            repo:addStation(station1)
            repo:addStation(station2)
            repo:addStation(station3)

            local n1Seen = false
            local n2Seen = false
            local n3Seen = false
            local s1SeenAsFrom = false
            local s2SeenAsFrom = false
            local s3SeenAsFrom = false
            local s1SeenAsTo = false
            local s2SeenAsTo = false
            local s3SeenAsTo = false

            for i=1,50 do
                local narrative = repo:findOne()
                if narrative.name == "Narrative One" then n1Seen = true end
                if narrative.name == "Narrative Two" then n2Seen = true end
                if narrative.name == "Narrative Three" then n3Seen = true end
                if narrative.from == station1 then s1SeenAsFrom = true end
                if narrative.from == station2 then s2SeenAsFrom = true end
                if narrative.from == station3 then s3SeenAsFrom = true end
                if narrative.to == station1 then s1SeenAsTo = true end
                if narrative.to == station2 then s2SeenAsTo = true end
                if narrative.to == station3 then s3SeenAsTo = true end
            end

            assert.is_true(n1Seen)
            assert.is_true(n2Seen)
            assert.is_true(n3Seen)
            assert.is_true(s1SeenAsFrom)
            assert.is_true(s2SeenAsFrom)
            assert.is_true(s3SeenAsFrom)
            assert.is_true(s1SeenAsTo)
            assert.is_true(s2SeenAsTo)
            assert.is_true(s3SeenAsTo)
        end)
        describe("filters", function()
            describe("by tags", function()
                it("filters by a single tag", function()
                    local narrative = narrativeMock("Narrative One")
                    narrative.from = {
                        tags = "foo"
                    }
                    narrative.to = {
                        tags = "bar"
                    }
                    local stationFrom = eeStationMock()
                    Station:withTags(stationFrom, "foo", "baz")
                    local stationTo = eeStationMock()
                    Station:withTags(stationTo, "bar", "baz")
                    local stationWithoutTags = eeStationMock()
                    local stationWithNoTags = eeStationMock()
                    Station:withTags(stationWithNoTags)
                    local stationWithDifferentTags = eeStationMock()
                    Station:withTags(stationWithDifferentTags, "baz", "blubber")

                    local repo = Narrative:newRepository()
                    repo:addNarrative(narrative)
                    repo:addStation(stationFrom)
                    repo:addStation(stationTo)
                    repo:addStation(stationWithoutTags)
                    repo:addStation(stationWithNoTags)
                    repo:addStation(stationWithDifferentTags)

                    for i=1,10 do
                        local n = repo:findOne()
                        assert.is_same(stationFrom, n.from)
                        assert.is_same(stationTo, n.to)
                    end

                end)
                it("filters by multiple tags", function()
                    local narrative = narrativeMock("Narrative One")
                    narrative.from = {
                        tags = {"foo", "bar"}
                    }
                    narrative.to = {
                        tags = {"bar", "baz"}
                    }
                    local stationFrom = eeStationMock()
                    Station:withTags(stationFrom, "foo", "bar", "one")
                    local stationTo = eeStationMock()
                    Station:withTags(stationTo, "bar", "baz", "one")
                    local stationWithoutTags = eeStationMock()
                    local stationWithNoTags = eeStationMock()
                    Station:withTags(stationWithNoTags)
                    local stationWithDifferentTags = eeStationMock()
                    Station:withTags(stationWithDifferentTags, "blubber")
                    local stationWithOnlyOneTag = eeStationMock()
                    Station:withTags(stationWithOnlyOneTag, "bar")

                    local repo = Narrative:newRepository()
                    repo:addNarrative(narrative)
                    repo:addStation(stationFrom)
                    repo:addStation(stationTo)
                    repo:addStation(stationWithoutTags)
                    repo:addStation(stationWithNoTags)
                    repo:addStation(stationWithDifferentTags)
                    repo:addStation(stationWithOnlyOneTag)

                    for i=1,10 do
                        local n = repo:findOne()
                        assert.is_same(stationFrom, n.from)
                        assert.is_same(stationTo, n.to)
                    end

                end)
            end)
        end)
    end)

end)