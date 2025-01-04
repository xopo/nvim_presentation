---@diagnostic disable: undefined-field
local parse = require("present")._parse_slides
local eq = assert.are.same

describe("present.parse_slides", function()
	it("should parse an empty file", function()
		eq({ slides = { { body = {}, title = "" } } }, parse({}))
	end)

	it("should parse a file with one slide", function()
		local text = {
			"#header",
			"some content",
		}
		eq({ slides = { { body = { "some content" }, title = "#header" } } }, parse(text))
	end)
end)
