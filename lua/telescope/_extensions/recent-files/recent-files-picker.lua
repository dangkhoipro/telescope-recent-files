local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local conf = require"telescope.config".values
local utils = require "utils"

local M = {}

local options
local defaults = {stat_files = true}

local recent_bufs = {}
local recent_cnt = 0

M.setup = function(opts)
  print("setup called " .. vim.inspect(opts))
  options = utils.assign({{}, defaults, opts})
end

_G.telescope_recent_files_buf_enter = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  if options.normalize_file_name then
    file = options.normalize_file_name(file)
  end
  if file ~= "" then
    recent_bufs[file] = recent_cnt
    recent_cnt = recent_cnt + 1
  end
end

vim.cmd [[
augroup recents
  au!
  au! BufEnter * lua telescope_recent_files_buf_enter()
augroup END
]]

local function add_recent_file(results, file_path)
  if options.normalize_file_name then
    file_path = options.normalize_file_name(file_path)
  end
  local should_add = true
  if vim.tbl_contains(results, file_path) then
    should_add = false
  elseif options.ignore_pattern and string.find(file_path, options.ignore_pattern) then
    should_add = false
  end
  if should_add then
    table.insert(results, file_path)
  end
end

local function prepare_recent_files(opts)
  opts = utils.assign({}, options, opts)
  local current_buffer = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buffer)
  local results = {}
  local old_files_map = {}

  for i, file in ipairs(vim.v.oldfiles) do
    if file ~= current_file then
      add_recent_file(results, file)
      old_files_map[file] = i
    end
  end
  for buffer_file in pairs(recent_bufs) do
    if buffer_file ~= current_file then
      add_recent_file(results, buffer_file)
    end
  end
  table.sort(results, function(a, b)
    local a_recency = recent_bufs[a]
    local b_recency = recent_bufs[b]
    if a_recency == nil and b_recency == nil then
      local a_old = old_files_map[a]
      local b_old = old_files_map[b]
      if a_old == nil and b_old == nil then
        return a < b
      end
      if a_old == nil then
        return false
      end
      if b_old == nil then
        return true
      end
      return a_old < b_old
    end
    if a_recency == nil then
      return false
    end
    if b_recency == nil then
      return true
    end
    return b_recency < a_recency
  end)
  return results
end

M.recent_files = function(opts)
  pickers.new(opts, {
    prompt_title = "Recent files",
    finder = finders.new_table {
      results = prepare_recent_files(opts),
      entry_maker = opts.entry_maker or make_entry.gen_from_file()
    },
    sorter = conf.file_sorter(),
    previewer = conf.file_previewer()
  }):find()
end

return M
