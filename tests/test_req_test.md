## Tests

@@(REQTARGET = "test.html")

@(req.test "R_TEST_X: title of TEST X" {
    refs = "R_SPEC_1 R_SPEC_2",
    status = true,
})

@(req.test "R_TEST_Y: title of TEST Y" {
    refs = "R_SPEC_2",
    status = false,
})

@(req.test "R_TEST_Z: title of TEST Z" {
    refs = "R_SPEC_3",
    status = nil,
})

### Coverage matrix

@(req.matrix())
