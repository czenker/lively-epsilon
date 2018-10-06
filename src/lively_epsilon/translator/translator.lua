Translator = Translator or {}

Translator.new = function(self, defaultLocale)
    defaultLocale = defaultLocale or "en"
    if not isString(defaultLocale) then error("Expected defaultLocale to be a string, but got " .. type(defaultLocale), 2) end

    local dictionaries = {}
    local locales = {defaultLocale}

    local self
    self = {
        useLocale = function(self, ...)
            for i,locale in ipairs({...}) do
                if not isString(locale) then error("Expected locales to be strings, but got " .. type(locale) .. " at position " .. i, 2) end
            end
            locales = {...}
            table.insert(locales, defaultLocale)
        end,

        register = function(self, locale, key, label)
            if isTable(locale) then
                key = locale
                locale = defaultLocale
            elseif not isTable(key) and label == nil then
                label = key
                key = locale
                locale = defaultLocale
            end
            if not isString(locale) then error("Expected locale to be a string, but got " .. type(locale), 2) end
            if isTable(key) then
                for k, l in pairs(key) do
                    self:register(locale, k, l)
                end
            else
                if not isString(key) then error("Expected key to be a string for locale " .. locale .. ", but got " .. type(key), 2) end
                if not isString(label) and not isFunction(label) then error("Expected label to be a string or function for " .. key .. " in " .. locale ..", but got " .. type(label), 2) end
                dictionaries[locale] = dictionaries[locale] or {}
                if dictionaries[locale][key] ~= nil then logWarning("Translation for key " .. key .. " with locale " .. locale .. " does already exist. It will be overridden.") end
                dictionaries[locale][key] = label
            end
        end,

        translate = function(key, ...)
            local args = {... }
            if isTable(key) then
                -- key is self
                key = table.remove(args, 1)
            end
            if not isString(key) then error("Expected key to be a string, but got " .. type(key), 2) end

            local hadError = false

            for _,locale in pairs(locales) do
                if dictionaries[locale] ~= nil and dictionaries[locale][key] ~= nil then
                    local trans = dictionaries[locale][key]
                    if isFunction(trans) then
                        local status, message = pcall(trans, table.unpack(args))
                        if not status then
                            hadError = true
                            local errorMsg = "An error occured when getting translation for " .. key .. " in locale " .. locale
                            if type(message) == "string" then
                                errorMsg = errorMsg .. ": " .. message
                            end
                            logError(errorMsg)
                        elseif not isString(message) then
                            logError("Expected translation for " .. key .. " in locale " .. locale .. " to return a string, but got " .. type(message))
                        else
                            return message
                        end
                    else
                        return trans
                    end
                end
            end
            if hadError then
                return ""
            else
                error("No translation exists for key " .. key, 2)
            end
        end,

        -- internal function
        getDictionaries = function()
            return dictionaries
        end,

        -- internal function
        getDefaultLocale = function()
            return defaultLocale
        end,

        -- internal function
        getLocales = function()
            return locales
        end,
    }
    return self
end

Translator.isTranslator = function(self, thing)
    return isTable(thing) and
        isFunction(thing.useLocale) and
        isFunction(thing.register) and
        isFunction(thing.translate)
end