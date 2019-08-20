insulate("Mission", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local function newMission(config) return Mission:new(config) end
    local function acceptedMission(config)
        local mission =  Mission:new(config)
        mission:accept()
        return mission
    end
    local function declinedMission(config)
        local mission =  Mission:new(config)
        mission:decline()
        return mission
    end
    local function startedMission(config)
        local mission =  Mission:new(config)
        mission:accept()
        mission:start()
        return mission
    end
    local function successfulMission(config)
        local mission =  Mission:new(config)
        mission:accept()
        mission:start()
        mission:success()
        return mission
    end
    local function failedMission(config)
        local mission =  Mission:new(config)
        mission:accept()
        mission:start()
        mission:fail()
        return mission
    end

    describe(":new()", function()
        it("should create a valid Mission", function()
            local mission = Mission:new()

            assert.is_true(Mission:isMission(mission))
        end)

        it("allows to give config", function()
            local id = "foobar"
            local mission = Mission:new({id = id})

            assert.is_same(id, mission:getId())
            assert.is_true(Mission:isMission(mission))
        end)

        it("fails if the config is not a table", function()
            assert.has_error(function() Mission:new("thisBreaks") end)
        end)

        it("fails if acceptCondition is not a function", function()
            assert.has_error(function() Mission:new({acceptCondition = 42}) end)
        end)

        it("fails if onAccept is not a function", function()
            assert.has_error(function() Mission:new({onAccept = 42}) end)
        end)

        it("fails if onDecline is not a function", function()
            assert.has_error(function() Mission:new({onDecline = 42}) end)
        end)

        it("fails if onStart is not a function", function()
            assert.has_error(function() Mission:new({onStart = 42}) end)
        end)

        it("fails if onSuccess is not a function", function()
            assert.has_error(function() Mission:new({onSuccess = 42}) end)
        end)

        it("fails if onFailure is not a function", function()
            assert.has_error(function() Mission:new({onFailure = 42}) end)
        end)

        it("fails if onEnd is not a function", function()
            assert.has_error(function() Mission:new({onEnd = 42}) end)
        end)

        describe(":getId()", function()
            it("is set at random if none is given", function()
                local mission = Mission:new()

                assert.is_true(isString(mission:getId()))
                assert.is_not_same("", mission:getId())
            end)

            it("uses the given id", function()
                local id = "foobar"
                local mission = Mission:new({id = id})

                assert.is_same(id, mission:getId())
            end)
        end)

        describe(":getState()", function()
            local new = "new"
            local accepted = "accepted"
            local started = "started"
            local declined = "declined"
            local failed = "failed"
            local successful = "successful"

            it("returns \"" .. new .. "\" for a new mission", function()
                assert.is_same(new, newMission():getState())
            end)
            it("returns \"" .. accepted .. "\" for an accepted mission", function()
                assert.is_same(accepted, acceptedMission():getState())
            end)
            it("returns \"" .. started .. "\" for a started mission", function()
                assert.is_same(started, startedMission():getState())
            end)
            it("returns \"" .. declined .. "\" for a declined mission", function()
                assert.is_same(declined, declinedMission():getState())
            end)
            it("returns \"" .. failed .. "\" for a failed mission", function()
                assert.is_same(failed, failedMission():getState())
            end)
            it("returns \"" .. successful .. "\" for a successful mission", function()
                assert.is_same(successful, successfulMission():getState())
            end)
        end)

        describe(":canBeAccepted()", function()
            it("is true when no config is set", function()
                local mission = newMission()
                assert.is_true(mission:canBeAccepted())
            end)
        end)

        describe(":accept()", function()
            it ("switches to \"accepted\" if no callback is set", function()
                local mission = newMission()

                mission:accept()
                assert.is_same("accepted", mission:getState())
            end)
            it ("calls the onAccept callback", function()
                local callbackCalled = false
                local mission
                mission = newMission({onAccept = function(self)
                    assert.is_same(mission, self)
                    callbackCalled = true
                end})

                mission:accept()
                assert.is_true(callbackCalled)
            end)
            it("fails when acceptCondition callback returns false", function()
                local mission = newMission({acceptCondition = function() return false end})

                assert.has_error(function() mission:accept() end)
            end)
            it("fails when acceptCondition callback returns a string", function()
                local mission = newMission({acceptCondition = function() return "Just... No" end})

                assert.has_error(function() mission:accept() end)
            end)
            it("fails if onAccept callback fails", function()
                local mission = newMission({onAccept = function() error("boom") end})

                assert.has_error(function() mission:accept() end)
            end)
        end)

        describe(":decline()", function()
            it ("calls the onDecline callback", function()
                local callbackCalled = false
                local mission
                mission = newMission({onDecline = function(self)
                    assert.is_same(mission, self)
                    callbackCalled = true
                end})

                mission:decline()
                assert.is_true(callbackCalled)
            end)

            it("fails if onDecline callback fails", function()
                local mission = newMission({onDecline = function() error("boom") end})

                assert.has_error(function() mission:decline() end)
            end)
        end)

        describe(":start()", function()
            it ("calls the onStart callback", function()
                local callbackCalled = false
                local mission
                mission = acceptedMission({onStart = function(self)
                    assert.is_same(mission, self)
                    callbackCalled = true
                end})

                mission:start()
                assert.is_true(callbackCalled)
            end)

            it("fails if onDecline callback fails", function()
                local mission = acceptedMission({onStart = function() error("boom") end})

                assert.has_error(function() mission:start() end)
            end)
        end)

        describe(":fail()", function()
            it ("calls the onFailure callback and then the onEnd callback", function()
                local onFailure = false
                local onEndCalled = false

                local mission
                mission = startedMission({
                    onFailure = function(self)
                        assert.is_same(mission, self)
                        onFailure = true
                    end,
                    onEnd = function(self)
                        assert.is_same(mission, self)
                        assert.is_true(onFailure)
                        onEndCalled = true
                    end
                })

                mission:fail()
                assert.is_true(onFailure)
                assert.is_true(onEndCalled)
            end)

            it("fails if onFailure callback fails", function()
                local mission = startedMission({onFailure = function() error("boom") end})

                assert.has_error(function() mission:fail() end)
            end)

            it("fails if onEnd callback fails", function()
                local mission = startedMission({onEnd = function() error("boom") end})

                assert.has_error(function() mission:fail() end)
            end)
        end)

        describe(":success()", function()
            it ("calls the onSuccess callback and then the onEnd callback", function()
                local onSuccessCalled = false
                local onEndCalled = false

                local mission
                mission = startedMission({
                    onSuccess = function(self)
                        assert.is_same(mission, self)
                        onSuccessCalled = true
                    end,
                    onEnd = function(self)
                        assert.is_same(mission, self)
                        assert.is_true(onSuccessCalled)
                        onEndCalled = true
                    end
                })

                mission:success()
                assert.is_true(onSuccessCalled)
                assert.is_true(onEndCalled)
            end)

            it("fails if onSuccess callback fails", function()
                local mission = startedMission({onSuccess = function() error("boom") end})

                assert.has_error(function() mission:success() end)
            end)

            it("fails if onEnd callback fails", function()
                local mission = startedMission({onEnd = function() error("boom") end})

                assert.has_error(function() mission:success() end)
            end)
        end)

        describe("state machine", function()
            local testData = {
                {newMission(),        "accept",  true},
                {newMission(),        "decline", true},
                {newMission(),        "start",   false},
                {newMission(),        "fail",    false},
                {newMission(),        "success", false},
                {acceptedMission(),   "accept",  false},
                {acceptedMission(),   "decline", false},
                {acceptedMission(),   "start",   true},
                {acceptedMission(),   "fail",    false},
                {acceptedMission(),   "success", false},
                {declinedMission(),   "accept",  false},
                {declinedMission(),   "decline", false},
                {declinedMission(),   "start",   false},
                {declinedMission(),   "fail",    false},
                {declinedMission(),   "success", false},
                {startedMission(),    "accept",  false},
                {startedMission(),    "decline", false},
                {startedMission(),    "start",   false},
                {startedMission(),    "fail",    true},
                {startedMission(),    "success", true},
                {successfulMission(), "accept",  false},
                {successfulMission(), "decline", false},
                {successfulMission(), "start",   false},
                {successfulMission(), "fail",    false},
                {successfulMission(), "success", false},
                {failedMission(),     "accept",  false},
                {failedMission(),     "decline", false},
                {failedMission(),     "start",   false},
                {failedMission(),     "fail",    false},
                {failedMission(),     "success", false},
            }

            for _, test in pairs(testData) do
                local mission, funcName, success = table.unpack(test)
                if success then
                    it("allows to call " .. funcName .. " on a mission in state " .. mission:getState(), function()
                        mission[funcName](mission) -- it should not error
                    end)
                else
                    it("prevents calls to " .. funcName .. " on a mission in state " .. mission:getState(), function()
                        assert.has_error(function()
                            mission[funcName](mission)
                        end)
                    end)
                end
            end

        end)
    end)

    describe(":registerMissionCreationListener()", function()
        it("fires when mission is created", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionCreationListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            assert.is_false(eventCalled)

            local mission = Mission:new()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
    end)
    describe(":registerMissionAcceptListener()", function()
        it("fires when mission is accepted", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionAcceptListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            local mission = Mission:new()

            assert.is_false(eventCalled)

            mission:accept()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
    end)
    describe(":registerMissionDeclineListener()", function()
        it("fires when mission is declined", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionDeclineListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            local mission = Mission:new()

            assert.is_false(eventCalled)

            mission:decline()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
    end)
    describe(":registerMissionStartListener()", function()
        it("fires when mission is started", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionStartListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            local mission = Mission:new()
            mission:accept()

            assert.is_false(eventCalled)

            mission:start()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
    end)
    describe(":registerMissionSuccessListener()", function()
        it("fires when mission is successful", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionSuccessListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            local mission = Mission:new()
            mission:accept()
            mission:start()

            assert.is_false(eventCalled)

            mission:success()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
    end)
    describe(":registerMissionFailureListener()", function()
        it("fires when mission is fails", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionFailureListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            local mission = Mission:new()
            mission:accept()
            mission:start()

            assert.is_false(eventCalled)

            mission:fail()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
    end)
    describe(":registerMissionEndListener()", function()
        it("fires when mission is successful", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionEndListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            local mission = Mission:new()
            mission:accept()
            mission:start()

            assert.is_false(eventCalled)

            mission:success()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
        it("fires when mission is fails", function()
            local eventCalled = false
            local calledArg1
            Mission:registerMissionEndListener(function(_, arg1)
                eventCalled = true
                calledArg1 = arg1
            end)

            local mission = Mission:new()
            mission:accept()
            mission:start()

            assert.is_false(eventCalled)

            mission:fail()

            assert.is_true(eventCalled)
            assert.is_same(mission, calledArg1)
        end)
    end)
end)