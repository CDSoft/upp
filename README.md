# Universal PreProcessor

[UPP]: http://cdelord.fr/upp "Universal PreProcessor"
[Panda]: http://cdelord.fr/panda "Pandoc add-ons (Lua filters for Pandoc)"
[Lua]: http://www.lua.org/
[GitHub]: https://github.com/CDSoft/upp
[cdelord.fr]: http://cdelord.fr

UPP is a minimalist and generic text preprocessor using Lua macros.

If you need a Pandoc preprocessor, [Panda] may be a better choice.

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

- [Lua] (version 5.4.3)

## Installation from source

``` sh
$ git clone https://github.com/CDSoft/upp.git
$ cd upp
$ make install      # install upp in ~/.local/bin
```

## Precompiled binaries

It is recommended to install upp from the sources.

In case you need precompiled binaries (`upp` and Lua interpretor included),
the latest binaries are available here:

- [Linux UPP executable](http://cdelord.fr/upp/upp)
- [Windows UPP executable](http://cdelord.fr/upp/upp.exe)

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

Lua expressions are embedded in the document to process: `$( Lua expression )`.

Lua chunks can also be embedded in the document to add new definitions: `:( Lua chunk )`.

A macro is just a Lua function. Some macros are predefined by `upp`.
New macros can be defined by loading Lua scripts (options `-l` and `-e`) or embedded as Lua chunks.

Expression and chunks can return values. These values are formated according to their types:

- `__tostring` method from a custom metatable:
  if the value has a `__tostring` metamethod, it is used to format the value
- arrays (with no `__tostring` metamethod):
  items are concatenated (with `table.concat`) the separator is the first defined among:
    - the `sep` field of the table
    - the global `BLOCK_SEP` variable
    - `"\\n"`
- other types are formated by the default `tostring` function.

## Example

```
The user's home is $(os.getenv "HOME").
```

## Builtin macros

* All Lua functions and modules are available as `upp` macros (see <https://www.lua.org/manual/>)
* `input_files()`: list of the input files given on the command line.
* `output_file()`: output file given on the command line.
* `upp(Lua_expression)`: evaluate a Lua expression and outputs its result.
* `die(msg, errcode)`: print `msg` and exit with the error code `errcode`.
* `import(script)`: evaluate a Lua script (e.g. to define new macros).
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
Import a Lua script: :(import "script_name")
Embed a Lua script: :( Lua script )
Evaluate a Lua expression: $( 1 + lua_function(lua_variable) )
Include another document: $(include "other_document_name")
Conditional text: $(when (lang == "fr") [[ Ce texte est écrit en français ! ]])
```

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
