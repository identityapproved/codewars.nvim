local config = require("codewars.config")
local log = require("codewars.logger")
local P = require("plenary.path")

---@class cw.Storage
local storage = {}

--- Where the solution for `slug` in `lang_slug` lives. `storage.path`, when
--- set, decides the path (relative to storage.home, or absolute / `~`); one
--- that errors or returns no path is reported and the flat default is used,
--- so a broken function can never stop a kata from opening.
---@param slug string
---@param lang_slug string
---@return Path
function storage.solution_file(slug, lang_slug)
    local lang = require("codewars.utils").get_lang(lang_slug)
    assert(lang, "Unsupported language: " .. tostring(lang_slug))
    local rel = ("%s.%s"):format(slug, lang.ft)

    local fn = ((config.user or {}).storage or {}).path
    if type(fn) == "function" then
        local ok, res = pcall(fn, { lang = lang_slug, slug = slug, ext = lang.ft })
        if not ok then
            log.warn(("storage.path failed (%s); using %s"):format(tostring(res), rel))
        elseif type(res) ~= "string" or res == "" then
            log.warn(("storage.path returned no path; using %s"):format(rel))
        else
            rel = vim.fn.expand(res)
        end
    end

    if rel:sub(1, 1) == "/" then return P:new(rel) end
    return config.storage.home:joinpath(rel)
end

return storage
