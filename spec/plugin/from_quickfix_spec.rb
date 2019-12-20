require 'spec_helper'

describe "From Quickfix" do
  it "can search for a given query and load the results from the quickfix window" do
    write_file 'one.txt', 'One Two Three'
    write_file 'two.txt', 'Two Three Four'

    vim.command 'vimgrep /Two/ * '
    vim.command 'WritableSearchFromQuickfix'

    vim.buffer_contents.should include <<~EOF.strip
      one.txt:1-1
       One Two Three
    EOF

    vim.buffer_contents.should include <<~EOF.strip
      two.txt:1-1
       Two Three Four
    EOF
  end

  it "handles quickfix results in the same file" do
    write_file 'one.txt', "One Two Three\nTwo Three Four"

    vim.command 'vimgrep /Two/ * '
    vim.command 'WritableSearchFromQuickfix'

    vim.buffer_contents.should include <<~EOF.strip
      one.txt:1-2
       One Two Three
       Two Three Four
    EOF
  end

  it "doesn't do string comparison for lines" do
    write_file 'one.txt', "One Two Three#{"\n" * 5}Two Three Four#{"\n" * 8}Five Two Six"

    vim.command 'vimgrep /Two/ * '
    vim.command 'WritableSearchFromQuickfix'

    expected_nonblank = <<~EOF.strip
      one.txt:1-9
       One Two Three
       Two Three Four
      one.txt:11-14
       Five Two Six
    EOF
    actual_nonblank = vim.buffer_contents.split("\n").grep(/\S/).join("\n")

    actual_nonblank.should eq expected_nonblank
  end
end
