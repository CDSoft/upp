#!/usr/bin/env lua

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

local help = [[
usage: upp [options] [files]

where 'files' is the list of files ('-' for 'stdin').

options:

    -h              show help
    -l script       execute a Lua script
    -e expression   execute a Lua expression
    -p path         add a path to package.path
    -o file         redirect the output to 'file'
    -MT name        add `name` to the target list (see `-MD`)
    -MF name        set the dependency file name
    -MD             generate a dependency file

Environment variables:

    UPP_PATH        paths to add to package.path
]]

local F = require "fun"
local fs = require "fs"
local sh = require "sh"

--[[----------------------------------------------------------------
--   Various functions usable in macros
--]]----------------------------------------------------------------

_ENV.F = require "fun"
_ENV.fs = require "fs"

local nop = F.const(nil)

local function upp_on_strings(x)
    if type(x) == "string" then return upp(x) end
    if type(x) == "table" then return F.mapt(upp_on_strings, x) end
    return x
end

local function uppish(...)
    local funcs = F.compose{...}
    return function(...)
        return funcs(table.unpack(F.map(upp_on_strings, {...})))
    end
end

local function get_first(x)
    return x
end

_ENV.basename = uppish(fs.basename)
_ENV.dirname = uppish(fs.dirname)
_ENV.noext = uppish(get_first, fs.splitext)
_ENV.join = uppish(fs.join)

_ENV.sh = uppish(assert, sh.read)

_ENV.prefix = uppish(F.prefix)
_ENV.suffix = uppish(F.suffix)

_ENV.map = function(f, xs) return F.map(f, F.map(upp_on_strings, xs)) end
_ENV.mapi = function(f, xs) return F.mapi(f, F.map(upp_on_strings, xs)) end
_ENV.mapt = function(f, t) return F.mapt(f, F.mapt(upp_on_strings, t)) end
_ENV.mapk = function(f, t) return F.mapk(f, F.mapt(upp_on_strings, t)) end

_ENV.filter = function(f, xs) return F.filter(f, F.filter(upp_on_strings, xs)) end
_ENV.filteri = function(f, xs) return F.filteri(f, F.filter(upp_on_strings, xs)) end
_ENV.filtert = function(f, t) return F.filtert(f, F.filtert(upp_on_strings, t)) end
_ENV.filterk = function(f, t) return F.filterk(f, F.filtert(upp_on_strings, t)) end

_ENV.range = F.range

_ENV.concat = function(xss) return F.map(upp_on_strings, xss):concat() end
_ENV.merge = function(ts) return F.mapt(upp_on_strings, ts):merge() end

local _atexit = {}

function atexit(chunk)
    table.insert(_atexit, chunk)
end

local function run_atexit()
    return function(_)
        for i = #_atexit, 1, -1 do
            _atexit[i]()
        end
    end
end

local function file_stack(handlers)
    local stack = {}
    local s = {}
    handlers = handlers or {}
    local push_handler = handlers.push_handler or nop
    local pop_handler = handlers.pop_handler or nop
    function s.top()
        if #stack > 0 then return stack[#stack] end
    end
    function s.push(name)
        push_handler(name)
        table.insert(stack, name)
    end
    function s.pop()
        pop_handler()
        table.remove(stack)
    end
    function s.with(name, f)
        s.push(name)
        local ret = f()
        s.pop()
        return ret
    end
    return s
end

--[[----------------------------------------------------------------
--   Command line parser
--]]----------------------------------------------------------------

local inputs = {}       -- {filename: true}
local outputs = {}      -- {filename: {lines}}
local targets = {}      -- {filename: true} user defined targets (-MT option)
local known_input_files = {sep=" "}   -- list of input files separated by spaces to be usable in command lines
local loaded_files = {} -- {filename: true}
local main_output_file = nil
local dep_file = nil
local dep_file_enabled = false
local output_stack = file_stack {
    push_handler = function(name) outputs[name] = outputs[name] or {} end
}

local stdin_name = "-"
local stdout_name = "-"

function die(msg, errcode)
    io.stderr:write("upp: "..msg.."\n")
    os.exit(errcode or 1)
end

local function add_package_path(path)
    local config = package.config:gmatch("[^\n]*")
    local dir_sep = config()
    local template_sep = config()
    local template = config()
    local new_path = path..dir_sep..template..".lua"
    package.path = new_path .. template_sep .. package.path
end

local function update_path(paths)
    if not paths then return end
    for path in paths:gmatch "[^:]*" do
        add_package_path(path)
    end
end

local function load_script(filename)
    return function()
        local path = assert(package.searchpath(filename:gsub("%.lua$", ""), package.path))
        loaded_files[path] = true
        assert(loadfile(path, "t"))()
    end
end

local function eval_expr(expr)
    return function()
        assert(load(expr, expr, "t"))()
    end
end

local function set_output(output)
    if output_stack.top() then die("multiple -o option") end
    main_output_file = output
    output_stack.push(output)
    return nop
end

local function set_stdout()
    if not output_stack.top() then
        set_output(stdout_name)
    end
    return nop
end

local function add_path(path)
    return function() add_package_path(path) end
end

local function add_target(name)
    targets[name] = true
    return nop
end

local function set_dep_file(name)
    if dep_file then die("multiple -MF option") end
    dep_file = name
    dep_file_enabled = true
    return nop
