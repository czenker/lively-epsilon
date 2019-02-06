insulate("Missions:answer", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":answer()", function()
        it("should create a valid Mission with one station", function()
            local station = SpaceStation()
            Station:withComms(station)

            local mission = Missions:answer(
                station,
                "What is the answer to my question?",
                "I want to answer your question.", {
                    rightAnswer = "42",
                    correctAnswerResponse = "You are right.",
                    wrongAnswers = { "I don't know", "Yes", "No" },
                    wrongAnswerResponse = "You are wrong.",
                }
            )

            assert.is_true(Mission:isMission(mission))
        end)
    end)
end)