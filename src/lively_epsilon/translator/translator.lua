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

        register = function(self, lang, key, label)
            if isTable(lang) then
                key = lang
                lang = defaultLocale
            elseif not isTable(key) and label == nil then
                label = key
                key = lang
                lang = defaultLocale
            end
            if not isString(lang) then error("Expected lang to be a string, but got " .. type(lang), 2) end
            if isTable(key) then
                for k, l in pairs(key) do
                    self:register(lang, k, l)
                end
            else
                if not isString(key) then error("Expected key to be a string for language " .. lang .. ", but got " .. type(key), 2) end
                if not isString(label) and not isFunction(label) then error("Expected label to be a string or function for " .. key .. " in " .. lang ..", but got " .. type(label), 2) end
                dictionaries[lang] = dictionaries[lang] or {}
                if dictionaries[lang][key] ~= nil then logWarning("Translation for key " .. key .. " with locale " .. lang .. " does already exist. It will be overridden.") end
                dictionaries[lang][key] = label
            end
        end,

        translate = function(key, ...)
            local args = {... }
            if isTable(key) then
                -- key is self
                key = table.remove(args, 1)
            end
            if not isString(key) then error("Expected key to be a string, but got " .. type(key), 2) end
            for _,locale in pairs(locales) do
                if dictionaries[locale] ~= nil and dictionaries[locale][key] ~= nil then
                    local trans = dictionaries[locale][key]
                    if isFunction(trans) then
                        local status, message = pcall(trans, table.unpack(args))
                        if not status then
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
            error("No translation exists for key " .. key, 2)
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