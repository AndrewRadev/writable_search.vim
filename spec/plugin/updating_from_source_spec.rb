require 'spec_helper'

describe "Updating from source" do
  it "updates the proxies from the source files" do
    write_file 'one.txt', 'One Two Three'

    vim.set_buffer_contents normalize_string_indent(<<-EOF)
      one.txt:1:One Two Three
    EOF
    vim.command 'call writable_search#Parse()'

    write_file 'one.txt', 'One Foo Three'

    vim.write

    vim.buffer_contents.should include 'One Foo Three'
  end
end
