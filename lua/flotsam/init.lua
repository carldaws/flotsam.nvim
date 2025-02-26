local M = {}

M.mappings = {}

function M.open_floating_terminal(command)
	local buf = vim.api.nvim_create_buf(false, true)

	local width = vim.api.nvim_get_option_value("columns", {})
	local height = vim.api.nvim_get_option_value("lines", {})

	local win_height = math.ceil(height * 0.8)
	local win_width = math.ceil(width * 0.8)
	local row = math.ceil((height - win_height) / 2)
	local col = math.ceil((width - win_width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
	})

	local shell = os.getenv("SHELL") or "/bin/sh"
	local job_id = vim.fn.termopen(shell, {
		on_exit = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end
	})

	vim.b[buf].terminal_job_id = job_id

	vim.api.nvim_command("startinsert")

	vim.defer_fn(function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_chan_send(job_id, command .. "\n")
		end
	end, 100)

	vim.api.nvim_buf_set_keymap(buf, "t", "<Esc><Esc>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
end

function M.setup(opts)
	M.mappings = opts.mappings or {}

	for _, mapping in ipairs(M.mappings) do
		vim.api.nvim_set_keymap("n", mapping.keymap, string.format(
			"<cmd>lua require('flotsam').open_floating_terminal('%s')<CR>", vim.fn.escape(mapping.command, "'")
		), { noremap = true, silent = true })
	end
end

return M
