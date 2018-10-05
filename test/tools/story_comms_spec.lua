insulate("Tools", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("storyComms()", function()
        insulate("valid call", function()
            require "lively_epsilon"
            require "test.mocks"

            it("can be created", function()
                finally(function() Tools:endStoryComms() end)

                local station = eeStationMock()
                Station:withComms(station)
                local player = eePlayerMock()
                local screen = commsScreenMock()
                Tools:storyComms(station, player, screen)
            end)
        end)
        insulate("valid call", function()
            randomize(false)
            require "lively_epsilon"
            require "test.mocks"

            local station = eeStationMock()
            Station:withComms(station)
            local player = eePlayerMock()
            local screen = commsScreenMock()

            it("can be created", function()
                finally(function() Tools:endStoryComms() end)

                Tools:storyComms(station, player, screen)
            end)

            it("can be stopped and started again", function()
                finally(function() Tools:endStoryComms() end)

                Tools:endStoryComms()
                Tools:storyComms(station, player, screen)
            end)
        end)
        insulate("invalid calls", function()
            require "lively_epsilon"
            require "test.mocks"

            local station = eeStationMock()
            Station:withComms(station)
            local player = eePlayerMock()
            local screen = commsScreenMock()

            it("fails when called without station", function()
                assert.has_error(function() Tools:storyComms(nil, player, screen) end)
            end)
            it("fails when called with station without comms", function()
                assert.has_error(function() Tools:storyComms(eeStationMock(), player, screen) end)
            end)
            it("fails when called without player", function()
                assert.has_error(function() Tools:storyComms(station, nil, screen) end)
            end)
            it("fails when called without screen", function()
                assert.has_error(function() Tools:storyComms(station, player, nil) end)
            end)
            it("fails when an other storyComms() is currently running", function()
                finally(function() Tools:endStoryComms() end)
                
                Tools:storyComms(station, player, screen)
                assert.has_error(function() Tools:storyComms(station, player, screen) end)
            end)
        end)
    end)
end)