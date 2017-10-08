local prototype = {
    name = function(self)
        return self.firstName .. " " .. self.lastName
    end
}

Person = {
    new = function(self)
        local gender, firstName, lastName = personNames.getName()


        return  setmetatable({
            firstName = firstName,
            lastName = lastName
        }, {__index = prototype})
    end
}

function isRichPerson(person)
    return type(person) == "table" and person.firstName ~= nil and person.lastName ~= nil
end