
pi = math.pi
abs = math.abs

local template_f1 = {__tostring = function(t) return ("assert(fabs(%s(%f) - %f) < 1e-6);"):format(t.f, t.x1, t.y) end}

function test_f1(fname)
    return function(xs)
        return F.map(Test_f1(fname), xs)
    end
end

function Test_f1(fname)
    return function(x1)
        local t = {
            f = fname,
            x1 = x1,
            y = math[fname](x1),
        }
        return setmetatable(t, template_f1)
    end
end
