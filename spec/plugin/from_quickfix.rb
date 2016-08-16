require 'spec_helper'

describe "From Quickfix" do
  it "can search for a given query and load the results from the quickfix window" do
    write_file 'one.txt', 'One Two Three'
    write_file 'two.txt', 'Two Three Four'

    vim.command 'vimgrep /Two/ * '
    vim.command 'WritableSearchFromQuickfix'

    vim.buffer_contents.should include normalize_string_indent(<<-EOF)
      one.txt:1-1
       One Two Three
    EOF

    vim.buffer_contents.should include normalize_string_indent(<<-EOF)
      two.txt:1-1
       Two Three Four
    EOF
  end
end
