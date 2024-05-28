-- ~/.config/nvim/lua/theprimeagen/lazy/convert_and_view.lua

local M = {}

function M.convertAndViewPDF()
    print("convertAndViewPDF function called")

    local current_file = vim.fn.expand('%:p')
    local current_file_no_ext = vim.fn.expand('%:p:r')
    local pdf_file = current_file_no_ext .. '.pdf'

    -- Convert the Markdown file to PDF using pandoc
    local pandoc_cmd = 'pandoc "' .. current_file .. '" -o "' .. pdf_file .. '"'
    local success = vim.fn.system(pandoc_cmd)

    -- Open the PDF with the default PDF viewer
    local open_cmd = 'xdg-open "' .. pdf_file .. '"'
    vim.fn.system(open_cmd)

    -- Wait for the PDF viewer to close and then delete the PDF file
    vim.defer_fn(function()
        vim.fn.delete(pdf_file)
    end, 5000) -- Adjust the delay if necessary
end

function M.setup()
    vim.api.nvim_set_keymap('n', '<Space>cp', ':lua require("theprimeagen.lazy.convert_and_view").convertAndViewPDF()<CR>', { noremap = true, silent = true })
end

return setmetatable({}, {
    __index = M,
    __call = function(_, ...)
        return M.setup(...)
    end
})
