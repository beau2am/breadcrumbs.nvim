-- lua/beaus_plugins/breadcrumb_trail/init.lua
local M = {}

local breadcrumb_colors = {
	"#ff5c5c",
	"#ffa234",
	"#ffd700",
	"#b6e354",
	"#57e389",
	"#59dfff",
}

local ns = vim.api.nvim_create_namespace("breadcrumbs")
local fade_time = 300

-- Highlight setup
local cur_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg or "#22272e"
for i, color in ipairs(breadcrumb_colors) do
	vim.api.nvim_set_hl(0, "Breadcrumb" .. i, { fg = color, bg = cur_bg, bold = true })
end

local colors = {}
for i = 1, #breadcrumb_colors do
	table.insert(colors, "Breadcrumb" .. i)
end

-- crumbs[bufnr] = { { row, col, ... }, ... }
local crumbs = {}
local crumb_id = 0

-- M.last_pos[bufnr] = { row, col }
M.last_pos = {}

-- Utility: Safe extmark setter
local function safe_set_extmark(bufnr, row, col, i)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end

	local line_count = vim.api.nvim_buf_line_count(bufnr)
	if row < 0 or row >= line_count then
		return
	end

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local max_col = #line

	if col < 0 then
		col = 0
	elseif col > max_col then
		col = max_col
	end

	vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
		virt_text = { { "█", colors[i] } },
		virt_text_pos = "overlay",
		hl_mode = "combine",
	})
end

local function redraw_crumbs(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	for i, crumb in ipairs(crumbs[bufnr] or {}) do
		safe_set_extmark(bufnr, crumb.row, crumb.col, i)
	end
end

local function schedule_crumb_fade(bufnr, id)
	vim.defer_fn(function()
		if not crumbs[bufnr] then
			return
		end
		for i, crumb in ipairs(crumbs[bufnr]) do
			if crumb.id == id then
				table.remove(crumbs[bufnr], i)
				redraw_crumbs(bufnr)
				break
			end
		end
	end, fade_time)
end

function M.leave_breadcrumb()
	local bufnr = vim.api.nvim_get_current_buf()
	local pos = vim.api.nvim_win_get_cursor(0)
	local row, col = pos[1] - 1, pos[2]
	crumbs[bufnr] = crumbs[bufnr] or {}
	M.last_pos[bufnr] = M.last_pos[bufnr] or {}

	local last = M.last_pos[bufnr]
	if last[1] and (last[1] ~= row or last[2] ~= col) then
		crumb_id = crumb_id + 1
		local id = crumb_id
		table.insert(crumbs[bufnr], 1, { row = last[1], col = last[2], hl = 1, id = id })
		-- 	if #crumbs[bufnr] > #colors then
		-- 		table.remove(crumbs[bufnr], #crumbs[bufnr])
		-- 	end
		schedule_crumb_fade(bufnr, id)
	end

	redraw_crumbs(bufnr)

	M.last_pos[bufnr][1], M.last_pos[bufnr][2] = row, col
end

function M.setup()
	vim.api.nvim_create_autocmd({ "CursorMoved" }, {
		callback = function()
			M.leave_breadcrumb()
		end,
		group = vim.api.nvim_create_augroup("BreadcrumbTrail", { clear = true }),
		desc = "Leave breadcrumb trail with VirtText",
	})
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
		callback = function(args)
			crumbs[args.buf] = nil
			M.last_pos[args.buf] = nil
		end,
		group = vim.api.nvim_create_augroup("BreadcrumbTrailCleanup", { clear = true }),
	})
end

return M
