local M = {}
M.slots = {}

local data_dir = vim.fn.stdpath("data") .. "/ezpoon"
vim.fn.mkdir(data_dir, "p")

local ns_id = vim.api.nvim_create_namespace("EZpoon")

---Find path where arglst is saved depending on context.
---Context depends on which git repo user is in, otherwise fallback to global
---@return string
local function _get_path()
  local context

  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if result.code ~= 0 then
    context = "global"
  else
    context = result.stdout:gsub("\n", ""):gsub("/", "_")
  end

  return data_dir .. "/" .. context
end

---Save current state
local function _save_state()
  local path = _get_path()

  vim.fn.writefile({ vim.json.encode(M.slots) }, path)
end

---Load slots depending on context.
---Context depends on which git repo user is in, otherwise fallback to global
---@return table<string|integer, string>
local function _load_state()
  local path = _get_path()

  -- If state file does not exist, write the file
  if vim.fn.filereadable(path) == 0 then
    _save_state()
  end

  local content = table.concat(vim.fn.readfile(path))
  return vim.json.decode(content)
end

---Return a sorted array of keys
---@param tbl table<string|integer, string>
---@return (string|integer)[]
local function _sorted_keys(tbl)
  local keys = vim.tbl_keys(tbl)
  table.sort(keys, function(a, b)
    return string.byte(a) < string.byte(b)
  end)

  return keys
end

---Return an array of formatted lines for Menu's buffer
---@param slots table<string|integer, string>
---@param sorted_keys (string|integer)[]
---@return string[]
local function _get_formatted_lines(slots, sorted_keys)
  local formatted_lines = {}
  for _, k in ipairs(sorted_keys) do
    table.insert(formatted_lines, string.format("[%s] = %s", k, slots[k]))
  end

  return formatted_lines
end

---Validate the lines to ensure correct syntax
---Filepath needs to be valid
---Returns a boolean flag indicating if all lines are valid, and a table of the lines with errors
---@param lines string[]
---@return boolean, string[]
local function _validate_lines(lines)
  local is_all_valid = true
  local lines_with_errors = {}

  for i, line in ipairs(lines) do
    local sep_start_index, _ = string.find(line, "=")
    local filepath = vim.fn.trim(string.sub(line, sep_start_index + 1))
    local key = string.match(line, "^%[(.-)%]")
    local is_valid_fp = true
    local is_valid_key = true

    if vim.fn.filereadable(vim.fn.expand(filepath)) == 0 then
      is_valid_fp = false
    end

    if not (key and key:match("^[0-9a-z]$")) then
      is_valid_key = false
    end

    if not (is_valid_fp and is_valid_key) then
      is_all_valid = false
      table.insert(lines_with_errors, i)
    end
  end

  return is_all_valid, lines_with_errors
end

-- ============================================
-- Action: Add
-- ============================================

---Add current file to EZpoon
---@param key string
function M.add(key)
  M.slots = _load_state()
  local current_file = vim.fn.expand("%:p")

  if current_file == "" or vim.bo.buftype ~= "" then
    return
  end

  M.slots[key] = current_file

  _save_state()

  vim.notify("EZpoon: " .. current_file .. " added to " .. "[" .. key .. "]", vim.log.levels.INFO)
end

-- ============================================
-- Action: Jump
-- ============================================

---Jump to the file registered to the specific key
---@param key string
function M.jump(key)
  M.slots = _load_state()
  local filepath = M.slots[key]

  vim.cmd.edit(filepath)
end

-- ============================================
-- Action: menu
-- ============================================

---Display EZpoon's menu for editing
function M.menu()
  M.slots = _load_state()
  local sorted_keys = _sorted_keys(M.slots)
  local formatted_lines = _get_formatted_lines(M.slots, sorted_keys)

  -- Menu's buffers settings
  local menu_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = menu_buf })
  vim.api.nvim_set_option_value("bufhidden", "delete", { buf = menu_buf })
  vim.api.nvim_buf_set_name(menu_buf, "EZPoon-Menu")

  vim.api.nvim_buf_set_lines(menu_buf, 0, -1, false, formatted_lines)

  vim.keymap.set("n", "<ESC>", "<CMD>q<CR>", { buffer = menu_buf, silent = true })

  -- Menu's floating window settings
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local menu_win = vim.api.nvim_open_win(menu_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "EZpoon Menu",
    title_pos = "center",
    footer = ":w to save | :q or ESC to quit",
    footer_pos = "center",
  })

  -- Save logic
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = menu_buf,
    desc = "Save EZpoon state on write",
    callback = function(_)
      vim.api.nvim_buf_clear_namespace(menu_buf, ns_id, 0, -1)

      local new_lines = vim.api.nvim_buf_get_lines(menu_buf, 0, -1, false)

      local is_all_valid, lines_with_errors = _validate_lines(new_lines)

      if is_all_valid then
        M.slots = {}

        for _, line in ipairs(new_lines) do
          local sep_start_index, _ = string.find(line, "=")
          local filepath = vim.fn.trim(string.sub(line, sep_start_index + 1))
          local key = string.match(line, "^%[(.-)%]")

          M.slots[key] = filepath

          _save_state()
        end

        vim.api.nvim_set_option_value("modified", false, { buf = menu_buf })
        vim.notify("EZpoon: State saved!", vim.log.levels.INFO)
        vim.api.nvim_win_close(menu_win, true)
      else
        for _, line_num in ipairs(lines_with_errors) do
          vim.api.nvim_buf_set_extmark(menu_buf, ns_id, line_num - 1, 0, {
            virt_text = { { "X", "ErrorMsg" } },
            virt_text_pos = "eol",
          })
        end
        vim.notify(
          "EZpoon: Please ensure syntax is correct ([<key>] = <valid fp>), and that the file exists!",
          vim.log.levels.ERROR
        )
      end
    end,
  })
end

return M