end

local function enable_dep_file()
    dep_file_enabled = true
    return nop
end

local function process(content)
    table.insert(outputs[output_stack.top()], upp(content))
end

local function add_input_file(filename)
    table.insert(known_input_files, filename)
end

local function process_stdin()
    add_input_file(stdin_name)
    return function()
        local content = io.stdin:read "a"
        process(content)
    end
end

local function read_file(filename)
    local f = assert(io.open(filename))
    local content = f:read "a"
    f:close()
    inputs[filename] = true
    return content
end

local function process_file(filename)
    add_input_file(filename)
    return function()
        process(read_file(filename))
    end
end

local function parse_args()
    local args = F.clone(arg)
    local need_to_process_stdin = true
    local actions = {}
    local function shift(n) for _ = 1,n do table.remove(args, 1) end end
    while #args > 0 do
        local action = nil
        if args[1] == "-h" then print(help); os.exit(0)
        elseif args[1] == "-l" then action = load_script(args[2]); shift(2)
        elseif args[1] == "-e" then action = eval_expr(args[2]); shift(2)
        elseif args[1] == "-o" then action = set_output(args[2]); shift(2)
        elseif args[1] == "-p" then action = add_path(args[2]); shift(2)
        elseif args[1] == "-MT" then action = add_target(args[2]); shift(2)
        elseif args[1] == "-MF" then action = set_dep_file(args[2]); shift(2)
        elseif args[1] == "-M" then action = enable_dep_file(); shift(1)
        elseif args[1] == "-MD" then action = enable_dep_file(); shift(1)
        elseif args[1] == stdin_name then action = process_stdin(); shift(1); need_to_process_stdin = false
        elseif args[1] == "--" then shift(1); break
        elseif args[1]:match "^%-" then die("Unknown option: "..args[1].."\n\n"..help)
        else action = process_file(args[1]); shift(1); need_to_process_stdin = false
        end
        table.insert(actions, action)
    end
    while #args > 0 do
        table.insert(actions, process_file(args[1])); shift(1); need_to_process_stdin = false
    end
    if need_to_process_stdin then table.insert(actions, process_stdin()) end
    table.insert(actions, set_stdout())
    table.insert(actions, run_atexit())
    return actions
end

--[[----------------------------------------------------------------
--   Preprocessor
--]]----------------------------------------------------------------

local upp_enabled = true

function upp(content)
    local function format_value(x)
        local x_mt = getmetatable(x)
        if x_mt and x_mt.__tostring then return tostring(x) end
        if type(x) == "table" then
            -- each item of an array is a separate block of text
            return table.concat(F.map(tostring, x), x.sep or BLOCK_SEP or "\n")
        end
        return tostring(x)
    end
    return (content:gsub("([$:@?])(@?)(%b())", function(t, t2, x)
        if (t == "$" or (t == "@" and t2 == "")) and upp_enabled then -- x is an expression
            local y = (assert(load("return "..x:sub(2, -2), x, "t")))()
            -- if the expression can be evaluated, process it
            return upp(format_value(y))
        elseif (t == ":" or (t == "@" and t2 == "@")) and upp_enabled then -- x is a chunk
            local y = (assert(load(x:sub(2, -2), x, "t")))()
            -- if the chunk returns a value, process it
            -- otherwise leave it blank
            return y ~= nil and upp(format_value(y)) or ""
        elseif t == "?" and t2 == "" then -- enable/disable verbatim sections
            upp_enabled = (assert(load("return "..x:sub(2, -2), x, "t")))()
            return ""
        end
    end))
end

function input_files() return known_input_files end

function output_file() return main_output_file end

function include(filename) return read_file(filename) end

function when(cond) return cond and F.id or F.const "" end

function emit(name)
    name = upp(name)
    if name:match "^-" then
        name = fs.splitext(output_stack.top())..name
    end
    return function(content)
        output_stack.with(name, function()
            add_input_file(name)
            process(content)
        end)
    end
end

local function populate_env()
    update_path(fs.join(fs.dirname(fs.dirname(arg[0])), "lib", "upp"))
    update_path(os.getenv "UPP_PATH")
end

local function process_args(actions)
    populate_env()
    for _, action in ipairs(actions) do action() end
end

local function write_outputs()
    for name, contents in pairs(outputs) do
        local f = (name == stdout_name) and io.stdout or assert(io.open(name, "w"))
        f:write(table.concat(contents))
        f:close()
    end
end

local function write_dep_file()
    if dep_file_enabled then
        local name = dep_file or (main_output_file and fs.splitext(main_output_file)..".d")
        if not name then die("The dependency file name is unknown, use -MF or -o") end
        local function mklist(...)
            return F{...}
                :merge()
                :keys()
                :filter(function(p) return p ~= stdin_name end)
                :unwords()
        end
        local scripts = {}
        for modname, _ in pairs(package.loaded) do
            local path = package.searchpath(modname, package.path)
            if path then scripts[path] = true end
        end
        local deps = mklist(targets, outputs).." : "..mklist(inputs, scripts, loaded_files)
        local f = assert(io.open(name, "w"))
        f:write(deps.."\n")
        f:close()
    end
end

local function main()
    local actions = parse_args()
    process_args(actions)
    write_dep_file()
    write_outputs()
end

main()
