vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("n", "<leader>fe", vim.cmd.Ex)

keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- shortcut for escape from insert mode
keymap.set("i", "jk", "<Esc>")

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window verticaly
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make splits equal width and height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

--tab management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab
-- Paste in visual mode without yanking replace text
-- vim.keymap.set("x", "p", [["_dP]])

-- yank to clipboard
keymap.set({ "n", "v" }, "<leader>y", [["+y]])
-- yank line to clipboard
keymap.set("n", "<leader>Y", [["+Y]])

--delete without yanking
keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- save, quit
keymap.set("n", "<leader>ww", ":w<cr>")
keymap.set("n", "<leader>wq", ":q<cr>")

-- move blocks of text up/down with K/J in visual mode
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })

-- center the screen after scrolling up/down with Ctrl-u/d
keymap.set("n", "C-u>", "<C-u>zz")
keymap.set("n", "C-d>", "<C-d>zz")

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<cr>")

-- increment and decrement numbers
keymap.set("n", "<leader>+", "<C-a>")
keymap.set("n", "<leader>-", "<C-x>")
