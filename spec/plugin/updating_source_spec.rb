require 'spec_helper'

describe "Updating source" do
  it "can update the source files" do
    write_file 'one.txt', 'One Two Three'
    write_file 'two.txt', 'Two Three Four'

    vim.command 'WritableSearch Two'
    vim.command '%s/Two/Foo/g'
    vim.write

    IO.read('one.txt').strip.should eq 'One Foo Three'
    IO.read('two.txt').strip.should eq 'Foo Three Four'
  end
end
