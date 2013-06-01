require 'spec_helper'

describe "Searching" do
  it "can search for a given query and show the results" do
    write_file 'one.txt', 'One Two Three'
    write_file 'two.txt', 'Two Three Four'

    vim.command 'WritableSearch Two'

    vim.buffer_contents.should eq normalize_string_indent(<<-EOF)
      two.txt:1-1
       Two Three Four
      one.txt:1-1
       One Two Three
    EOF
  end
end
