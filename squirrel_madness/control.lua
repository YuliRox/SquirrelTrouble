local runtime = require("scripts.runtime")

runtime.register()

if script.active_mods["factorio-test"] then
  require("__factorio-test__/init")(
    { "scripts.tests" },
    { load_luassert = true, game_speed = 1000 }
  )
end
