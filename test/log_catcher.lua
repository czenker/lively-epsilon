-- catches all logs
function withLogCatcher(func)
    local backupError, backupWarning, backupInfo, backupDebug, backupTrace = _G.logError, _G.logWarning, _G.logInfo, _G.logDebug, _G.logTrace

    local errors, warnings, infos, debugs, traces = {}, {}, {}, {}, {}


    local function catch(tab)
        return function(message) table.insert(tab, message) end
    end

    _G.logError = catch(errors)
    _G.logWarning = catch(warnings)
    _G.logInfo = catch(infos)
    _G.logTrace = catch(traces)
    _G.logDebug = catch(debugs)

    local function count(tab)
        return function() return Util.size(tab) end
    end
    local function popLast(tab)
        return function() return table.remove(tab) end
    end

    func({
        countErrors = count(errors),
        popLastError = popLast(errors),
        countWarnings = count(warnings),
        popLastWarning = popLast(warnings),
        countInfos = count(infos),
        popLastInfo = popLast(infos),
        countDebugs = count(debugs),
        popLastDebug = popLast(debugs),
        countTraces = count(traces),
        popLastTrace = popLast(traces),
        destroy = function()
            -- restore previous loggers
            _G.logError, _G.logWarning, _G.logInfo, _G.logDebug, _G.logTrace = backupError, backupWarning, backupInfo, backupDebug, backupTrace
        end,
    })
end