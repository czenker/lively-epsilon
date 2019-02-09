Missions = Missions or {}

--- Someone asks a question and the crew needs to give the correct answer.
---
--- How they come to the conclusion does not really matter. It could be a riddle, something to observe, a reward by the GM after role playing or they might even guess the correct answer.
---
--- @param self
--- @param commable ShipTemplateBased where to give the answer
--- @param question string|function
--- @param playerSays string|function
--- @param config table
---   @field acceptCondition function gets `self` as arguments. should return `true` or `false` whether the mission can be accepted
---   @field onAccept function gets `self` as argument
---   @field onDecline function gets `self` as argument
---   @field onStart function gets `self` as argument
---   @field correctAnswer string|function|nil
---   @field wrongAnswers table[string]|function
---   @field backLabel string|nil|function the label if you do not want to give an answer right now
---   @field correctAnswerResponse string|function what is said when the answer is correct
---   @field wrongAnswerResponse string|function what is said when the answer is wrong
---   @field onSuccess function gets `self` as argument
---   @field onFailure function gets `self` as argument
---   @field onEnd function gets `self` as argument
--- @return Mission
Missions.answer = function(self, commable, question, playerSays, config)
    if not isEeShipTemplateBased(commable) then error("Expected commable to be a ship or station, but got " .. typeInspect(commable), 2) end
    if not ShipTemplateBased:hasComms(commable) then error("Expected commable to have comms, but it does not.", 2) end

    if not isString(question) and not isFunction(question) then
        error("Expected question to be a string or function, but got " .. typeInspect(question), 2)
    end
    if not isString(playerSays) and not isFunction(playerSays) then
        error("Expected playerSays to be a string or function, but got " .. typeInspect(playerSays), 2)
    end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end
    if not isNil(config.correctAnswer) and not isFunction(config.correctAnswer) and not isString(config.correctAnswer) then
        error("Expected correctAnswer to be nil, a string or function, but got " .. typeInspect(config.correctAnswer), 2)
    end
    if isTable(config.wrongAnswers) then
        for i,answer in pairs(config.wrongAnswers) do
            if not isString(answer) then error("Expected wrong answer " .. i .. " to be a string, but got " .. typeInspect(answer), 4) end
        end
    elseif not isFunction(config.wrongAnswers) then
        error("Expected wrongAnswers to be a table or function, but got " .. typeInspect(config.wrongAnswers), 2)
    end
    --if not isNil(config.abortAnswer) and not isString(config.abortAnswer) and not isFunction(config.abortAnswer) then
    --    error("Expected abortAnswer to be nil, a string or function, but got " .. typeInspect(config.abortAnswer), 2)
    --end
    if not isNil(config.backLabel) and not isString(config.backLabel) and not isFunction(config.backLabel) then
        error("Expected backLabel to be nil, a string or function, but got " .. typeInspect(config.backLabel), 2)
    end
    if not isString(config.correctAnswerResponse) and not isFunction(config.correctAnswerResponse) then
        error("Expected correctAnswerResponse to be a string or function, but got " .. typeInspect(config.correctAnswerResponse), 2)
    end
    if not isString(config.wrongAnswerResponse) and not isFunction(config.wrongAnswerResponse) then
        error("Expected wrongAnswerResponse to be a string or function, but got " .. typeInspect(config.wrongAnswerResponse), 2)
    end
    --if not isNil(config.abortAnswerResponse) and not isString(config.abortAnswerResponse) and not isFunction(config.abortAnswerResponse) then
    --    error("Expected abortAnswerResponse to be nil, a string or function, but got " .. typeInspect(config.abortAnswerResponse), 2)
    --end

    local commsId = "mission_answer_" .. Util.randomUuid()
    local cronId = "mission_answer_" .. Util.randomUuid()

    local mission

    local correctScreen = function(answer)
        return function(self, station, player)
            local responseText = config.correctAnswerResponse
            if isFunction(config.correctAnswerResponse) then
                userCallback(config.correctAnswerResponse, mission, answer, player)
            end

            mission:success()
            return Comms:newScreen(responseText)
        end
    end
    local wrongScreen = function(answer)
        return function(self, station, player)
            local responseText = config.wrongAnswerResponse
            if isFunction(config.wrongAnswerResponse) then
                userCallback(config.wrongAnswerResponse, mission, answer, player)
            end

            mission:fail()
            return Comms:newScreen(responseText)
        end
    end

    local questionScreen = function(self, station, player)
        local questionText
        if isFunction(question) then
            questionText = question(mission, player)
        elseif isString(question) then
            questionText = question
        end
        local screen = Comms:newScreen(questionText)

        -- add all the wrong answers
        local wrongAnswers = {}
        if isTable(config.wrongAnswers) then
            wrongAnswers = config.wrongAnswers
        elseif isFunction(config.wrongAnswers) then
            wrongAnswers = config.wrongAnswers(mission)
            if not isTable(wrongAnswers) then
                logError("Expected answers to be a table, but got " .. typeInspect(wrongAnswers) .. ". Assuming nil.")
                wrongAnswers = {}
            end
        end

        local replies = {}
        for i, answer in pairs(wrongAnswers) do
            if isString(answer) then
                table.insert(replies, Comms:newReply(answer, wrongScreen(answer)))
            else
                logError("Ignoring answer " .. i .. ", because it was expected to be a string, but got " .. typeInspect(answer))
            end
        end

        -- add the right answer
        local correctAnswer
        if isString(config.correctAnswer) then
            correctAnswer = config.correctAnswer
        elseif isFunction(config.correctAnswer) then
            correctAnswer = config.correctAnswer(mission)
            if not isNil(correctAnswer) and not isString(correctAnswer) then
                logError("Expected correct answer to be nil or string, but got " .. typeInspect(correctAnswer) .. ". Assuming nil.")
                correctAnswer = nil
            end
        end
        if isString(correctAnswer) then
            table.insert(replies, Comms:newReply(correctAnswer, correctScreen(correctAnswer)))
        end

        -- give it a good shuffle
        replies = Util.randomSort(replies)

        -- add back button
        local backLabel
        if isString(config.backLabel) then
            backLabel = config.backLabel
        elseif isFunction(config.backLabel) then
            backLabel = config.backLabel(mission)
            if not isNil(backLabel) and not isString(backLabel) then
                logError("Expected backLabel to be nil or string, but got " .. typeInspect(backLabel) .. ". Assuming nil.")
                backLabel = nil
            end
        end
        if isString(backLabel) then
            table.insert(replies, Comms:newReply(backLabel))
        end

        for _,reply in pairs(replies) do
            screen:addReply(reply)
        end

        return screen
    end

    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(config.onStart) then config.onStart(self) end

            local playerText
            if isFunction(playerSays) then
                playerText = playerSays(self)
                if not isString(playerText) then logError("Expected playerSays to return a string, but got " .. typeInspect(playerText)) end
            elseif isString(playerSays) then
                playerText = playerSays
            end

            Cron.regular(cronId, function()
                if not commable:isValid() then mission:fail() end
            end, 1)

            commable:addComms(Comms:newReply(playerText, questionScreen), commsId)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            if commable:isValid() then commable:removeComms(commsId) end
            Cron.abort(cronId)
            if isFunction(config.onEnd) then config.onEnd(self) end
        end,
    })

    --- get the place where to give the answer
    --- @param self
    --- @return ShipTemplateBased
    mission.getCommable = function(self)
        return commable
    end

    return mission
end