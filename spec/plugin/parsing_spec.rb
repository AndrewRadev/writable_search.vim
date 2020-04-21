require 'spec_helper'

describe "Parsing" do
  before :each do
    FileUtils.mkdir_p('autoload/writable-search')

    write_file 'autoload/writable-search/proxy.vim', <<~EOF
      " padding
      " to adjust next proxies.
      function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict

    EOF
    write_file 'autoload/writable-search/parser.vim', <<~EOF
      function! writable_search#parser#Run()
        let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))

        "...
        for lines in a:grouped_lines
          let current_proxy          = writable_search#proxy#New(bufnr('%'))
          let current_proxy.filename = s:FindFilename(lines)
    EOF
  end

  it "parses grep results into a different representation (separated by dashes)" do
    write_file 'grep_results', <<~EOF
      autoload/writable-search/proxy.vim-2-" to adjust next proxies.
      autoload/writable-search/proxy.vim:3:function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict
      autoload/writable-search/proxy.vim-4-
      --
      autoload/writable-search/parser.vim:1:function! writable_search#parser#Run()
      autoload/writable-search/parser.vim-2-  let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
      --
      autoload/writable-search/parser.vim-5-  for lines in a:grouped_lines
      autoload/writable-search/parser.vim:6:    let current_proxy          = writable_search#proxy#New(bufnr('%'))
      autoload/writable-search/parser.vim-7-    let current_proxy.filename = s:FindFilename(lines)
    EOF

    vim.edit 'grep_results'
    vim.command 'call writable_search#Parse()'

    expect(vim.buffer_contents.lines.map(&:strip)).to eq <<~EOF.lines.map(&:strip)
      autoload/writable-search/proxy.vim:2-4
       " to adjust next proxies.
       function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict

      autoload/writable-search/parser.vim:1-2
       function! writable_search#parser#Run()
         let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
      autoload/writable-search/parser.vim:5-7
         for lines in a:grouped_lines
           let current_proxy          = writable_search#proxy#New(bufnr('%'))
           let current_proxy.filename = s:FindFilename(lines)
    EOF
  end

  it "parses grep results into a different representation (no dashes)" do
    write_file 'grep_results', <<~EOF
      autoload/writable-search/proxy.vim-2-" to adjust next proxies.
      autoload/writable-search/proxy.vim:3:function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict
      autoload/writable-search/proxy.vim-4-
      autoload/writable-search/parser.vim:1:function! writable_search#parser#Run()
      autoload/writable-search/parser.vim-2-  let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
      autoload/writable-search/parser.vim-5-  for lines in a:grouped_lines
      autoload/writable-search/parser.vim:6:    let current_proxy          = writable_search#proxy#New(bufnr('%'))
      autoload/writable-search/parser.vim-7-    let current_proxy.filename = s:FindFilename(lines)
    EOF

    vim.edit 'grep_results'
    vim.command 'call writable_search#Parse()'

    expect(vim.buffer_contents.lines.map(&:strip)).to eq <<~EOF.lines.map(&:strip)
      autoload/writable-search/proxy.vim:2-4
       " to adjust next proxies.
       function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict

      autoload/writable-search/parser.vim:1-2
       function! writable_search#parser#Run()
         let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
      autoload/writable-search/parser.vim:5-7
         for lines in a:grouped_lines
           let current_proxy          = writable_search#proxy#New(bufnr('%'))
           let current_proxy.filename = s:FindFilename(lines)
    EOF
  end
end
