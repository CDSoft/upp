# UPP test suite

:(  local x = 1
    local y = 2
    z = x + y
)

- foo defined on the command line: foo = $(foo)
- foofoo defined in test_lib.lua: foofoo = $(foofoo)
- z defined in an embedded chunk: z = $(z)
- undefined is not defined: undefined = $(undefined)

foofoo can be undefined: :(foofoo = nil)foofoo = $(foofoo)
and redefined by reloading test_lib.lua: :(import "test_lib.lua")foofoo = $(foofoo)

$(include "tests/test_include.md")

# Some maths

1 + 1 = $(1 + 1)
cos(π) = $(math.cos(math.pi))

# Conditionals

:(lang = "fr")

lang = $(lang)

$(when(lang=="fr") [[
lang = $(lang) => Ce texte en français doit apparaitre !
]])

$(when(lang=="en") [[
lang = $(lang) => You should not see this text in english!
]])
