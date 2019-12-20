require 'spec_helper'

describe "Updating from source" do
  it "updates the proxies from the source files" do
    write_file 'one.txt', 'One Two Three'

    vim.set_buffer_contents <<~EOF
      one.txt:1:One Two Three
    EOF
    vim.command 'call writable_search#Parse()'

    write_file 'one.txt', 'One Foo Three'

    vim.write

    expect(vim.buffer_contents).to include 'One Foo Three'
  end
end
