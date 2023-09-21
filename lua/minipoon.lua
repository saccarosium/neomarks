local uv = vim.loop

Options = {
  storefile = vim.fn.stdpath('data') .. "/minipoon.json"
}

Store = {}
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

local function store_get()
  local cwd = uv.cwd()
  Store[cwd] = Store[cwd] or {}
  return Store[cwd]
end

local function store_save()
  local file = uv.fs_open(Options.storefile, "w", 438)
  if file then
    local ok, result = pcall(vim.json.encode, Store)
    if not ok then
      error(result)
    end
    assert(uv.fs_write(file, result))
    assert(uv.fs_close(file))
  end
end

local function store_load()
  local file = uv.fs_open(Options.storefile, "r", 438)
  if file then
    local stat = assert(uv.fs_fstat(file))
    local data = assert(uv.fs_read(file, stat.size, 0))
    assert(uv.fs_close(file))
    local ok, result = pcall(vim.json.decode, data)
    Store = ok and result or {}
  end
end

-- }}}
-- MARK: {{{

local function mark_new(filepath)
  return {
    filepath = filepath or vim.api.nvim_buf_get_name(0),
    pos = vim.api.nvim_win_get_cursor(0),
  }
end

local function mark_get(filepath)
  filepath = filepath or vim.api.nvim_buf_get_name(0)
  for _, mark in ipairs(store_get()) do
    if mark.filepath == filepath then
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

local function mark_follow(mark)
  vim.cmd.edit(mark.filepath)
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
  for _, filepath in ipairs(ui_get_items()) do
    local mark = mark_get(filepath)
    res[#res + 1] = mark or mark_new(filepath)
  end
  Store[uv.cwd()] = res
end

local function ui_select_item()
  local line = vim.api.nvim_get_current_line()
  local filepath = make_absolute(line)
  local mark = mark_get(filepath)
  if mark then
    mark_follow(mark)
  end
end

local function is_ui_open()
  return not vim.tbl_isempty(UI)
end

local function ui_close()
  ui_save_items()
  vim.api.nvim_win_close(UI.win, true)
  UI = {}
end

local function ui_create()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    title = "minipoon",
    title_pos = "center",
    relative = "editor",
    border = "rounded",
    width = 60,
    height = 10,
    row = math.floor(((vim.o.lines - 10) / 2) - 5),
    col = math.floor((vim.o.columns - 60) / 2),
  })

  vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal")
  vim.api.nvim_buf_set_name(buf, "minipoon-menu")
  vim.api.nvim_buf_set_option(buf, "filetype", "minipoon")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")

  for _, k in ipairs({ "q", "<C-c>", "<ESC>" }) do
    vim.keymap.set('n', k, ui_close, { buffer = buf })
  end

  vim.keymap.set('n', '<CR>', ui_select_item, { buffer = buf })

  vim.api.nvim_create_autocmd("BufLeave", { once = true, callback = ui_close, })

  UI = {
    buf = buf,
    win = win,
  }
end

local function ui_populate()
  local store = store_get()
  local filepaths = {}
  for _, mark in ipairs(store) do
    table.insert(filepaths, make_relative(mark.filepath))
  end
  vim.api.nvim_buf_set_lines(UI.buf, 0, -1, false, filepaths)
end

-- }}}

local M = {}

function M.setup()
  store_load()
  vim.api.nvim_create_autocmd("BufLeave", {
    callback = function()
      local mark = mark_get()
      if mark then
        mark_update_pos(mark)
      end
      store_save()
    end
  })
end

function M.mark_file()
  local store = store_get()
  local mark = mark_get()
  if not mark then
    table.insert(store, mark_new())
  else
    mark_update_pos(mark)
  end
end

function M.ui_toogle()
  if is_ui_open() then
    ui_close()
    return
  end
  ui_create()
  ui_populate()
end

function M.jump_to(idx)
  mark_update_current_pos()
  local store = store_get()
  local mark = store[idx]
  if mark then
    mark_follow(mark)
  end
end

return M

-- vim: foldmethod=marker
