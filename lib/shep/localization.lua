---@class shep.Localization
---@field translations table<string, table<string, string>>
local localization = {
    currentLocale = 'fallback',
    translations = {
        fallback = {}
    }
}

--- Add a new entry to the localization table
---@param language string
---@param uniqueKey string
---@param translation string
---@overload fun(self: shep.Localization, uniqueKey: string, translation: string)
function localization:addEntry(language, uniqueKey, translation)
    if not translation then
        language, uniqueKey, translation = 'fallback', language, uniqueKey
    end

    if not self.translations[language] then
        self.translations[language] = {
            [uniqueKey] = translation
        }
        return;
    end

    self.translations[language][uniqueKey] = translation
end

--- Get the translation for a given key
---@param key string
function localization:t(key)
    if self.translations[self.currentLocale] and self.translations[self.currentLocale][key] then
        return self.translations[self.currentLocale][key]
    elseif self.translations['fallback'][key] then
        return self.translations['fallback'][key]
    else
        -- If the key is not found, return the key itself
        return key
    end
end

--- Set the current locale
---@param locale string
function localization:setLocale(locale)
    self.currentLocale = locale
end

--- Load translations from a file
--- The file should be a JSON file with the following format:
--- {
---    "key": "translation",
---    "key2": "translation2"
--- }
---@param filePath string
function localization:loadFromFile(filePath)
    local language = filePath:match("([^/]+)%.%w+$")
    local file = love.filesystem.newFile(filePath)
    file:open('r')
    local data = file:read()
    file:close()

    local translations = json.decode(data)
    for key, translation in pairs(translations) do
        self:addEntry(language, key, translation)
    end
end

--- Load translations from a directory
---@param dirPath string
function localization:loadFromDirectory(dirPath)
    local files = self:getTranslationFiles(dirPath)
    for _, file in ipairs(files) do
        self:loadFromFile(dirPath .. '/' .. file)
    end
end

--- Get all the JSON translation files in a directory
---@private
---@return table<string>
function localization:getTranslationFiles(dirPath)
    local files = love.filesystem.getDirectoryItems(dirPath)
    local jsonFiles = {}
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            table.insert(jsonFiles, file)
        end
    end

    return jsonFiles
end

return localization