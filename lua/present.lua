local M = {}
M.setup = function()
	print("loaded present.nvim")
end

---@class present.Slides
---@fields slides string[]: The slides of the file

--- Take some lines and parses them
---@param slides present.Slide[]: The lines in the buffer
---@return present.Slides

---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The body of the slide
local parse_slides = function(lines)
	local slides = { slides = {} }
	local current_slide = {
		title = "",
		body = {},
	}
	local separator = "^#"

	for _, line in ipairs(lines) do
		if line:find(separator) then
			if #current_slide.title > 0 then
				table.insert(slides.slides, current_slide)
			end

			current_slide = {
				title = line,
				body = {},
			}
		else
			table.insert(current_slide.body, line)
		end
	end

	-- remember to add the last one
	table.insert(slides.slides, current_slide)
	return slides
end

local create_floating_window = function(config, enter)
	if enter == nil then
		enter = false
	end

	-- Define window config
	local buf = vim.api.nvim_create_buf(false, true) -- Create a new buffer
	local win = vim.api.nvim_open_win(buf, enter or false, config) -- Create the floating window

	-- Return the floating window handle
	return { buf = buf, win = win }
end

local restore = {}
restore.cmdheight = {
	original = vim.o.cmdheight,
	present = 0,
}

local setConfig = function(optional)
	for option, config in pairs(restore) do
		vim.opt[option] = optional and config.present or config.original
	end
end

local create_windows_config = function()
	local width = vim.o.columns
	local height = vim.o.lines

	local header_height = 1 -- with border
	local footer_height = 1 --  no border
	local body_height = height - header_height - footer_height - 6 -- with border

	return {
		background = {
			relative = "editor",
			width = width,
			height = height,
			style = "minimal",
			col = 0,
			row = 0,
			border = "none",
			zindex = 1,
		},
		header = {
			relative = "editor",
			width = width,
			height = header_height,
			style = "minimal",
			col = 0,
			row = 0,
			border = "rounded",
			zindex = 2,
		},
		body = {
			relative = "editor",
			width = width - 8,
			height = body_height,
			style = "minimal",
			col = 3,
			row = 3,
			border = { " " },
		},
		footer = {
			relative = "editor",
			width = width,
			height = footer_height,
			style = "minimal",
			col = 0,
			row = height - 2,
			border = "rounded",
			zindex = 2,
		},
	}
end

local state = {
	parsed = {},
	current_slide = 1,
	floats = {},
}

local foreach_float = function(cb)
	for name, float in pairs(state.floats) do
		cb(name, float)
	end
end

local present_keymap = function(mode, key, callback)
	vim.keymap.set(mode, key, callback, {
		buffer = state.floats.body.buf,
	})
end

M.start_presentation = function(opts)
	opts = opts or {}
	opts.bufnr = opts.bufnr or 0
	local windows = create_windows_config()

	local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
	state.parsed = parse_slides(lines)
	state.current_slide = 1
	state.title = vim.fn.expand("%:t")

	state.floats.background = create_floating_window(windows.background)
	state.floats.header = create_floating_window(windows.header)
	state.floats.footer = create_floating_window(windows.footer)
	state.floats.body = create_floating_window(windows.body, true)

	-- apply markdown magic
	foreach_float(function(_, float)
		vim.bo[float.buf].filetype = "markdown"
	end)

	local set_current_slide = function(slide_number)
		local slide = state.parsed.slides[slide_number]
		local width = vim.o.columns
		local padding = string.rep(" ", (width - #slide.title) / 2)
		local title = padding .. slide.title
		local footer = string.format("   %d / %d | %s", state.current_slide, #state.parsed.slides, state.title)
		local pre = string.rep(" ", width - #footer - 5)

		vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })
		vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)
		vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { pre .. footer })
	end

	--// Keymaps for plugin
	present_keymap("n", "n", function()
		state.current_slide = math.min(state.current_slide + 1, #state.parsed.slides)
		set_current_slide(state.current_slide)
	end)

	present_keymap("n", "p", function()
		state.current_slide = math.max(state.current_slide - 1, 1)
		set_current_slide(state.current_slide)
	end)

	present_keymap("n", "q", function()
		pcall(vim.api.nvim_win_close, state.floats.body.win, true)
	end)

	setConfig(true)

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = state.floats.body.buf,
		callback = function()
			setConfig()
			print("Yayaya")

			-- pcall(vim.api.nvim_win_close, state.floats.background.win, true)
			-- pcall(vim.api.nvim_win_close, state.floats.header.win, true)
			foreach_float(function(_, float)
				pcall(vim.api.nvim_win_close, float.win, true)
			end)
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		-- group = vim.api.nvim_create_augroup("present-resized", {}),
		callback = function()
			if not vim.api.nvim_win_is_valid(state.floats.body.win) or state.floats.body.win == nil then
				return
			end
			local updated = create_windows_config()
			foreach_float(function(name, _)
				vim.api.nvim_win_set_config(state.floats[name].win, updated[name])
			end)
			set_current_slide(state.current_slide)
		end,
	})

	set_current_slide(1)
end

-- local call_go_program = function(input)
--     print("call go program with input: " .. input)
--     local cmd = "go run go_plugin.go" .. input
--     local handle = io.popen(cmd)
--     if handle then
--         local result = handle:read("*a")
--         handle:close()
--         print("inside go program" .. result)
--         return result
--     else
--         print(" there is no handle here")
--     end
--     return "something is wrong"
-- end
--
-- vim.api.nvim_create_user_command("GoPlugin", function(opts)
--     local result = call_go_program(opts.args)
--     print("Go program result" .. result)
-- end, { nargs = 1 })

-- echo nvim_get_current_buf()
-- M.start_presentation({ bufnr = 4 })
-- vim.print(parse_slides({
--     "# Hello",
--     "this is a line",
--     "# World",
--     "end line",
-- }))

M._parse_slides = parse_slides

return M
