insulate("Person", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe("byName()", function()
        it("should create a valid Person object by name", function()
            local person = Person.byName("John Doe")

            assert.is_same("John Doe", person.getFormalName())
            assert.is_same("John Doe", person.getNickName())
            assert.is_true(Person:isPerson(person))
        end)
        it("should create a valid Person object by name with nickname", function()
            local person = Person.byName("John Doe", "John")

            assert.is_same("John Doe", person.getFormalName())
            assert.is_same("John", person.getNickName())
            assert.is_true(Person:isPerson(person))
        end)
    end)
end)