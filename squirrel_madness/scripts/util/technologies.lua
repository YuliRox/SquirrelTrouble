local M = {}

function M.force_has_technology(force, technology_name)
  if not (force and force.valid and force.technologies) then
    return false
  end

  local technology = force.technologies[technology_name]
  return technology and technology.valid and technology.researched
end

return M
