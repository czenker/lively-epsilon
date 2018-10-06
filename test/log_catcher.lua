-- catches all logs
function withLogCatcher(func)
    local backupError, backupWarning, backupInfo, backupDebug = _G.logError, _G.logWarning, _G.logInfo, _G.logDebug

    local errors, warnings, infos, debugs = {}, {}, {}, {}


    local function catch(tab)
        return function(message) table.insert(tab, message) end
    end

    _G.logError = catch(errors)
    _G.logWarning = catch(warnings)
    _G.logInfo = catch(infos)
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
        destroy = function()
            -- restore previous loggers
            _G.logError, _G.logWarning, _G.logInfo, _G.logDebug = backupError, backupWarning, backupInfo, backupDebug
        end,
    })
end