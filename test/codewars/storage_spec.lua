local P = require("plenary.path")

describe("storage.solution_file", function()
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")

    local warnings = {}
    package.loaded["codewars.logger"] = {
        info = function() end,
        warn = function(msg) table.insert(warnings, msg) end,
        error = function() end,
        err = function() end,
        debug = function() end,
    }
    local cfg = {
        user = {},
        langs = require("codewars.config.langs"),
        storage = { home = P:new(tmp) },
    }
    package.loaded["codewars.config"] = cfg
    package.loaded["codewars.utils"] = nil
    package.loaded["codewars.storage"] = nil
    local storage = require("codewars.storage")

    local function path_of(slug, lang)
        return storage.solution_file(slug, lang):absolute()
    end

    before_each(function()
        warnings = {}
        cfg.user = {}
    end)

    it("defaults to <slug>.<ext> flat in home", function()
        assert.are.equal(tmp .. "/multiply.py", path_of("multiply", "python"))
        assert.are.equal(tmp .. "/multiply.rs", path_of("multiply", "rust"))
    end)

    it("joins a relative result to home and passes lang, slug and ext", function()
        local seen
        cfg.user = { storage = { path = function(ctx)
            seen = ctx
            return ("%s/%s.%s"):format(ctx.lang, ctx.slug, ctx.ext)
        end } }
        assert.are.equal(tmp .. "/javascript/find-the-odd-int.js", path_of("find-the-odd-int", "javascript"))
        assert.are.same({ lang = "javascript", slug = "find-the-odd-int", ext = "js" }, seen)
    end)

    it("uses an absolute result as is", function()
        cfg.user = { storage = { path = function(ctx) return "/srv/kata/" .. ctx.slug .. ".c" end } }
        assert.are.equal("/srv/kata/x.c", path_of("x", "c"))
    end)

    it("expands ~", function()
        cfg.user = { storage = { path = function() return "~/kata/x.nim" end } }
        assert.are.equal(vim.fn.expand("~") .. "/kata/x.nim", path_of("x", "nim"))
    end)

    it("falls back to the flat name and warns when the function errors", function()
        cfg.user = { storage = { path = function() error("boom") end } }
        assert.are.equal(tmp .. "/x.py", path_of("x", "python"))
        assert.are.equal(1, #warnings)
        assert.truthy(warnings[1]:find("boom", 1, true))
    end)

    it("falls back when the function returns no path", function()
        for _, ret in ipairs({ { nil }, { "" }, { 42 } }) do
            warnings = {}
            cfg.user = { storage = { path = function() return ret[1] end } }
            assert.are.equal(tmp .. "/x.py", path_of("x", "python"))
            assert.are.equal(1, #warnings)
        end
    end)
end)
