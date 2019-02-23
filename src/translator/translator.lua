Translator = Translator or {}

local transliterate = function(s)
    -- TODO: potentially slow and should support more languages
    s = s:gsub("ä", "ae")
    s = s:gsub("ö", "oe")
    s = s:gsub("ü", "ue")
    s = s:gsub("Ä", "Ae")
    s = s:gsub("Ö", "Oe")
    s = s:gsub("Ü", "Ue")
    s = s:gsub("ß", "ss")
    return s
end

--- create a new Translator
--- @param self
--- @param defaultLocale string (default: `en`)
--- @return Translator
Translator.new = function(self, defaultLocale)
    defaultLocale = defaultLocale or "en"
    if not isString(defaultLocale) then error("Expected defaultLocale to be a string, but got " .. typeInspect(defaultLocale), 2) end

    local dictionaries = {}
    local locales = {defaultLocale}

    local translator
    translator = {
        --- change the current locale used for translation
        --- @param self
        --- @param ... string
        --- @return Translator
        useLocale = function(self, ...)
            for i,locale in ipairs({...}) do
                if not isString(locale) then error("Expected locales to be strings, but got " .. typeInspect(locale) .. " at position " .. i, 2) end
            end
            locales = {...}
            table.insert(locales, defaultLocale)
            return self
        end,

        --- register one or more translations
        --- @param self
        --- @param locale string (optional)
        --- @param key string|table could be the name of the key or a table with keys and translations
        --- @param label string|function (optional) when key is a string this is the translation
        --- @return string
        register = function(self, locale, key, label)
            if isTable(locale) then
                key = locale
                locale = defaultLocale
            elseif not isTable(key) and label == nil then
                label = key
                key = locale
                locale = defaultLocale
            end
            if not isString(locale) then error("Expected locale to be a string, but got " .. typeInspect(locale), 2) end
            if isTable(key) then
                for k, l in pairs(key) do
                    self:register(locale, k, l)
                end
            else
                if not isString(key) then error("Expected key to be a string for locale " .. locale .. ", but got " .. typeInspect(key), 2) end
                if not isString(label) and not isFunction(label) then error("Expected label to be a string or function for " .. key .. " in " .. locale ..", but got " .. typeInspect(label), 2) end
                dictionaries[locale] = dictionaries[locale] or {}
                if dictionaries[locale][key] ~= nil then logWarning("Translation for key " .. key .. " with locale " .. locale .. " does already exist. It will be overridden.") end
                dictionaries[locale][key] = label
            end
        end,

        --- translate a message
        --- @param key string
        --- @param ... any whatever arguments the translation needs
        --- @return string it will always return a string except when the translation key exists in no language
        translate = function(key, ...)
            local args = {... }
            if isTable(key) then
                -- key is self
                key = table.remove(args, 1)
            end
            if not isString(key) then error("Expected key to be a string, but got " .. typeInspect(key), 2) end

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
                            logError("Expected translation for " .. key .. " in locale " .. locale .. " to return a string, but got " .. typeInspect(message))
                        else
                            return transliterate(message)
                        end
                    else
                        return transliterate(trans)
                    end
                end
            end
            if hadError then
                return ""
            else
                error("No translation exists for key " .. key, 2)
            end
        end,

        --- @internal
        getDictionaries = function()
            return dictionaries
        end,

        --- @internal
        getDefaultLocale = function()
            return defaultLocale
        end,

        --- @internal
        -- internal function
        getLocales = function()
            return locales
        end,
    }
    return translator
end

--- check if the given thing is a translator
--- @param self
--- @param thing any
--- @return boolean
Translator.isTranslator = function(self, thing)
    return isTable(thing) and
        isFunction(thing.useLocale) and
        isFunction(thing.register) and
        isFunction(thing.translate)
end