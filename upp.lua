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

--[[----------------------------------------------------------------
--   OS detection
--]]----------------------------------------------------------------

local dir_sep
do
    local config = package.config:gmatch("[^\n]*")
    dir_sep = config()
end

--[[----------------------------------------------------------------
--   Various functions usable in macros
--]]----------------------------------------------------------------

local function id(x)
    return x
end

local function const(x)
    return function() return x end
end

local nop = const(nil)

function map(f, xs)
    local ys = {}
    for _, x in ipairs(xs) do table.insert(ys, f(x)) end
    return ys
end

function filter(p, xs)
    local ys = {}
    for _, x in ipairs(xs) do if p(x) then table.insert(ys, x) end end
    return ys
end

function range(a, b, step)
    step = step or (a < b and 1) or (a > b and -1)
    local r = {}
    if a < b then
        assert(step > 0, "step shall be positive")
        while a <= b do
            table.insert(r, a)
            a = a + step
        end
    elseif a > b then
        assert(step < 0, "step shall be negative")
        while a >= b do
            table.insert(r, a)
            a = a + step
        end
    else
        table.insert(r, a)
    end
    return r
end

local function clone(xs)
    return map(id, xs)
end

function concat(...)
    local t = {}
    for _, ti in ipairs({...}) do
        for _, v in ipairs(ti) do table.insert(t, v) end
    end
    return t
end

function merge(...)
    local t = {}
    for _, ti in ipairs({...}) do
        for k, v in pairs(ti) do t[k] = v end
    end
    return t
end

local function sort(t)
    local s = clone(t)
    table.sort(s)
    return s
end

local function uniq(t)
    local u = {}
    local seen = {}
    for _, x in ipairs(t) do
        if not seen[x] then
            table.insert(u, x)
            seen[x] = true
        end
    end
    return u
end

local base_pattern = dir_sep.."[^"..dir_sep.."]*$"
local dir_pattern = ".*"..dir_sep
local ext_pattern = "%.[^"..dir_sep.."]*$"

function dirname(path)
    return (upp(path):gsub(base_pattern, ""))
end

function basename(path)
    return (upp(path):gsub(dir_pattern, ""))
end

local function noext(path)
    return (upp(path):gsub(ext_pattern, ""))
end

function join(...)
    local ps = {}
    for _, p in ipairs({...}) do
        p = upp(p)
        if p:match("^"..dir_sep) then
            ps = {p}
        else
            table.insert(ps, p)
        end
    end
    return table.concat(ps, dir_sep)
end

function sh(command)
    local p = io.popen(upp(command))
    local out = p:read("a")
    assert(p:close())
    return out
end

function prefix(pre)
    return function(s) return upp(pre..s) end
end

function suffix(post)
    return function(s) return upp(s..post) end
end

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

local function keys(t)
    local ks = {}
    for k, _ in pairs(t) do table.insert(ks, k) end
    table.sort(ks)
    return ks
end

local function values(t)
    local ks = keys(t)
    local vs = {}
    for _, k in ipairs(ks) do table.insert(vs, t[k]) end
    return vs
end

local function items(t)
    local ks = keys(t)
    local is = {}
    for _, k in ipairs(ks) do table.insert(is, {k, t[k]}) end
    return is
end

--[[----------------------------------------------------------------
--   Command line parser
--]]----------------------------------------------------------------

local inputs = {}       -- {filename: true}
local outputs = {}      -- {filename: {lines}}
local scripts = {}      -- {filename: true}
local targets = {}      -- {filename: true} user defined targets (-MT option)
local known_input_files = {sep=" "}   -- list of input files separated by spaces to be usable in command lines
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
        scripts[path] = true
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
    local args = clone(arg)
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

function upp(content)
    local function format_value(x)
        local x_mt = getmetatable(x)
        if x_mt and x_mt.__tostring then return tostring(x) end
        if type(x) == "table" then
            -- each item of an array is a separate block of text
            return table.concat(map(tostring, x), x.sep or BLOCK_SEP or "\n")
        end
        return tostring(x)
    end
    return (content:gsub("([$:])(%b())", function(t, x)
        if t == "$" then -- x is an expression
            local y = (assert(load("return "..x:sub(2, -2), x, "t")))()
            -- if the expression can be evaluated, process it
            return upp(format_value(y))
        elseif t == ":" then -- x is a chunk
            local y = (assert(load(x:sub(2, -2), x, "t")))()
            -- if the chunk returns a value, process it
            -- otherwise leave it blank
            return y ~= nil and upp(format_value(y)) or ""
        end
    end))
end

function input_files() return known_input_files end

function output_file() return main_output_file end

function import(name) load_script(name)() end

function include(filename) return read_file(filename) end

function when(cond) return cond and id or const "" end

function emit(name)
    name = upp(name)
    if name:match "^-" then
        name = noext(output_stack.top())..name
    end
    return function(content)
        output_stack.with(name, function()
            add_input_file(name)
            process(content)
        end)
    end
end

local function populate_env()
    update_path(join(dirname(dirname(arg[0])), "lib", "upp"))
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
        local name = dep_file or (main_output_file and noext(main_output_file)..".d")
        if not name then die("The dependency file name is unknown, use -MF or -o") end
        local function mklist(...)
            return table.concat(
                filter(function(p) return p ~= stdin_name end,
                    sort(uniq(concat(table.unpack(map(keys, {...})))))), " ")
        end
        local deps = mklist(targets, outputs).." : "..mklist(inputs, scripts)
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
