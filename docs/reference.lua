if type(arg[1]) ~= "string" then error("Expected an output file name as first argument to " .. arg[0]) end

require "init"
require "spec/mocks"

local ship = CpuShip():setCallSign("Ghost")
local player = PlayerSpaceship():setCallSign("USC Spaceship")
local station = SpaceStation():setCallSign("Nowhere")

local returnValues = {
    EventHandler_new = EventHandler:new(),
    Menu_new = Menu:new(),
    Menu_newItem = Menu:newItem("Click Me"),
    Generic_withTags = Generic:withTags(ship),
    Fleet_new = Fleet:new({}),
    Order_attack = Order:attack(ship),
    Order_defend = Order:defend(ship),
    Order_dock = Order:dock(station),
    Order_flyTo = Order:flyTo(1000, 0),
    Order_roaming = Order:roaming(),
    Mission_new = Mission:new(),
    Mission_withBroker = Mission:withBroker(Mission:new(), "Foobar"),
    Mission_forPlayer = Mission:forPlayer(Mission:new(), player),
    Ship_withFleet = Ship:withFleet(CpuShip(), Fleet:new({})),
    Ship_withOrderQueue = Ship:withOrderQueue(CpuShip()),
    Fleet_withOrderQueue = Fleet:withOrderQueue(Fleet:new({})),
    Chatter_new = Chatter:new(),
    Chatter_newFactory = Chatter:newFactory(1, function() end),
    Chatter_newNoise = Chatter:newNoise(Chatter:new()),
    Comms_screen = Comms.screen("", {}),
    Player_withMenu = Player:withMenu(PlayerSpaceship()),
    Player_withMissionTracker = Player:withMissionTracker(PlayerSpaceship()),
    Player_withStorage = Player:withStorage(PlayerSpaceship()),
    Player_withUpgradeTracker = Player:withUpgradeTracker(PlayerSpaceship()),
    ShipTemplateBased_withComms = ShipTemplateBased:withComms(CpuShip()),
    ShipTemplateBased_withCrew = ShipTemplateBased:withCrew(CpuShip()),
    ShipTemplateBased_withMissionBroker = ShipTemplateBased:withMissionBroker(CpuShip()),
    ShipTemplateBased_withStorageRooms = ShipTemplateBased:withStorageRooms(SpaceStation(), {}),
    ShipTemplateBased_withUpgradeBroker = ShipTemplateBased:withUpgradeBroker(SpaceStation()),
    Station_withMerchant = Station:withMerchant(Station:withStorageRooms(SpaceStation(), {}), {}),
    Station_withProduction = Station:withProduction(Station:withStorageRooms(SpaceStation(), {}), {}),
    Station_withProduction = Station:withProduction(Station:withStorageRooms(SpaceStation(), {}), {}),
    BrokerUpgrade_new = BrokerUpgrade:new({name="Foobar"}),
    Person_byName = Person:byName("John Doe"),
    Product_new = Product:new("Unobtainium"),
    Missions_answer = Missions:answer(Station:withComms(SpaceStation()), "Who are you?", "I want to answer", {
        wrongAnswers = {},
        correctAnswerResponse = "",
        wrongAnswerResponse = "",
    }),
    Missions_bringProduct = Missions:bringProduct(Station:withComms(SpaceStation()), {
        product = Product:new(""),
    }),
    Missions_capture = Missions:capture(CpuShip(), {}),
    Missions_crewForRent = Missions:crewForRent(CpuShip(), {}),
    Missions_destroy = Missions:destroy(CpuShip(), {}),
    Missions_disable = Missions:disable(CpuShip(), {}),
    Missions_pickUp = Missions:pickUp(Artifact()),
    Missions_scan = Missions:scan(CpuShip()),
    Missions_transportProduct = Missions:transportProduct(SpaceStation(), SpaceStation(), Product:new("")),
    Missions_transportToken = Missions:transportToken(SpaceStation(), SpaceStation()),
    Missions_visit = Missions:visit(SpaceStation()),
    Translator_new = Translator:new(),
}

local data = {
    "Missions",
    "Product",
    "Person",
    "BrokerUpgrade",
    "Station",
    "ShipTemplateBased",
    "Player",
    "Comms",
    "Chatter",
    "Cron",
    "EventHandler",
    "Util",
    "Menu",
    "Generic",
    "Fleet",
    "Order",
    "Tools",
    "Ship",
    "Mission",
    "Translator",
}
table.sort(data)

local indexFilePath = arg[1]
local indexFile = io.open(indexFilePath, "w+")

indexFile:write(":attribute-missing: warn", "\n")
indexFile:write(":attribute-undefined: drop", "\n")
indexFile:write(":source-highlighter: coderay", "\n")
indexFile:write("\n")
indexFile:write(":toc: left", "\n")
indexFile:write(":toclevels: 2", "\n")
indexFile:write(":icons: font", "\n")
indexFile:write("\n")
indexFile:write("= Lively Epsilon Reference", "\n")
indexFile:write("\n")

_G.LivelyEpsilonConfig = {
    useAnsi = true,
    logLevel = "DEBUG",
    logTime = false,
}

