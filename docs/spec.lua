local json = require ("dkjson")

local jsonFilePath = arg[1]
local jsonFile = io.open(jsonFilePath, "r")
if jsonFile == nil then error("Could not open file " .. jsonFilePath .. " for reading.") end

local data, _, err = json.decode(jsonFile:read("*all"))
if err then error("Error reading json: " .. err) end
if #data == nil or #data < 50 then error("Unexpected json detected in " .. jsonFilePath) end

local indexFilePath = arg[2]
local indexFile = io.open(indexFilePath, "w+")
if indexFile == nil then error("Could not open file " .. indexFilePath .. " for writing.") end

---
--- Utility Functions

local indentOfLine = function(line)
    if line == "" then return nil end
    local s, e = line:find("^%s*")
    if s == nil then return 0 else return e end
end

-- we are a little stupid and just determine the end of the function by checking for the next line that has text on the same indent level
local isolateTestFunction = function(filePath, startAt)
    filePath = "../" .. filePath
    local f = io.open(filePath, "r")
    if not f then error("Could not open file " .. filePath) end

    local lines = {}
    for line in f:lines() do
        table.insert(lines, line)
    end

    if lines[startAt] == nil then error("File " .. filePath .. " does not have a line " .. startAt) end

    local targetIndent = indentOfLine(lines[startAt])

    for i=startAt+1,#lines do
        local indent = indentOfLine(lines[i])
        if indent == nil then
            -- nothing: This is an empty line
        elseif indent < targetIndent then
            error("You probably messed up indent in file " .. filePath .. " around line " .. i .. ". Expected an indent of " .. targetIndent .. ", but got " .. indent)
        elseif indent == targetIndent then
            return startAt, i
        end
    end

    error("Could not an end in file " .. filePath .. " with indent level " .. targetIndent)
end

local slug = function(name)
    return name:lower():gsub("[^%w]", "-"):gsub("%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
end

---
--- Ok, lets go

local processedTests = 0
local groups = {}

for i, entry in ipairs(data) do
    if entry.name == nil or entry.file == nil or entry.line == nil then
        error("Invalid data set at position " .. i)
    end
    local name = entry.name
    name = name:gsub(" ([%.:])", "%1")
    name = name:gsub("^([^%s]+) ([^%s]+)%(%)", "%1:%2()")

    local idx = name:find(" ")
    local group, test
    if idx ~= nil then
        group = name:sub(1,idx-1)
        test = name:sub(idx+1)
    else
        group = "Other"
        test = name
    end

    groups[group] = groups[group] or {}
    table.insert(groups[group], {
        name = name,
        file = entry.file,
        line = entry.line,
        slug = slug(name),
    })
    processedTests = processedTests + 1
end

if processedTests < 50 then error("Something went wrong. Did not find a fair number of tests, but only " .. processedTests .. ".") end

indexFile:write(":attribute-missing: warn", "\n")
indexFile:write(":attribute-undefined: drop", "\n")
indexFile:write(":source-highlighter: coderay", "\n")
indexFile:write("\n")
indexFile:write(":toc: left", "\n")
indexFile:write(":toclevels: 2", "\n")
indexFile:write(":icons: font", "\n")
indexFile:write("\n")
indexFile:write("= Lively Epsilon Specification", "\n")
indexFile:write("\n")
indexFile:write("This document shows intentional specifications of the components provided by Lively Epsilon.", "\n\n")
indexFile:write(
        "The following are code examples that are run as tests. So they sometimes use mocks that you could see in the code\n",
        "examples. Statements starting with `assert` are assumptions on the code that follows. Their name should be self-explanatory.",
        "\n\n"
)
indexFile:write("[WARNING]", "\n")
indexFile:write("====\n")
indexFile:write("The documentation also documents internal functions. Please check if a method is supposed to be used in the link:reference.html[API reference] before using it.", "\n")
indexFile:write("====\n\n")

local keys = {}

for k, _ in pairs(groups) do
    table.insert(keys, k)
end
table.sort(keys)

for _, group in pairs(keys) do
    local tests = groups[group]
    table.sort(tests, function(a, b) return a.name < b.name end)

    indexFile:write("[[" .. slug(group) .. "]]\n")
    indexFile:write("== " .. group, "\n\n")
    for _, entry in pairs(tests) do
        local from, to = isolateTestFunction(entry.file, entry.line)
        if to - from < 2 then error("Expected test \"" .. entry.name .. "\" in file " .. entry.file .. " at line " .. from .. " to have at least two lines.") end

        indexFile:write("[[" .. entry.slug .. "]]\n")
        indexFile:write("+++ <details><summary> +++\n")
        indexFile:write(entry.name .. "\n")
        indexFile:write("+++ </summary><div> +++\n")
        indexFile:write("[source,lua]\n----\n")
        indexFile:write("include::{rootdir}/", entry.file, "[lines=", from+1, "..", to-1, ", indent=0]\n")
        indexFile:write("----\n")
        indexFile:write("+++ </div></details> +++\n\n")

        --indexFile:write(" <<", entry.slug, ", ^[Code]^>>")
        indexFile:write("\n")
    end
    indexFile:write("\n")

    --for _, entry in pairs(tests) do

    --end
end




