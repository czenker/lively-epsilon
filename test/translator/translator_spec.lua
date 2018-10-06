insulate("Translator:new()", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    it("should work when only using one locale", function()
        local translator = Translator:new()
        assert.is_true(Translator:isTranslator(translator))

        translator:register("say_hello", "Hello World")

        assert.is_same("Hello World", translator:translate("say_hello"))
    end)

    it("should basically work with a different locale", function()
        local translator = Translator:new()

        assert.is_true(Translator:isTranslator(translator))

        translator:register("say_hello", "Hello World")
        translator:register("de", "say_hello", "Hallo Welt")

        assert.is_same("Hello World", translator:translate("say_hello"))
        translator:useLocale("de")
        assert.is_same("Hallo Welt", translator:translate("say_hello"))
    end)

    it("uses a fallback when translation is not available", function()
        local translator = Translator:new()

        assert.is_true(Translator:isTranslator(translator))

        translator:register("say_hello", "Hello World")

        translator:useLocale("de")
        assert.is_same("Hello World", translator:translate("say_hello"))
    end)

    it("uses multiple fallbacks when translation is not available", function()
        local translator = Translator:new()
        translator:useLocale("sp", "de")

        translator:register("en", "test", "Hello World")
        assert.is_same("Hello World", translator:translate("test"))
        translator:register("de", "test", "Hallo Welt")
        assert.is_same("Hallo Welt", translator:translate("test"))
        translator:register("sp", "test", "Hola Mundo")
        assert.is_same("Hola Mundo", translator:translate("test"))
    end)

    describe("functions as values", function()
        it("can use a function as translation", function()
            local translator = Translator:new()
            translator:register("say_hello", function() return "Hello World" end)

            assert.is_same("Hello World", translator:translate("say_hello"))
        end)
        it("gives the translator and all given arguments to translation function", function()
            local translator = Translator:new()
            local arg1 = Util.randomUuid()
            local arg2 = Util.randomUuid()
            local arg3 = Util.randomUuid()
            local givenArg1, givenArg2, givenArg3

            translator:register("say_hello", function(arg1, arg2, arg3)
                givenArg1 = arg1
                givenArg2 = arg2
                givenArg3 = arg3
                return "Hello World"
            end)

            assert.is_same("Hello World", translator:translate("say_hello", arg1, arg2, arg3))
            assert.is_same(arg1, givenArg1)
            assert.is_same(arg2, givenArg2)
            assert.is_same(arg3, givenArg3)
        end)
        it("tries fallback locales if function errors", function()
            -- this behavior should not be problematic because translations should not have side-effects
            local translator = Translator:new("en")
            translator:useLocale("de")
            translator:register("en", "say_hello", function() return "Hello World" end)
            translator:register("de", "say_hello", function() return error("Boom") end)

            assert.is_same("Hello World", translator:translate("say_hello"))
        end)
        it("tries fallback locales if function does not return a string", function()
            local translator = Translator:new("en")
            translator:useLocale("de")
            translator:register("en", "say_hello", function() return "Hello World" end)
            translator:register("de", "say_hello", function() return 42 end)

            assert.is_same("Hello World", translator:translate("say_hello"))
        end)
    end)

    describe("register() can take a table of translations", function()
        it("should work with the default locale", function()
            local translator = Translator:new()

            translator:register({
                say_hello = "Hello World",
                say_bye = "Goodbye",
            })

            assert.is_same("Hello World", translator:translate("say_hello"))
        end)
        it("should work with a different locale", function()
            local translator = Translator:new()

            translator:register({
                say_hello = "Hello World",
                say_bye = "Goodbye",
            })
            translator:register("de", {
                say_hello = "Hallo Welt",
                say_bye = "Tschau",
            })

            translator:useLocale("de")
            assert.is_same("Hallo Welt", translator:translate("say_hello"))
        end)
    end)


    describe("short hand syntax", function()
        it("should allow to use short-hand", function()
            local translator = Translator:new()
            local t = translator.translate

            translator:register("say_hello", "Hello World")

            assert.is_same("Hello World", t("say_hello"))
        end)

        it("gives the translator and all given arguments to translation function", function()
            local translator = Translator:new()
            local t = translator.translate

            local arg1 = Util.randomUuid()
            local arg2 = Util.randomUuid()
            local arg3 = Util.randomUuid()
            local givenArg1, givenArg2, givenArg3

            translator:register("say_hello", function(arg1, arg2, arg3)
                givenArg1 = arg1
                givenArg2 = arg2
                givenArg3 = arg3
                return "Hello World"
            end)

            assert.is_same("Hello World", t("say_hello", arg1, arg2, arg3))
            assert.is_same(arg1, givenArg1)
            assert.is_same(arg2, givenArg2)
            assert.is_same(arg3, givenArg3)
        end)
    end)


    describe("new()", function()
        it("allows to set the default locale", function()
            local translator = Translator:new("de")
            translator:register("en", "say_hello", "Hello World")
            translator:register("de", "say_hello", "Hallo Welt")

            assert.is_same("Hallo Welt", translator:translate("say_hello"))
            translator:useLocale("en")
            assert.is_same("Hello World", translator:translate("say_hello"))
            translator:useLocale("de")
            assert.is_same("Hallo Welt", translator:translate("say_hello"))
        end)
        it("fails if defaultLocale is not a string", function()
            assert.has_error(function()
                Translator:new(42)
            end)
        end)
    end)

    describe("register()", function()
        it("fails if key is missing", function()
            local translator = Translator:new()

            assert.has_error(function()
                translator:register()
            end)

            assert.has_error(function()
                translator:register("say_hello", nil)
            end)
        end)
        it("fails if label is not a string or function", function()
            local translator = Translator:new()

            assert.has_error(function()
                translator:register("say_hello", 42)
            end)

            assert.has_error(function()
                translator:register("say_hello", nil)
            end)
        end)
        it("fails if locale is not a string", function()
            local translator = Translator:new()

            assert.has_error(function()
                translator:register(42, "say_hello", "Hello World")
            end)

            assert.has_error(function()
                translator:register(nil, "say_hello", "Hello World")
            end)
        end)
    end)

    describe("translate()", function()
        it("should fail if key does not exist in translation or defaultLocale", function()
            local translator = Translator:new()

            translator:register("say_hello", "Hello World")

            assert.has_error(function()
                translator:translate("mistyped")
            end)
        end)
        it("returns an empty string if a translation errors and all fallbacks error too", function()
            local translator = Translator:new()

            translator:register("say_hello", function() error("Boom") end)
            assert.is_same("", translator:translate("say_hello"))
        end)

        it("should fail if key is not a string", function()
            local translator = Translator:new()

            translator:register("say_hello", "Hello World")

            assert.has_error(function()
                translator:translate(42)
            end, "Expected key to be a string, but got number")
            assert.has_error(function()
                translator:translate({})
            end, "Expected key to be a string, but got table")
        end)

    end)

    describe("useLocale", function()
        it("uses default locale if no argument is given", function()
            local translator = Translator:new()
            translator:register("say_hello", "Hello World")

            translator:useLocale()

            assert.is_same("Hello World", translator:translate("say_hello"))
        end)
        it("fails if any of the arguments is not a string", function()
            local translator = Translator:new()

            assert.has_error(function()
                translator:useLocale(42)
            end)

            assert.has_error(function()
                translator:useLocale("en", "de", 42)
            end)
        end)
    end)
end)