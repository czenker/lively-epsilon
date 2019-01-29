local function useAnsi()
    return (LivelyEpsilonConfig or {}).useAnsi or false
end

local function logLevel()
    local logLvl = (LivelyEpsilonConfig or {}).logLevel
    if isString(logLvl) then logLvl = logLvl:upper() end
    return logLvl
end

local function timestamp()
    if (LivelyEpsilonConfig or {}).logTime == true then
        return string.format("[%7.1f]", Cron.now())
    else
        return ""
    end
end

local red = "\u{001b}[41m\u{001b}[37m"
local yellow = "\u{001b}[33m"
local cyan = "\u{001b}[36m"
local grey = "\u{001b}[30;1m"
local reset = "\u{001b}[0m"

logError = function (message)
    local logLvl = logLevel()
    if logLvl == nil or logLvl == "DEBUG" or logLvl == "INFO" or logLvl == "WARNING" or logLvl == "ERROR" then
        print(timestamp() .. (useAnsi() and red or "") .. "[ERROR] " .. message .. (useAnsi() and reset or ""))
    end
end

logWarning = function (message)
    local logLvl = logLevel()
    if logLvl == nil or logLvl == "DEBUG" or logLvl == "INFO" or logLvl == "WARNING" then
        print(timestamp() .. (useAnsi() and yellow or "") .. "[WARN]  " .. message .. (useAnsi() and reset or ""))
    end
end

logInfo = function (message)
    local logLvl = logLevel()
    if logLvl == nil or logLvl == "DEBUG" or logLvl == "INFO" then
        print(timestamp() .. (useAnsi() and cyan or "") .. "[INFO]  " .. message .. (useAnsi() and reset or ""))
    end
end

logDebug = function (message)
    local logLvl = logLevel()
    if logLvl == nil or logLvl == "DEBUG" then
        print(timestamp() .. (useAnsi() and grey or "") .. "[DEBUG] " .. message .. (useAnsi() and reset or ""))
    end
end
