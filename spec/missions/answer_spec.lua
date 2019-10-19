insulate("Missions:answer()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("should create a valid Mission with one station and a guessing game", function()
        local station = SpaceStation()
        Station:withComms(station)

        local mission = Missions:answer(
            station,
            "What is the answer to my question?",
            "I want to answer your question.", {
                correctAnswer = "42",
                correctAnswerResponse = "You are right.",
                wrongAnswers = { "I don't know", "Yes", "No" },
                wrongAnswerResponse = "You are wrong.",
            }
        )

        assert.is_true(Mission:isMission(mission))

        local player = PlayerSpaceship()

        player:commandOpenTextComm(station)
        assert.is_false(player:hasComms("I want to answer your question."))
        player:commandCloseTextComm(station)

        mission:accept()
        mission:start()

        player:commandOpenTextComm(station)
        assert.is_true(player:hasComms("I want to answer your question."))
        player:selectComms("I want to answer your question.")

        assert.is_same("What is the answer to my question?", player:getCurrentCommsText())
        assert.is_true(player:hasComms("42"))
        assert.is_true(player:hasComms("I don't know"))
        assert.is_true(player:hasComms("Yes"))
        assert.is_true(player:hasComms("No"))

        player:commandCloseTextComm(station)
    end)

    it("mission fails if the wrong answer is given", function()
        local station = SpaceStation()
        Station:withComms(station)

        local mission = Missions:answer(
                station,
                "What is the answer to my question?",
                "I want to answer your question.", {
                    correctAnswer = "42",
                    correctAnswerResponse = "You are right.",
                    wrongAnswers = { "I don't know", "Yes", "No" },
                    wrongAnswerResponse = "You are wrong.",
                }
        )

        assert.is_true(Mission:isMission(mission))
        mission:accept()
        mission:start()

        local player = PlayerSpaceship()
        player:commandOpenTextComm(station)
        assert.is_true(player:hasComms("I want to answer your question."))
        player:selectComms("I want to answer your question.")
        assert.is_same("What is the answer to my question?", player:getCurrentCommsText())
        player:selectComms("Yes")
        assert.is_same("You are wrong.", player:getCurrentCommsText())

        assert.is_same("failed", mission:getState())
        player:commandCloseTextComm(station)
    end)

    it("mission is successful if the correct answer is given", function()
        local station = SpaceStation()
        Station:withComms(station)

        local mission = Missions:answer(
                station,
                "What is the answer to my question?",
                "I want to answer your question.", {
                    correctAnswer = "42",
                    correctAnswerResponse = "You are right.",
                    wrongAnswers = { "I don't know", "Yes", "No" },
                    wrongAnswerResponse = "You are wrong.",
                }
        )

        assert.is_true(Mission:isMission(mission))
        mission:accept()
        mission:start()

        local player = PlayerSpaceship()
        player:commandOpenTextComm(station)
        assert.is_true(player:hasComms("I want to answer your question."))
        player:selectComms("I want to answer your question.")
        assert.is_same("What is the answer to my question?", player:getCurrentCommsText())
        player:selectComms("42")
        assert.is_same("You are right.", player:getCurrentCommsText())

        assert.is_same("successful", mission:getState())
        player:commandCloseTextComm(station)
    end)

    it("is possible to enable the right answer through a function", function()
        local station = SpaceStation()
        Station:withComms(station)
        local correctAnswer = nil

        local mission = Missions:answer(
                station,
                "What is my name?",
                "I want to answer your question.", {
                    correctAnswer = function() return correctAnswer end,
                    correctAnswerResponse = "You are right.",
                    wrongAnswers = { "Paul", "Klaus", "Hans" },
                    wrongAnswerResponse = "You are wrong.",
                }
        )

        assert.is_true(Mission:isMission(mission))
        mission:accept()
        mission:start()

        local player = PlayerSpaceship()
        player:commandOpenTextComm(station)
        player:selectComms("I want to answer your question.")
        assert.is_same("What is my name?", player:getCurrentCommsText())
        assert.is_true(player:hasComms("Paul"))
        assert.is_true(player:hasComms("Klaus"))
        assert.is_true(player:hasComms("Hans"))
        assert.is_false(player:hasComms("Rumpelstiltskin"))
        player:commandCloseTextComm(station)

        correctAnswer = "Rumpelstiltskin"
        player:commandOpenTextComm(station)
        player:selectComms("I want to answer your question.")
        assert.is_same("What is my name?", player:getCurrentCommsText())
        assert.is_true(player:hasComms("Rumpelstiltskin"))
        player:selectComms("Rumpelstiltskin")
        player:commandCloseTextComm(station)
    end)

    it("can have dynamic questions and answers", function()
        local station = SpaceStation():setCallSign("Station")
        local player = PlayerSpaceship():setCallSign("Player")
        Station:withComms(station)

        local questionCallArg1, questionCallArg2
        local correctAnswerCallArg1, correctAnswerCallArg2
        local wrongAnswerCallArg1, wrongAnswerCallArg2

        local mission = Missions:answer(
                station,
                function(arg1, arg2)
                    questionCallArg1, questionCallArg2 = arg1, arg2
                    return "What is your ships call sign?"
                end,
                "I want to answer your question.", {
                    correctAnswer = function(arg1, arg2)
                        correctAnswerCallArg1, correctAnswerCallArg2 = arg1, arg2
                        return arg2:getCallSign()
                    end,
                    correctAnswerResponse = "You are right.",
                    wrongAnswers = function(arg1, arg2)
                        wrongAnswerCallArg1, wrongAnswerCallArg2 = arg1, arg2
                        return {
                            "Not " .. arg2:getCallSign()
                        }
                    end,
                    wrongAnswerResponse = "You are wrong.",
                }
        )

        assert.is_true(Mission:isMission(mission))
        mission:accept()
        mission:start()

        player:commandOpenTextComm(station)
        player:selectComms("I want to answer your question.")
        assert.is_same(mission, questionCallArg1)
        assert.is_same(player, questionCallArg2)
        assert.is_same("What is your ships call sign?", player:getCurrentCommsText())
        assert.is_same(mission, correctAnswerCallArg1)
        assert.is_same(player, correctAnswerCallArg2)
        assert.is_same(mission, wrongAnswerCallArg1)
        assert.is_same(player, wrongAnswerCallArg2)
        player:commandCloseTextComm(station)
    end)
end)