-- Ensure git is available for plugins like gitsigns
local function setup_git_path()
  -- Check if git is already available
  if vim.fn.executable("git") == 1 then
    return
  end

  -- Common git locations on NixOS and other systems
  local git_paths = {
    "/run/current-system/sw/bin",
    "/usr/bin",
    "/usr/local/bin",
    "/opt/homebrew/bin",
    vim.env.HOME .. "/.nix-profile/bin",
  }

  -- Add git paths to PATH
  for _, path in ipairs(git_paths) do
    if vim.fn.isdirectory(path) == 1 then
      vim.env.PATH = path .. ":" .. vim.env.PATH
    end
  end

  -- Verify git is now available
  if vim.fn.executable("git") == 0 then
    vim.notify("Warning: git executable not found in PATH", vim.log.levels.WARN)
  end
end

-- Run setup
setup_git_path()