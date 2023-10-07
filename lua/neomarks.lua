local uv = vim.loop
local autocmd = vim.api.nvim_create_autocmd

Options = {
  storagefile = vim.fn.stdpath('data') .. "/neomarks.json",
  menu = {
    width = 60,
    height = 10,
    border = "rounded",
    title = "Neomarks",
    title_pos = "center",
  }
}

Storage = {}
Marks = {}
Menu = nil

-- UTILS: {{{

local function path_sep()
  if jit then
    local os = string.lower(jit.os)
    return os ~= "windows" and "/" or "\\"
  else
    return package.config:sub(1, 1)
  end
end

local function make_absolute(path)
  local cwd = uv.cwd() .. path_sep()
  path = cwd .. path
  return path
end

local function make_relative(path)
  local cwd = uv.cwd()
  if path == cwd then
    path = "."
  else
    if path:sub(1, #cwd) == cwd then
      path = path:sub(#cwd + 2, -1)
    end
  end
  return path
end

local function create_float()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    title = Options.menu.title,
    title_pos = Options.menu.title_pos,
    relative = "editor",
    border = Options.menu.border,
    width = Options.menu.width,
    height = Options.menu.height,
    row = math.floor(((vim.o.lines - Options.menu.height) / 2) - 1),
    col = math.floor((vim.o.columns - Options.menu.width) / 2),
  })

  vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal")
  vim.api.nvim_buf_set_option(buf, "filetype", "neomarks")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")

  assert(buf and win, "Couldn't create menu correctly")

  return win, buf
end

-- }}}
-- STORAGE: {{{

local function storage_get()
  local cwd = uv.cwd()
  Storage[cwd] = Storage[cwd] or {}
  return Storage[cwd]
end

local function storage_save()
  for k, v in pairs(Storage) do
    if vim.tbl_isempty(v) then
      Storage[k] = nil
    end
  end
  local file = uv.fs_open(Options.storagefile, "w", 438)
  if not file then
    error("Couldn't save to storagefile")
  end
  local ok, result = pcall(vim.json.encode, Storage)
  if not ok then
    error(result)
  end
  assert(uv.fs_write(file, result))
  assert(uv.fs_close(file))
end

local function storage_load()
  local file = uv.fs_open(Options.storagefile, "r", 438)
  if not file then
    return
  end
  local stat = assert(uv.fs_fstat(file))
  local data = assert(uv.fs_read(file, stat.size, 0))
  assert(uv.fs_close(file))
  local ok, result = pcall(vim.json.decode, data)
  Storage = ok and result or {}
end

-- }}}
-- MARK: {{{

local function mark_new(file)
  return {
    file = file or vim.api.nvim_buf_get_name(0),
    buffer = vim.api.nvim_get_current_buf(),
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

local function mark_update_pos(mark)
  mark.pos = vim.api.nvim_win_get_cursor(0)
end

local function mark_update_current_pos()
  local mark = mark_get()
  if not mark then
    return
  end
  mark_update_pos(mark)
end

local function mark_follow(mark)
  assert(mark, "Mark not valid")
  local buf_valid = vim.api.nvim_buf_is_valid(mark.buffer)
  local buf_name = buf_valid and vim.api.nvim_buf_get_name(mark.buffer)
  if buf_valid and buf_name == mark.file then
    vim.cmd.buffer(mark.buffer)
  else
    vim.cmd.edit(mark.file)
  end
  vim.api.nvim_win_set_cursor(0, mark.pos)
end

-- }}}
-- MENU: {{{

local function menu_get_items()
  local lines = vim.api.nvim_buf_get_lines(Menu.buf, 0, -1, true)
  for i, line in ipairs(lines) do
    if line == "" or line:gsub("%s", "") == "" then
      table.remove(lines, i)
    else
      lines[i] = make_absolute(line)
    end
  end
  return lines
end

local function menu_save_items()
  local res = {}
  for _, file in ipairs(menu_get_items()) do
    local mark = mark_get(file)
    res[#res + 1] = mark or mark_new(file)
  end
  Storage[uv.cwd()] = res
  Marks = storage_get()
end

local function menu_select_item()
  local line = vim.api.nvim_get_current_line()
  local file = make_absolute(line)
  local mark = mark_get(file)
  if not mark then
    return
  end
  mark_follow(mark)
end

local function menu_close()
  menu_save_items()
  vim.api.nvim_win_close(Menu.win, true)
  Menu = nil
end

local function menu_open()
  local win, buf = create_float()

  for k, v in pairs({
    ["a"] = [[<nop>]],
    ["o"] = [[<nop>]],
    ["i"] = [[<nop>]],
    ["c"] = [[<nop>]],
    ["e"] = menu_select_item,
    ["q"] = menu_close,
    ["<C-c>"] = menu_close,
    ["<ESC>"] = menu_close,
    ["<CR>"] = menu_select_item,
  }) do
    -- This is done so I can write only the lower case verison of a letter
    -- and remap also the upper case version.
    local upper = string.byte(k) - 32
    vim.keymap.set('n', k, v, { buffer = buf })
    if upper >= 65 or upper <= 122 then
      vim.keymap.set('n', string.char(upper), v, { buffer = buf })
    end
  end

  autocmd("BufLeave", { once = true, callback = menu_close, })

  Menu = {
    buf = buf,
    win = win,
  }
end

local function menu_populate()
  local files = {}
  for _, mark in ipairs(Marks) do
    table.insert(files, make_relative(mark.file))
  end
  vim.api.nvim_buf_set_lines(Menu.buf, 0, -1, false, files)
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
  if mark then
    return
  end
  table.insert(Marks, mark_new())
end

function M.menu_toogle()
  if Menu then
    menu_close()
  else
    menu_open()
    menu_populate()
  end
end

function M.jump_to(idx)
  mark_update_current_pos()
  local mark = Marks[idx]
  if not mark then
    return
  end
  mark_follow(mark)
end

return M

-- vim: foldmethod=marker
