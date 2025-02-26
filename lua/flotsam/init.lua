local M = {}

M.mappings = {}
M.terminals = {}

function M.open_floating_terminal(command)
	local term_data = M.terminals[command]
	local buf = term_data and term_data.buf
	local win = term_data and term_data.win

	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
		M.terminals[command].win = nil
		return
	end

	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		buf = vim.api.nvim_create_buf(false, true)
		M.terminals[command] = { buf = buf }
	end

	local width = vim.api.nvim_get_option_value("columns", {})
	local height = vim.api.nvim_get_option_value("lines", {})

	local win_height = math.ceil(height * 0.8)
	local win_width = math.ceil(width * 0.8)
	local row = math.ceil((height - win_height) / 2)
	local col = math.ceil((width - win_width) / 2)

	win = vim.api.nvim_open_win(buf, true, {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
	})

	M.terminals[command].win = win

	if vim.fn.bufname(buf) == "" then
		local shell = os.getenv("SHELL") or "/bin/sh"
		local job_id = vim.fn.termopen(shell, {
			on_exit = function()
				if M.terminals[command] and M.terminals[command].win then
					local win_to_close = M.terminals[command].win
					if win_to_close and vim.api.nvim_win_is_valid(win_to_close) then
						vim.api.nvim_win_close(win_to_close, true)
					end
				end

				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end

				M.terminals[command] = nil
			end
		})

		vim.b[buf].terminal_job_id = job_id

		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_chan_send(job_id, command .. "\n")
			end
		end, 100)

		vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>",
			"<C-\\><C-n>:lua require('flotsam').hide_terminal('" .. command .. "')<CR>",
			{ noremap = true, silent = true })
	end

	vim.api.nvim_command("startinsert")
end

function M.hide_terminal(command)
	local term_data = M.terminals[command]
	if term_data and term_data.win and vim.api.nvim_win_is_valid(term_data.win) then
		vim.api.nvim_win_close(term_data.win, true)
		M.terminals[command].win = nil
	end
end

function M.setup(opts)
	M.mappings = opts.mappings or {}

	for _, mapping in ipairs(M.mappings) do
		vim.api.nvim_set_keymap("n", mapping.keymap, string.format(
			"<cmd>lua require('flotsam').open_floating_terminal('%s')<CR>", vim.fn.escape(mapping.command, "'")
		), { noremap = true, silent = true })
	end

	vim.api.nvim_create_user_command("Flotsam", function(args)
		local command = table.concat(args.fargs, " ")
		if command and command ~= "" then
			M.open_floating_terminal(command)
		else
			print("Usage: :Flotsam <command>")
		end
	end, { nargs = "+" })
end

return M