--- ----
---
--- parsing doc blocks
---
--- ----

local getDocComment = function(filePath, lineNr)
    local lines = {}

    local i = 1
    for line in io.lines(filePath) do
        lines[i] = line
        i = i + 1
    end

    local ret = {}
    for i = lineNr-1, 1, -1 do
        local hit = string.match(lines[i], "^%s*%-%-%-%s*(.*)")
        if hit ~= nil then
            table.insert(ret, 1, hit)
        else
            break
        end
    end

    return ret
end

local parseParamTag = function(line)
    local name, typ, description = line:match("^@[^%s]+%s+([^%s]+)%s*([^%s]*)%s*(.*)")
    if description == nil then error("Expected a well formed param tag, but did not get it.\n> " .. line) end
    if typ == "" then typ = nil end
    if description == "" then description = nil end

    return {
        name = name,
        type = typ,
        description = description,
    }
end
local parseReturnTag = function(line)
    local typ, description = line:match("^@[^%s]+%s+([^%s]+)%s*(.*)")
    if typ == nil then error("Expected a well formed return tag, but did not get it.\n> " .. line) end
    if description == "" then description = nil end

    return {
        type = typ,
        description = description,
    }
end
local parseDeprecatedOrInternalTag = function(line)
    local description = line:match("^@[^%s]+%s*(.*)")
    if description == nil then error("Expected a well formed deprecated tag, but did not get it.\n> " .. line) end
    if description == "" then description = nil end

    return description
end


local addSignatureToDocComment = function(docComment, functionLabel)
    -- generate the signature
    local signature = functionLabel or docComment.functionName
    local tableNotation
    local idx = signature:find("%.[^%.]*$")
    if idx ~= nil then
        tableNotation = signature:sub(idx+1)
    else
        tableNotation = signature
    end

    local tableNotation = tableNotation .. " = function("
    local arguments = docComment.arguments
    docComment.isSelfFunction = false

    if arguments[1] ~= nil and arguments[1].name == "self" then
        local idx = signature:find("%.[^%.]*$")
        if idx ~= nil then
            signature = signature:sub(1, idx-1) .. ":" .. signature:sub(idx+1)
            table.remove(arguments, 1)
            docComment.isSelfFunction = true
            tableNotation = tableNotation .. "self"
            if arguments[1] ~= nil then tableNotation = tableNotation .. ", " end
        end
    end

    signature = signature .. "("
    signature = signature .. table.concat(Util.map(arguments, function(arg) return arg.name end), ", ")
    tableNotation = tableNotation .. table.concat(Util.map(arguments, function(arg) return arg.name end), ", ") .. ") end,"
    signature = signature .. ")"

    if docComment.numberOfReturnValues == 1 then
        signature = "local " .. docComment.returns.type:sub(1,1):lower() .. " = " .. signature
    elseif docComment.numberOfReturnValues > 1 then
        local varNames = {}
        for i=1,docComment.numberOfReturnValues do
            varNames[i] = "r" .. i
        end
        signature = "local " .. Util.mkString(varNames, ", ") .. " = " .. signature
    end

    docComment.signature = signature
    docComment.tableSignature = tableNotation
    docComment.arguments = arguments

    return docComment
end

