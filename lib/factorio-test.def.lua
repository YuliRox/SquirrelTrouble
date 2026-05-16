---@meta
---@diagnostic disable: missing-return

-- luassert global (replaces built-in assert in test context)
---@class Luassert
---@overload fun(v: any, message?: string): any
-- matchers (callable directly or via is_ prefix)
---@field is_true      fun(v: any): nil
---@field is_false     fun(v: any): nil
---@field is_truthy    fun(v: any): nil
---@field is_falsy     fun(v: any): nil
---@field is_nil       fun(v: any): nil
---@field is_boolean   fun(v: any): nil
---@field is_number    fun(v: any): nil
---@field is_string    fun(v: any): nil
---@field is_table     fun(v: any): nil
---@field is_function  fun(v: any): nil
---@field is_userdata  fun(v: any): nil
---@field is_thread    fun(v: any): nil
-- negated variants (is + not modifier)
---@field is_not_nil       fun(v: any): nil
---@field is_not_true      fun(v: any): nil
---@field is_not_false     fun(v: any): nil
---@field is_not_truthy    fun(v: any): nil
---@field is_not_falsy     fun(v: any): nil
-- assertions
---@field truthy    fun(v: any): nil
---@field falsy     fun(v: any): nil
---@field same      fun(expected: any, actual: any): nil
---@field equal     fun(expected: any, actual: any): nil
---@field equals    fun(expected: any, actual: any): nil
---@field near      fun(expected: number, actual: number, tolerance: number): nil
---@field matches   fun(pattern: string, actual: string): nil
---@field match     fun(pattern: string, actual: string): nil
---@field unique    fun(list: table): nil
---@field error     fun(func: function, ...): nil
---@field errors    fun(func: function, ...): nil
---@field error_matches fun(func: function, pattern: string): nil
---@field error_match   fun(func: function, pattern: string): nil
-- message modifier (chainable)
---@field message   fun(msg: string): Luassert

---@type Luassert
assert = nil

---@type TestCreator
test = nil
---@type TestCreator
it = nil
---@type DescribeCreator
describe = nil
---@type LifecycleFn
before_all = nil
---@type LifecycleFn
after_all = nil
---@type LifecycleFn
before_each = nil
---@type LifecycleFn
after_each = nil
---@type LifecycleFn
after_test = nil

---@param timeout number|nil
---@overload fun()
function async(timeout) end

function done() end

---@param func OnTickFn
function on_tick(func) end

---@param ticks number
---@param func TestFn
function after_ticks(ticks, func) end

---@param ticks number
function ticks_between_tests(ticks) end

---@param ... string
function tags(...) end

---@class FactorioTestConfig
---@field default_timeout number | nil
---@field default_ticks_between_tests number | nil
---@field game_speed number | nil
---@field log_passed_tests boolean | nil
---@field log_skipped_tests boolean | nil
---@field test_pattern string | nil
---@field tag_whitelist string[] | nil
---@field tag_blacklist string[] | nil
---@field before_test_run fun() | nil
---@field after_test_run fun() | nil
---@field sound_effects boolean | nil

---@alias TestFn fun(): nil
---@alias HookFn TestFn
---@alias OnTickFn (fun(tick: number): nil) | (fun(tick: number): boolean)

---@class TestCreatorBase
---@overload fun(name: string, func: TestFn): TestBuilder<TestFn>
local TestCreatorBase = {}

---@generic T
---@param values T[][]
---@return fun(name: string, func: fun(...: T): nil): nil
---@overload fun<T>(values: T[]): fun(name: string, func: fun(v: T): nil): nil
function TestCreatorBase.each(values) end

---@class TestCreator : TestCreatorBase
---@overload fun(name: string, func: TestFn): TestBuilder<TestFn>
---@field skip TestCreatorBase
---@field only TestCreatorBase
local TestCreator = {
    ---@param name string
    todo = function(name)
    end
}

---@class TestBuilder<T>
local TestBuilder = {}

---@generic T
---@param func T
---@return TestBuilder<T>
function TestBuilder.after_script_reload(func) end

---@generic T
---@param func T
---@return TestBuilder<T>
function TestBuilder.after_mod_reload(func) end

---@class DescribeCreatorBase
---@overload fun(name: string, func: TestFn): nil
local DescribeCreatorBase = {}

---@generic T
---@param values T[][]
---@return fun(name: string, func: fun(...: T): nil): nil
---@overload fun<T>(values: T[]): fun(name: string, func: fun(v: T): nil): nil
function DescribeCreatorBase.each(values) end

---@class DescribeCreator : DescribeCreatorBase
---@overload fun(name: string, func: TestFn): nil
---@field skip DescribeCreatorBase
---@field only DescribeCreatorBase

---@alias LifecycleFn fun(func: HookFn): nil