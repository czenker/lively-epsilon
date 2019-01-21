insulate("Translator:inspect()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("finds missing translations", function()
        local translator = Translator:new("en")
        translator:register("en", "say_hello", "Hello World")
        translator:register("en", "say_bye", "Good Bye")
        translator:register("de", "say_bye", "Tschau")
        translator:useLocale("de")

        local missingTranslations, excessiveTranslations = Translator:inspect(translator)

        assert.is_same({"say_hello"}, missingTranslations)
        assert.is_same({}, excessiveTranslations)
    end)

    it("finds excessive translations", function()
        local translator = Translator:new()
        translator:register("en", "say_hello", "Hello World")
        translator:register("de", "say_hello", "Hallo Welt")
        translator:register("de", "say_bye", "Tschau")
        translator:useLocale("de")

        local missingTranslations, excessiveTranslations = Translator:inspect(translator)

        assert.is_same({}, missingTranslations)
        assert.is_same({"say_bye"}, excessiveTranslations)
    end)

    it("sorts the result alphabethically by key", function()
        local translator = Translator:new()
        translator:register("en", "say_a", "A")
        translator:register("en", "say_b", "B")
        translator:register("en", "say_c", "C")
        translator:register("de", "say_d", "D")
        translator:register("de", "say_e", "E")
        translator:register("de", "say_f", "F")
        translator:useLocale("de")

        local missingTranslations, excessiveTranslations = Translator:inspect(translator)

        assert.is_same({"say_a", "say_b", "say_c"}, missingTranslations)
        assert.is_same({"say_d", "say_e", "say_f"}, excessiveTranslations)
    end)

    it("fails if translator is not a Translator", function()
        assert.has_error(function()
            Translator:inspect(nil)
        end)
        assert.has_error(function()
            Translator:inspect(42)
        end)
        assert.has_error(function()
            Translator:inspect({})
        end)
    end)
end)

insulate("Translator:printInspection()", function()
    require "init"

    it("look that there is no smoke", function()
        -- all good
        local translator = Translator:new("en")
        translator:register("en", "say_hello", "Hello World")
        translator:register("de", "say_hello", "Hallo Welt")
        translator:useLocale("de")

        Translator:printInspection(translator)

        -- only missing
        local translator = Translator:new("en")
        translator:register("en", "say_hello", "Hello World")
        translator:register("en", "say_bye", "Good Bye")
        translator:register("de", "say_bye", "Tschau")
        translator:useLocale("de")

        Translator:printInspection(translator)

        -- only excessive
        local translator = Translator:new()
        translator:register("en", "say_hello", "Hello World")
        translator:register("de", "say_hello", "Hallo Welt")
        translator:register("de", "say_bye", "Tschau")
        translator:useLocale("de")

        Translator:printInspection(translator)

        -- mixed
        local translator = Translator:new()
        translator:register("en", "say_a", "A")
        translator:register("en", "say_b", "B")
        translator:register("en", "say_c", "C")
        translator:register("de", "say_d", "D")
        translator:register("de", "say_e", "E")
        translator:register("de", "say_f", "F")
        translator:useLocale("de")

        Translator:printInspection(translator)
    end)
end)