local parseDocComment = function(functionId, func, functionLabel)
    local info = debug.getinfo(func)
    local docBlockLines = getDocComment(info.short_src, info.linedefined)

    local ret = addSignatureToDocComment({
        functionName = functionId,
        description = "",
        arguments = {},
        isDeprecated = false,
        deprecatedMessage = nil,
        isInternal = false,
        internalMessage = nil,
        returns = nil,
        numberOfReturnValues = 0,
    })

    for _, line in pairs(docBlockLines) do
        if line:sub(1,1) == "@" then
            local tag = line:match("^@[^%s]+")
            if tag == "@param" then
                local param = parseParamTag(line)
                table.insert(ret.arguments, param)
            elseif tag == "@field" then
                if ret.arguments[#ret.arguments] == nil then error("@field has to follow a @param") end
                ret.arguments[#ret.arguments].sub = ret.arguments[#ret.arguments].sub or {}
                table.insert(ret.arguments[#ret.arguments].sub, parseParamTag(line))
            elseif tag == "@deprecated" then
                ret.isDeprecated = true
                ret.deprecatedMessage = parseDeprecatedOrInternalTag(line)
            elseif tag == "@return" then
                local returns = parseReturnTag(line)
                if returns.type == "nil" then
                    returns = nil
                else
                    local numberOfCommas = returns.type:len() - returns.type:gsub(",", ""):len()
                    ret.numberOfReturnValues = numberOfCommas + 1
                end

                ret.returns = returns
            elseif tag == "@see" then
                -- TODO: ignore for now
            elseif tag == "@internal" then
                ret.isInternal = true
                ret.internalMessage = parseDeprecatedOrInternalTag(line)
            else
                error("Expected a known tag, but got " .. tag)
            end
        else
            ret.description = ret.description .. line .. "\n"
        end
    end

    ret = addSignatureToDocComment(ret, functionLabel)

    local paramsCount = #ret.arguments
    if ret.isSelfFunction then paramsCount = paramsCount + 1 end
    if ret.arguments[#ret.arguments] ~= nil and ret.arguments[#ret.arguments].name == "..." then paramsCount = paramsCount - 1 end
    if paramsCount ~= info.nparams then
        error("Expected all " .. info.nparams .. " arguments to be documented, but got " .. paramsCount .. " in " .. functionId)
    end

    return ret
end


--- ----
---
--- documenting
---
--- ----

local function writeFuncArguments(arguments, indent)
    indent = indent or 0
    local prefix = string.rep(" ", indent * 4)
    local postfix = string.rep(":", indent)
    local doc = ""
    for _, arg in pairs(arguments) do
        if arg.type or arg.description then
            local argName = arg.name
            if argName == "..." then argName = "\\" .. argName .. " (multiple)" end
            doc = doc .. prefix .. argName .. "::" .. postfix .. "\n"
            if arg.type then doc = doc .. prefix .. "`" .. arg.type .. "` " end
            if arg.description then doc = doc .. prefix .. arg.description end
            doc = doc .. "\n"
            if arg.sub ~= nil then
                for _, subarg in pairs(arg.sub) do
                    doc = doc .. prefix .. "    " .. subarg.name .. ":::" .. postfix .. "\n"
                    if subarg.type then doc = doc .. prefix .. "    `" .. subarg.type .. "` " end
                    if subarg.description then doc = doc .. prefix .. "    " .. subarg.description end
                    doc = doc .. "\n"
                end
            end
        end
    end
    doc = doc .. "\n"

    return doc
end

local documentFunction
local documentTable = function(tableId, theTable, headingLevel, tableLabel)
    local keys = {}
    for k, v in pairs(theTable) do
        if isFunction(v) and debug.getinfo(v).short_src:find("src/") ~= nil then
            table.insert(keys, k)
        end
    end
    table.sort(keys)
    local slug = tableId:lower():gsub("%.", "-")
    local doc = "[[" .. slug .. "]]\n"
    doc = doc .. string.rep("=", headingLevel) .. " " .. (tableLabel or tableId) .. "\n\n"

    doc = doc .. "Outline::\n[source,lua]\n----\n{\n"

    for _,k in pairs(keys) do
        local v = theTable[k]
        local functionDocComment = parseDocComment(tableId .. "." .. k, v, tableLabel and tableLabel .. "." .. k or nil)

        doc = doc .. "    " .. functionDocComment.tableSignature .. "\n"
    end

    doc = doc .. "}\n----\n\n"

    for _,k in pairs(keys) do
        local v = theTable[k]
        doc = doc .. documentFunction(tableId .. "." .. k, v, headingLevel + 1, tableLabel and "object." .. k or nil)
    end

    return doc
end

documentFunction = function(functionId, func, headingLevel, functionLabel)
    local docComment = parseDocComment(functionId, func, functionLabel)

    local slug = functionId:lower():gsub("%.", "-")

    local doc = "[[" .. slug .. "]]\n"
    doc = doc .. string.rep("=", headingLevel) .. " " .. (functionLabel or functionId) .. "\n\n"
    if docComment.isDeprecated then
        doc = doc .. "[WARNING]\n====\nThis function is deprecated and should not be used anymore.\n"
        if docComment.deprecatedMessage then
            doc = doc .. "\n" .. docComment.deprecatedMessage .. "\n"
        end
        doc = doc .. "====\n"
    end
    if docComment.isInternal then
        doc = doc .. "[WARNING]\n====\nThis function is only for internal use. It might change at any time without further notice.\n"
        if docComment.internalMessage then
            doc = doc .. "\n" .. docComment.internalMessage .. "\n"
        end
        doc = doc .. "====\n"
    end
    doc = doc .. docComment.description .. "\n"
    doc = doc .. "Usage::\n[source,lua]\n----\n" .. docComment.signature .. "\n----\n\n"

    doc = doc .. writeFuncArguments(docComment.arguments)

    local retValueKey = functionId:gsub("%.", "_")
    local returnValue = returnValues[retValueKey]

    if isTable(returnValue) then
        --doc = doc .. "==== Return Value\n\n"
        doc = doc .. documentTable(functionId .. ".returnValue", returnValue, headingLevel + 1, "Return Value")
    elseif not isNil(returnValue) then
        error("Expected the return value of " .. functionId .. " to be a table, but got " .. typeInspect(returnValue))
    elseif docComment.returns ~= nil then
        doc = doc .. "returnValue::\n"
        if arg.type then doc = doc .. "`" .. arg.type .. "` " end
        if arg.description then doc = doc .. arg.description end
        doc = doc .. "``" .. docComment.returns.type .. "`` " .. (docComment.returns.description or "") .. "\n\n"
    end

    return doc
end

for _, name in pairs(data) do
    local func = _G[name]

    if isFunction(func) then
        local content = documentFunction(name, func, 2)
        indexFile:write(content)
    elseif isTable(func) then
        local content = documentTable(name, func, 2)
        indexFile:write(content)
    end
end