# Universal PreProcessor

[UPP]: http://cdelord.fr/upp "Universal PreProcessor"
[Panda]: http://cdelord.fr/panda "Pandoc add-ons (Lua filters for Pandoc)"
[Lua]: http://www.lua.org/
[LuaX]: https://github.com/CDSoft/luax
[GitHub]: https://github.com/CDSoft/upp
[cdelord.fr]: http://cdelord.fr

UPP is a minimalist and generic text preprocessor using Lua macros.

If you need a Pandoc preprocessor, [Panda] may be a better choice.

# Warning: UPP may not be supported in the future

Their is no plan to support UPP from now on.
UPP is meant to be replaced by [ypp](http://cdelord.fr/ypp) which combines [UPP] and [Panda] features.

# Open source

[UPP] is an Open source software.
Anybody can contribute on [GitHub] to:

- suggest or add new features
- report or fix bugs
- improve the documentation
- add some nicer examples
- find new usages
- ...

# Installation

## Prerequisites

- [Lua] (version 5.4.4)
- [LuaX]

## Installation from source

``` sh
$ git clone https://github.com/CDSoft/luax.git && make -C luax install
$ git clone https://github.com/CDSoft/upp.git
$ cd upp
$ make install      # install upp in ~/.local/bin
```

`make install` installs `upp` in `~/.local/bin`.
The `PREFIX` variable can be defined to install `upp` to a different directory
(e.g. `make install PREFIX=/usr` to install `upp` in `/usr/bin`).

**Note**: `upp` can also be installed with [makex](https://github.com/CDSoft/makex).

## Precompiled binaries

It is recommended to install upp from the sources.

In case you need precompiled binaries (`upp` and [Luax](http://cdelord.fr/luax)
interpretor included), the latest binaries are available here: [UPP precompiled
binaries](http://cdelord.fr/upp/release.html)

## Test

``` sh
$ make test
```

# Usage

``` sh
$ upp [options] files
```

where `files` is the list of files (`-` for `stdin`).

options:

- `-h`: show help
- `-l script`: execute a Lua script
- `-e expression`: execute a Lua expression
- `-o file`: redirect the output to `file`
- `-p path`: add a path to `package.path`
- `-MT name`: add `name` to the target list (see `-MD`)
- `-MF name`: set the dependency file name
- `-MD`: generate a dependency file

# Documentation

Lua expressions are embedded in the document to process: `$( Lua expression )`
or `@( Lua expression )`.

Lua chunks can also be embedded in the document to add new definitions: `:( Lua
chunk )` or `@@( Lua chunk )`.

The `@` notation has been added as it is more Markdown syntax friendly (`$` may
interfere with LaTeX equations).

A macro is just a Lua function. Some macros are predefined by `upp`. New macros
can be defined by loading Lua scripts (options `-l` and `-e`) or embedded as
Lua chunks.

Expression and chunks can return values. These values are formatted according
to their types:

- `__tostring` method from a custom metatable: if the value has a `__tostring`
  metamethod, it is used to format the value
- arrays (with no `__tostring` metamethod): items are concatenated (with
  `table.concat`) the separator is the first defined among:
    - the `sep` field of the table
    - the global `BLOCK_SEP` variable
    - `"\\n"`
- other types are formatted by the default `tostring` function.

## Example

```
The user's home is $(os.getenv "HOME").
```

## Builtin macros

* All Lua and Luax functions and modules are available as `upp` macros
  (see <https://www.lua.org/manual/> and <http://cdelord.fr/luax/#built-in-modules>).
  E.g.:
    * `require(module)`: import a Lua script (e.g. to define new macros, variables, ...).
* `input_files()`: list of the input files given on the command line.
* `output_file()`: output file given on the command line.
* `upp(Lua_expression)`: evaluate a Lua expression and outputs its result.
* `die(msg, errcode)`: print `msg` and exit with the error code `errcode`.
* `include(filename)`: include a file in the currently preprocessed file.
* `when(condition)(text)`: process `text` if `condition` is true.
* `map(f, xs)`: return `{f(x) | x ∈ xs}`.
* `filter(p, xs)`: return `{x | x ∈ xs ∧ p(x)}`.
* `range(a, b, [step])`: return `{a, a+step, ..., b}`.
* `concat(l1, l2, ... ln)`: concatenate the lists `l1`, `l2`, ... `ln` into a new single list.
* `merge(t1, t2, ... tn)`: merge the fields of the tables `t1`, `t2`, ... `tn` into a new single table.
* `dirname(path)`: return the directory part of `path`.
* `basename(path)`: return the filename part of `path`.
* `join(p1, p2, ... pn)`: build a path (`p1/p2/.../pn`) from the path components `p1`, `p2`, ... `pn`.
* `sh(cmd)`: run the shell command `cmd` and return its output (`stdout`).
* `prefix(p)`: build a function that adds the prefix `p` to a string.
* `suffix(p)`: build a function that adds the suffix `p` to a string.
* `atexit(f)`: register the function `f`. `f` will be executed before writing the final document.
* `emit(filename)(content)`: write `content` to a new file named `filename`.

## Example

```
Import a Lua script: :(require "module_name")
Embed a Lua script: :( Lua script )
Evaluate a Lua expression: $( 1 + lua_function(lua_variable) )
Include another document: $(include "other_document_name")
Conditional text: $(when (lang == "fr") [[ Ce texte est écrit en français ! ]])
```

# Additional packages

`upp` comes with some packages (already included in the binaries, no external
dependancies are required).

## counter

The `counter` function generates counters:

* `counter(name, initial_value)`: create a counter named `name` with `initial_value` as the initial value.
  It returns `initial_value`. The default initial value is `1`.
* `counter(name)`: incremental the previous value of the counter `name` and returns it.

## req

The package `req` provides basic requirement management tools.

**Warning**: this package is still experimental and not tested...

# License

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

# Feedback

Your feedback and contributions are welcome.
You can contact me at [cdelord.fr].
