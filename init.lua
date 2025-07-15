local thisInitFile = debug.getinfo(1).source:match('@?(.*)')
local cwd = vim.fs.dirname(thisInitFile)
local appname = vim.env.NVIM_APPNAME or 'nvim'

vim.env.XDG_CONFIG_HOME = cwd
vim.env.XDG_DATA_HOME = vim.fs.joinpath(cwd, '.xdg', 'data')
vim.env.XDG_STATE_HOME = vim.fs.joinpath(cwd, '.xdg', 'state')
vim.env.XDG_CACHE_HOME = vim.fs.joinpath(cwd, '.xdg', 'cache')
vim.fn.mkdir(vim.fs.joinpath(vim.env.XDG_CACHE_HOME, appname), 'p')
local stdPathConfig = vim.fn.stdpath('config')

vim.opt.runtimepath:prepend(stdPathConfig)
vim.opt.packpath:prepend(stdPathConfig)

local extuiExists, extui = pcall(require, 'vim._extui')
if extuiExists then
  extui.enable({enable = true, msg = {target = 'msg'}})
end

local function gitClone(url, installPath, branch)
  if vim.fn.isdirectory(installPath) ~= 0 then
    return
  end

  local command = {'git', 'clone', '--', url, installPath}
  if branch then
    table.insert(command, 3, '--branch')
    table.insert(command, 4, branch)
  end

  vim.notify(('Cloning %s dependency into %s...'):format(url, installPath), vim.log.levels.INFO, {})
  local sysObj = vim.system(command, {}):wait()
  if sysObj.code ~= 0 then
    error(sysObj.stderr)
  end
  vim.notify(sysObj.stdout)
  vim.notify(sysObj.stderr, vim.log.levels.WARN)
end

local pluginsPath = vim.fs.joinpath(cwd, 'nvim/pack/plugins/opt')
vim.fn.mkdir(pluginsPath, 'p')
pluginsPath = vim.uv.fs_realpath(pluginsPath)

--- @type table<string, {url:string, branch: string?}>
local plugins = {
  -- [''] = {url = ''},
}

for name, repo in pairs(plugins) do
  local installPath = vim.fs.joinpath(pluginsPath, name)
  gitClone(repo.url, installPath, repo.branch)
  vim.opt.runtimepath:append(installPath)
  -- vim.cmd.packadd({args = {name}, bang = true})
end

local function init()
end

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = init,
})
