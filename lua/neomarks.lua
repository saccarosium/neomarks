local uv = vim.loop
local autocmd = vim.api.nvim_create_autocmd

Options = {
  storagefile = vim.fn.stdpath('data') .. "/pinboard.json",
  ui = {
    width = 60,
    height = 10,
    border = "rounded",
    title = "Neomarks",
    title_pos = "center",
  }
}

Storage = {}
Marks = {}
UI = {}

-- UTILS: {{{

local function make_relative(path)
  path = path:gsub(uv.cwd() .. "/", "")
  return path
end

local function make_absolute(path)
  return uv.cwd() .. '/' .. path
end

-- }}}
-- STORAGE: {{{

local function storage_get()
  local cwd = uv.cwd()
  Storage[cwd] = Storage[cwd] or {}
  return Storage[cwd]
end

local function storage_save()
  local file = uv.fs_open(Options.storagefile, "w", 438)
  if file then
    local ok, result = pcall(vim.json.encode, Storage)
    if not ok then
      error(result)
    end
    assert(uv.fs_write(file, result))
    assert(uv.fs_close(file))
  end
end

local function storage_load()
  local file = uv.fs_open(Options.storagefile, "r", 438)
  if file then
    local stat = assert(uv.fs_fstat(file))
    local data = assert(uv.fs_read(file, stat.size, 0))
    assert(uv.fs_close(file))
    local ok, result = pcall(vim.json.decode, data)
    Storage = ok and result or {}
  end
end

-- }}}
-- MARK: {{{

local function mark_new(filepath)
  return {
    file = file or vim.api.nvim_buf_get_name(0),
    pos = vim.api.nvim_win_get_cursor(0),
  }
end

local function mark_get(file)
  file = file or vim.api.nvim_buf_get_name(0)
  for _, mark in ipairs(Marks) do
    if mark.file == file then
      return mark
    end
  end
  return nil
end

local function mark_update_current_pos()
  local mark = mark_get()
  if mark then
    mark.pos = vim.api.nvim_win_get_cursor(0)
  end
end

local function mark_update_pos(mark)
  mark.pos = vim.api.nvim_win_get_cursor(0)
end

local function mark_follow(mark, action)
  vim.api.nvim_win_set_cursor(0, mark.pos)
end

-- }}}
-- UI: {{{

local function ui_get_items()
  local lines = vim.api.nvim_buf_get_lines(UI.buf, 0, -1, true)
  for i, line in ipairs(lines) do
    if line == "" or line:gsub("%s", "") == "" then
      table.remove(lines, i)
    else
      lines[i] = make_absolute(line)
    end
  end
  return lines
end

local function ui_save_items()
  local res = {}
  for _, file in ipairs(ui_get_items()) do
    local mark = mark_get(file)
    res[#res + 1] = mark or mark_new(file)
  end
  Storage[uv.cwd()] = res
  Marks = storage_get()
end

local function ui_select_item(action)
  local line = vim.api.nvim_get_current_line()
  local file = make_absolute(line)
  local mark = mark_get(file)
  if not mark then
    return
  end
end

local function ui_close()
  ui_save_items()
  vim.api.nvim_win_close(UI.win, true)
  UI = {}
end

local function ui_create()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    title = Options.ui.title,
    title_pos = Options.ui.title_pos,
    relative = "editor",
    border = Options.ui.border,
    width = Options.ui.width,
    height = Options.ui.height,
    row = math.floor(((vim.o.lines - Options.ui.height) / 2) - 1),
    col = math.floor((vim.o.columns - Options.ui.width) / 2),
  })

  vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal")
  vim.api.nvim_buf_set_name(buf, "marked-files")
  vim.api.nvim_buf_set_option(buf, "filetype", "neomarks")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")

  -- Keys that close the UI
  for _, k in ipairs({ "q", "<C-c>", "<ESC>" }) do
    vim.keymap.set('n', k, ui_close, { buffer = buf })
  end

  -- Disabled Keys
  for _, k in ipairs({ "i", "I", "c", "C", "D", "v", "s", "S" }) do
    vim.keymap.set('n', k, [[<nop>]], { buffer = buf })
  end

  -- Keys that select item under the cursor
  for k, a in pairs({
    ["<CR>"] = "edit",
    ["e"] = "edit",
    ["o"] = "split",
    ["O"] = "split",
    ["a"] = "vsplit",
    ["A"] = "vsplit",
  })
  do
    vim.keymap.set('n', k, function() ui_select_item(a) end, { buffer = buf })
  end

  autocmd("BufLeave", { once = true, callback = ui_close, })

  UI = {
    buf = buf,
    win = win,
    open = true
  }
end

local function ui_populate()
  local files = {}
  for _, mark in ipairs(Marks) do
    table.insert(files, make_relative(mark.file))
  end
  vim.api.nvim_buf_set_lines(UI.buf, 0, -1, false, files)
end

-- }}}

local M = {}

function M.setup(opts)
  storage_load()
  Marks = storage_get()
  Options = vim.tbl_deep_extend("force", Options, opts or {})
  local group = vim.api.nvim_create_augroup("Neomarks", {})
  autocmd("DirChanged", { group = group, callback = function() Marks = storage_get() end })
  autocmd("BufLeave", { group = group, callback = mark_update_current_pos, })
  autocmd("VimLeave", { group = group, callback = storage_save, })
end

function M.mark_file()
  local mark = mark_get()
  if not mark then
    table.insert(Marks, mark_new())
  end
end

function M.ui_toogle()
  if UI.open then
    ui_close()
  else
    ui_create()
    ui_populate()
  end
end

function M.jump_to(idx)
  mark_update_current_pos()
  local mark = Marks[idx]
  if mark then
    mark_follow(mark)
  end
end

return M

-- vim: foldmethod=marker
