local storage_lib = {}

function storage_lib.ensure()
  storage.version = storage.version or 3
  storage.regions = storage.regions or {}
  storage.last_refresh_tick = storage.last_refresh_tick or 0
  storage.seeded_chunks = storage.seeded_chunks or {}
  storage.saplings = storage.saplings or {}
  storage.next_sapling_id = storage.next_sapling_id or 1
  storage.force_tutorials = storage.force_tutorials or {}
end

return storage_lib
