--!strict

local TestRunner = {}

export type Case = {
    name: string,
    run: () -> (),
}

export type Suite = {
    name: string,
    cases: { Case },
}

function TestRunner.equal(actual: any, expected: any, message: string?)
    if actual ~= expected then
        error(
            message
                or string.format("expected %s, received %s", tostring(expected), tostring(actual)),
            2
        )
    end
end

function TestRunner.truthy(value: any, message: string?)
    if not value then
        error(message or "expected a truthy value", 2)
    end
end

function TestRunner.throws(callback: () -> (), expectedText: string?)
    local ok, message = pcall(callback)
    if ok then
        error("expected callback to throw", 2)
    end

    if expectedText ~= nil and not string.find(tostring(message), expectedText, 1, true) then
        error(
            string.format(
                "expected error containing %q, received %s",
                expectedText,
                tostring(message)
            ),
            2
        )
    end
end

function TestRunner.run(suites: { Suite })
    local passed = 0
    local failed = 0

    for _, suite in suites do
        print(string.format("Suite: %s", suite.name))
        for _, case in suite.cases do
            local ok, message = xpcall(case.run, debug.traceback)
            if ok then
                passed += 1
                print(string.format("  PASS %s", case.name))
            else
                failed += 1
                warn(string.format("  FAIL %s\n%s", case.name, tostring(message)))
            end
        end
    end

    print(string.format("Luau tests complete: %d passed, %d failed", passed, failed))
    if failed > 0 then
        error(string.format("%d Luau tests failed", failed))
    end
end

return table.freeze(TestRunner)
