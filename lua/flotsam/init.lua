local M = {}

M.mappings = {}
M.terminals = {}

local function calculate_window_config(position)
	local width = vim.o.columns
	local height = vim.o.lines

	local padding = 2
	local cfg = {
		style = "minimal",
		relative = "editor",
		border = "rounded",
	}

	if position == "bottom" then
		cfg.width = width - padding * 2
		cfg.height = math.floor(height / 2)
		cfg.row = height - cfg.height - padding
		cfg.col = padding
	elseif position == "top" then
		cfg.width = width - padding * 2
		cfg.height = math.floor(height / 2)
		cfg.row = padding
		cfg.col = padding
	elseif position == "left" then
		cfg.width = math.floor(width / 2)
		cfg.height = height - padding * 2
		cfg.row = padding
		cfg.col = padding
	elseif position == "right" then
		cfg.width = math.floor(width / 2)
		cfg.height = height - padding * 2
		cfg.row = padding
		cfg.col = width - cfg.width - padding
	else -- center
		cfg.width = math.floor(width * 0.8)
		cfg.height = math.floor(height * 0.8)
		cfg.row = math.floor((height - cfg.height) / 2)
		cfg.col = math.floor((width - cfg.width) / 2)
	end

	return cfg
end

function M.snap_terminal(command, position)
	local term = M.terminals[command]
	if not (term and term.win and vim.api.nvim_win_is_valid(term.win)) then return end

	local cfg = calculate_window_config(position)
	vim.api.nvim_win_set_config(term.win, cfg)
	term.position = position
end

function M.open_floating_terminal(command, position)
	position = position or "center"

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

	local cfg = calculate_window_config(position)
	win = vim.api.nvim_open_win(buf, true, cfg)

	M.terminals[command].win = win
	M.terminals[command].position = position

	if vim.fn.bufname(buf) == "" then
		local shell = os.getenv("SHELL") or "/bin/sh"
		local job_id = vim.fn.termopen({ shell, "-c", command .. "; exec " .. shell })
		vim.b[buf].terminal_job_id = job_id

		-- Exit terminal and hide on <Esc><Esc>
		vim.api.nvim_buf_set_keymap(buf, "t", "<Esc><Esc>",
			"<C-\\><C-n>:lua require('flotsam').hide_terminal('" .. command .. "')<CR>",
			{ noremap = true, silent = true })

		-- Movement keys to reposition
		local positions = { h = "left", l = "right", j = "bottom", k = "top", c = "center" }
		for key, pos in pairs(positions) do
			vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>" .. key,
				"<C-\\><C-n>:lua require('flotsam').snap_terminal('" .. command .. "', '" .. pos .. "')<CR>i",
				{ noremap = true, silent = true })
		end
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

