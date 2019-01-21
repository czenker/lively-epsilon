Translator = Translator or {}

-- returns all keys that are in table1, but not table2
local function distinctKeys(table1, table2)
    local ret = {}
    for k,_ in pairs(table1) do
        if table2[k] == nil then table.insert(ret, k) end
    end
    table.sort(ret)
    return ret
end

-- inspects for missing or excessive translations
Translator.inspect = function(self, translator)
    if not Translator:isTranslator(translator) then error("Expected translator to be a Translator, but got " .. typeInspect(translator), 2) end
    local locale1 = translator:getDefaultLocale()
    local locale2 = translator:getLocales()[1]
    if locale1 == locale2 then
        logWarning("Source and Target locale are identically - nothing to do for Translator:inspect()")
        return {}, {}
    else
        local dict1 = translator:getDictionaries()[locale1] or {}
        local dict2 = translator:getDictionaries()[locale2] or {}

        local missingKeys = distinctKeys(dict1, dict2)
        local excessiveKeys = distinctKeys(dict2, dict1)

        return missingKeys, excessiveKeys
    end
end

Translator.printInspection = function(self, translator)
    local missing, excessive = Translator:inspect(translator)
    local locale1 = translator:getDefaultLocale()
    local locale2 = translator:getLocales()[1]

    print("Checking translator - source locale: " .. locale1 .. ", target locale: " .. locale2)
    if Util.size(missing) == 0 and Util.size(excessive) == 0 then
        print("  Everything is fine.")
    else
        if Util.size(missing) > 0 then
            print("  The following translations are missing:")
            for _,key in pairs(missing) do
                print("    * " .. key)
            end
        else
            print("  There are no missing translations.")
        end

        if Util.size(excessive) > 0 then
            print("  The following translations are excessive:")
            for _,key in pairs(excessive) do
                print("    * " .. key)
            end
        else
            print("  There are no excessive translations.")
        end
    end
    print("")

end
