insulate("documentation on Mission", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        withUniverse(function()
            local player = PlayerSpaceship()
            -- tag::basic[]
            local mission = Mission:new({
                onStart = function()
                    print("The mission was started.")
                end,
                onSuccess = function()
                    player:addToShipLog("Mission successful")
                end,
            })
            -- end::basic[]

            mission:accept()
            mission:start()
            mission:success()
        end)
    end)
    it("chain", function()
        withUniverse(function()
            -- tag::chain[]
            local subMission1 = Mission:new({})
            local subMission2 = Mission:new({})

            local mission = Mission:chain(subMission1, subMission2)

            mission:accept()
            -- this starts subMission1
            mission:start()
            -- end::chain[]
            assert.is_same("started", subMission1:getState())
            -- tag::chain[]

            -- this will start subMission2
            subMission1:success()
            -- end::chain[]
            assert.is_same("successful", subMission1:getState())
            assert.is_same("started", subMission2:getState())
            -- tag::chain[]

            -- this will mark the mission as successful
            subMission2:success()
            -- end::chain[]
            assert.is_same("successful", subMission2:getState())
            assert.is_same("successful", mission:getState())
        end)
    end)
    it("allOf", function()
        withUniverse(function()
            -- tag::allOf[]
            local subMission1 = Mission:new({})
            local subMission2 = Mission:new({})

            local mission = Mission:allOf(subMission1, subMission2)

            mission:accept()
            -- this starts subMission1 and subMission2
            mission:start()
            -- end::allOf[]
            assert.is_same("started", subMission1:getState())
            assert.is_same("started", subMission2:getState())
            -- tag::allOf[]

            -- this will not yet finish the mission
            subMission1:success()
            -- end::allOf[]
            assert.is_same("successful", subMission1:getState())
            assert.is_same("started", subMission2:getState())
            assert.is_same("started", mission:getState())
            -- tag::allOf[]

            -- this will mark the mission as successful
            subMission2:success()
            -- end::allOf[]
            assert.is_same("successful", subMission2:getState())
            assert.is_same("successful", mission:getState())
        end)
    end)
    it("forPlayer", function()
        withUniverse(function()
            -- tag::for-player[]
            local player = PlayerSpaceship()
            local mission = Mission:new()
            Mission:forPlayer(mission, player)
            -- end::for-player[]

            mission:accept()
            mission:start()
            mission:success()
        end)
    end)
    it("withBroker", function()
        withUniverse(function()
            -- tag::with-broker[]
            local station = SpaceStation()
            local mission = Mission:new()
            Mission:withBroker(mission, "Title of the mission", {
                description = "Help " .. station:getCallSign() .. " solve their problems",
                missionBroker = station
            })
            -- end::with-broker[]

            mission:accept()
            mission:start()
            mission:success()
        end)
    end)
    it("withTimelimit", function()
        withUniverse(function()
            -- tag::with-timeLimit[]
            local station = SpaceStation()
            local mission = Mission:new()
            Mission:withTimeLimit(mission, 600) -- in seconds
            -- end::with-timeLimit[]

            mission:accept()
            mission:start()

            for _=1,599 do
                Cron.tick(1)
            end

            assert.is_same("started", mission:getState())
            Cron.tick(2)
            assert.is_same("failed", mission:getState())
        end)
    end)
end)