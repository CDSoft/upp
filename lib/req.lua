--[[
    This file is part of UPP.

    UPP is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    UPP is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with UPP.  If not, see <https://www.gnu.org/licenses/>.

    For further information about UPP you can visit
    http://cdelord.fr/upp
--]]

--[[
    Basic requirement management
    ============================

    The macro `req` defines a requirement and optionnally references to other requirements.
    It can also be given a custom table that can be used by third party scripts.

    The macro `req.test` defines a requirement associated to a test. It's very similar to
    a requirement created by `req` but can also contain a `status` attribute
    (`nil`: not executed, `false`: test failed, `true`: test passed).

    The database is stored as a simple database.

    The macro `req.ref' generates a reference to a requirement (hyperlink).

    The macro `reg.matrix` generates a coverage matrix.

    The macro `req.summary` returns a table with some statistics:
        reqs: number of requirements
        reqs_covered: number of requirements covered by other requirements or tests
        reqs_not_covered: number of requirements not covered by any other requirements or tests
        req_coverage: coverage rate (0..100)
        tests: number of test requirements
        tests_not_executed: number of tests not executed
        tests_failed: number of tests failed
        tests_passed: number of tests passed
        test_coverage: test coverage rate (0..100)

    The macro `req.dot` generates the source of a Graphviz diagram showing the requirements relationships.
    Node colors:
        cyan: orphan requirement
        orange: requirement not covered
        green: test passed
        red: test failed
        yellow: test not executed (or status unknown)

    Examples
    ========

    Orphan requirement (high level specification or derived requirement):
    @(req "REQ_ID: requirement title")

    Requirement refining other requirements:
    @(req "REQ_ID: requirement title" {
        refs = "references to other requirements", -- space separated ids in a string
        -- other custom fields can also be defined and stored in the database
    })

    References to a requirement can also appear everywhere: @(req.ref "ID")

    Coverage matrix for the current file (REQTARGET): @(req.matrix())
    Coverage matrix for the specific file: @(req.matrix "file")
    Coverage matrix for all files: @(req.matrix "g")

    Configuration
    =============

    The plugin expects two variables (Lua global variables or environment variables):

    REQDB: path to the requirement database (this is itself a Lua script)
    REQTARGET: path to the final document (used to attach requirements to the document)
--]]

-- Database format:
-- {
--      files = "file1 file2 ...",
--      order = "REQ_1 REQ_2 ...",
--      { file="filename", id="ID", title="...", refs={"REF1", "REF2", ...}, otherfields...},
--      ...
-- }

local fs = require "fs"
local fun = require "fun"

local COLOR = {
    ORPHAN = "cyan",
    NORMAL = "lightgrey",
    NOT_COVERED = "orange",
    TEST_PASSED = "green",
    TEST_FAILED = "red",
    TEST_NOT_EXECUTED = "yellow",
}

local _db = nil

local function getvar(name)
    local val = _ENV[name] or os.getenv(name)
    if not val then
        error(name..": variable not defined")
    end
    return val
end

local function reqstr(r)
    local refs = fun.map(r.refs or {}, function(ref) return ("%q"):format(ref) end)
    local attrs = {}
    for k, v in fun.pairs(r) do
        if k ~= "file" and k ~= "id" and k ~= "title" and k ~= "refs" then
            attrs[#attrs+1] = ("%s = %q,"):format(k, v)
        end
    end
    return ("{file=%q, id=%q, title=%q, refs={%s}, %s},\n"):format(
        r.file, r.id, r.title,
        table.concat(refs, ", "),
        table.concat(attrs, " ")
    )
end

local function ReqDB()
    if _db then return _db end
    local path = getvar "REQDB"
    local output = getvar "REQTARGET"
    local link = (output:match "%.html$" or output:match "%.pdf$") and output or nil
    local db = fs.is_file(path) and assert(loadfile(path))() or {}
    local order = (db.order or ""):words()
    local order_dict = {}
    fun.foreach(order, function(id) order_dict[id] = true end)
    local files = (db.files or ""):words()
    local files_dict = {}
    fun.foreach(files, function(id) files_dict[id] = true end)
    db = fun.filter(db, function(r) return r.file ~= output end)
    local old_reqs = {}
    fun.foreach(db, function(r) old_reqs[r.id] = r end)
    local dbmt = {
        __index = {
            output = function(_) return output end,
            link = function(_) return link end,
            getreq = function(_, id)
                local r = old_reqs[id]
                if not r then error(id..": requirement not defined") end
                return r
            end,
            order = function(_) return order end,
            files = function(_) return files end,
            add = function(_, r)
                local old_req = old_reqs[r.id]
                if old_req then
                    error(r.id..": already defined in "..old_req.file)
                end
                old_reqs[r.id] = r
                db[#db+1] = r
                if not order_dict[r.id] then
                    order[#order+1] = r.id
                    order_dict[r.id] = true
                end
                if not files_dict[r.file] then
                    files[#files+1] = r.file
                    files_dict[r.file] = true
                end
            end,
            check_refs = function(_, req)
                for _, ref in ipairs(req.refs or {}) do
                    if not old_reqs[ref] then
                        error(ref..": referenced by "..req.id.." but not defined")
                    end
                end
            end,
            save = function(_)
                local newdb = "return {\n"..
                                ("order = %q,\n"):format(table.concat(order, " "))..
                                ("files = %q,\n"):format(table.concat(files, " "))..
                                table.concat(fun.map(reqstr, db))..
                              "}\n"
                local f = assert(io.open(path, "w"))
                f:write(newdb)
                f:close()
            end,
            classify = function(_)
                local classes = {}
                local direct = {}
                local reverse = {}
                fun.foreach(db, function(req)
                    fun.foreach(req.refs or {}, function(ref_id)
                        direct[req.id] = direct[req.id] or {}
                        table.insert(direct[req.id], ref_id)
                        reverse[ref_id] = reverse[ref_id] or {}
                        table.insert(reverse[ref_id], req_id)
                    end)
                end)
                fun.foreach(db, function(req)
                    classes[req.id] = {
                        orphan = direct[req.id] == nil,
                        not_covered = reverse[req.id] == nil,
                    }
                end)
                return classes
            end;
        },
    }
    _db = setmetatable(db, dbmt)
    atexit(function() _db:save() end)
    return _db
end

local function define_requirement(id)
    local db = ReqDB()
    local title = nil
    if id:match ":" then
        id, title = id:match "^([^:]-):(.*)$"
        id = id:trim()
        title = title:trim()
    end
    local req = {
        id = id,
        title = title,
        file = db:output(),
        link = db:link(),
    }
    db:add(req)
    return setmetatable(req, {
        __tostring = function(_)
            local t = fun.concat(
                -- header (current requirement)
                {
                    { ("**`%s`**"):format(req.id), req.title and ("**[%s]{}**"):format(req.title) or "" },
                },
                -- body (references)
                fun.map(req.refs or {}, function(ref)
                    local req0 = db:getreq(ref)
                    return { ("*[`%s`](%s#%s)*"):format(req0.id, req0.file ~= req.file and req0.link or "", req0.id), req0.title or "" }
                end)
            )
            local nb_columns = math.max(table.unpack(map(t, function(row) return #row end)))
            local ws = fun.map(fun.range(1, nb_columns), function(i)
                return math.max(table.unpack(fun.map(t, function(row) return #row[i] end)))
            end)
            local total_width = nb_columns - 1 -- spaces between columns
            fun.foreach(ws, function(w) total_width = total_width + w end)
            local sep = table.concat(fun.map(ws, function(w) return ("-"):rep(w) end), " ")
            local blank = table.concat(fun.map(ws, function(w) return (" "):rep(w) end), " ")
            local header = {
                -- div separator with anchor "::::::::{#req}"
                ("%s{#%s}"):format((":"):rep(total_width), req.id),
                "",
                -- beginning of the table "----- -----"
                sep,
            }
            local footer = {
                -- end of the table "----- -----"
                sep,
                "",
                -- end of div "::::::::"
                ("%s"):format((":"):rep(total_width)),
            }
            local body =
                -- rows of the table
                fun.flatten(
                    fun.map(t, function(row, i) return {
                        table.concat(
                            map(row, function(cell, j) return cell..(" "):rep(ws[j]-#cell) end),
                        " "),
                        i > 1 and i < #t and blank or {}
                    }
                    end)
                )
            if #body > 1 then table.insert(body, 2, (sep:gsub("-", "-"))) end
            return table.concat(fun.concat(header, body, footer), "\n")
        end,
        __call = function(_, attrs)
            for k, v in pairs(attrs) do req[k] = v end
            if type(req.refs) == "string" then
                req.refs = req.refs:words()
            end
            db:check_refs(req)
            return req
        end,
    })
end

local function reference(id)
    local db = ReqDB()
    local req = db:getreq(id)
    return ("*[`%s`](%s#%s)*"):format(req.id, req.file ~= db:output() and req.link or "", req.id)
end

local function matrix(file)
    local db = ReqDB()
    local t = { { "**File**", ("**[`%s`](%s)**"):format(file, file) } }
    fun.foreach(db:order(), function(id)
        local req = db:getreq(id)
        if req.file == file then
            t[#t+1] = {
                ("[`%s`](%s#%s)"):format(req.id, req.file ~= db:output() and req.link or "", req.id),
                req.title or "",
            }
            fun.foreach(req.refs or {}, function(ref_id, i)
                local req0 = db:getreq(ref_id)
                if i == 1 then t[#t+1] = { "", "" } end
                t[#t+1] = {
                    "",
                    ("- *[`%s`](%s#%s)*: %s"):format(req0.id, req0.file ~= req.file and req0.link or "", req0.id, req0.title or ""),
                }
            end)
        end
    end)
    local nb_columns = math.max(table.unpack(map(t, function(row) return #row end)))
    local ws = fun.map(fun.range(1, nb_columns), function(i)
        return math.max(table.unpack(fun.map(t, function(row) return #row[i] end)))
    end)
    local sep = "+-"..table.concat(fun.map(ws, function(w) return ("-"):rep(w) end), "-+-").."-+"
    fun.foreach(t, function(row)
        fun.foreach(ws, function(w, i)
            row[i] = row[i] .. (" "):rep(w - #row[i])
        end)
    end)
    t = fun.map(t, function(row) return "| "..table.concat(row, " | ").." |" end)
    local t2 = {}
    fun.foreach(t, function(row, i)
        if i > 2 and not row:match "^|%s*|" then
            t2[#t2+1] = sep
        end
        t2[#t2+1] = row
    end)
    t = fun.concat(
        { sep },
        t2,
        { sep }
    )
    table.insert(t, 3, (sep:gsub("-", "=")))
    return table.concat(t, "\n")
end

return setmetatable({}, {
    __call = function(_, ...) return define_requirement(...) end,
    __index = {
        test = function(...) return define_requirement(...) { test = true } end,
        ref = function(...) return reference(...) end,
        matrix = function(current_file)
            local db = ReqDB()
            local files = current_file == nil and {db:output()}
                          or current_file == "g" and db:files()
                          or fun.flatten(current_file)
            local matrices = fun.map(matrix, files)
            return table.concat(matrices, "\n\n")
        end,
        summary = function(current_file)
            local db = ReqDB()
            local files = current_file == nil and {db:output()}
                          or current_file == "g" and db:files()
                          or fun.flatten(current_file)
            local file_selection = {}
            fun.foreach(files, function(file) file_selection[file] = true end)
            local nb_reqs = 0
            local nb_reqs_covered = 0
            local nb_tests = 0
            local nb_tests_not_executed = 0
            local nb_tests_failed = 0
            local nb_tests_passed = 0
            local class = db:classify()
            fun.foreach(db, function(req)
                if file_selection[req.file] then
                    if req.test then
                        nb_tests = nb_tests + 1
                        if req.status == nil then nb_tests_not_executed = nb_tests_not_executed + 1 end
                        if req.status == false then nb_tests_failed = nb_tests_failed + 1 end
                        if req.status == true then nb_tests_passed = nb_tests_passed + 1 end
                    else
                        nb_reqs = nb_reqs + 1
                        if not class[req.id].not_covered then nb_reqs_covered = nb_reqs_covered + 1 end
                    end
                end
            end)
            return {
                reqs = nb_reqs,
                reqs_covered = nb_reqs_covered,
                reqs_not_covered = nb_reqs - nb_reqs_covered,
                req_coverage = 100 * nb_reqs_covered // nb_reqs,
                tests = nb_tests,
                tests_not_executed = nb_tests_not_executed,
                tests_failed = nb_tests_failed,
                tests_passed = nb_tests_passed,
                test_coverage = 100 * nb_tests_passed // nb_tests,
            }
        end,
        dot = function(_)
            local db = ReqDB()
            local g = {
                "digraph {",
                "graph [rankdir=LR];",
                "fontsize=10",
                "node [style=filled, color=lightgrey, shape=none, fontsize=8, margin=0, height=0.16]",
            }
            local groups = {}
            local links = {}
            local classes = db:classify()
            fun.foreach(db:order(), function(id)
                local req = db:getreq(id)
                local group = groups[req.file] or {}
                groups[req.file] = group
                group[#group+1] = ("%s[URL=\"%s#%s\", color=%s]"):format(
                    req.id, req.link, req.id,
                       classes[id].not_covered and     req.test and req.status == true  and COLOR.TEST_PASSED
                    or classes[id].not_covered and     req.test and req.status == false and COLOR.TEST_FAILED
                    or classes[id].not_covered and     req.test and req.status == nil   and COLOR.TEST_NOT_EXECUTED
                    or classes[id].not_covered and not req.test                         and COLOR.NOT_COVERED
                    or classes[id].orphan                                               and COLOR.ORPHAN
                                                                                        or  COLOR.NORMAL
                )
                fun.foreach(req.refs or {}, function(ref)
                    links[#links+1] = ("%s -> %s"):format(ref, req.id)
                end)
            end)
            local i = 0
            fun.tforeach(groups, function(nodes, file)
                i = i + 1
                g[#g+1] = "subgraph cluster_"..i.." {"
                g[#g+1] = ("  label = %q;"):format(fs.basename(file))
                fun.foreach(nodes, function(node) g[#g+1] = ("  %s;"):format(node) end)
                g[#g+1] = "}"
            end)
            g = fun.concat(g, groups, links, {"}"})
            return table.concat(g, "\n")
        end,
    },
})
