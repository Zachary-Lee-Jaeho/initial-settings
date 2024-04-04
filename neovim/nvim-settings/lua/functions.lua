-- Functions for global settings

vim.wo.wrap = false

-- ToggleWrap
function ToggleWrap()
  if vim.wo.wrap then
    vim.wo.wrap = false
    print "Wrap disabled"
  else
    vim.wo.wrap = true
    print "Wrap enabled"
  end
end

vim.api.nvim_set_keymap("n", "<Leader>w", ":lua ToggleWrap()<CR>", { noremap = true, silent = true })

-- NvimTree가 마지막 남은 버퍼일 때 Neovim을 자동으로 종료
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("NvimTreeAutoClose", { clear = true }),
  callback = function()
    -- 열려 있는 윈도우가 하나뿐이고, 그 윈도우가 NvimTree인지 확인
    if #vim.api.nvim_list_wins() == 1 and vim.bo.filetype == "NvimTree" then
      -- NvimTree가 마지막 버퍼일 경우 Neovim 종료
      vim.cmd "confirm quit"
    end
  end,
})

local function open_nvim_tree(data)
  -- buffer is a directory
  local directory = vim.fn.isdirectory(data.file) == 1
  if not directory then
    -- buffer is a real file on the disk
    local real_file = vim.fn.filereadable(data.file) == 1
    -- buffer is a [No Name]
    local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
    if not real_file and not no_name then
      return
    end
    -- open the tree, find the file but don't focus it
    if require("nvim-tree.view").is_visible() then
      return
    else
      require("nvim-tree.api").tree.toggle { focus = false, find_file = true }
    end

    return
  end
  -- change to the directory
  vim.cmd.cd(data.file)
  -- open the tree
  require("nvim-tree.api").tree.open()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = open_nvim_tree,
})

-- Remember the last location of file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local ft = vim.bo.filetype
    if ft ~= "gitcommit" and vim.fn.line "'\"" > 0 and vim.fn.line "'\"" <= vim.fn.line "$" then
      vim.cmd 'normal! g`"'
    end
  end,
})
