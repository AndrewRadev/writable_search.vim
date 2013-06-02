require 'spec_helper'

describe "Updating source" do
  it "can update the source files" do
    write_file 'one.txt', 'One Two Three'
    write_file 'two.txt', 'Two Three Four'

    vim.set_buffer_contents normalize_string_indent(<<-EOF)
      one.txt:1:One Two Three
      --
      two.txt:1:Two Three Four
    EOF
    vim.command 'WritableSearch'

    vim.command '%s/Two/Foo/g'
    vim.write

    IO.read('one.txt').strip.should eq 'One Foo Three'
    IO.read('two.txt').strip.should eq 'Foo Three Four'
  end

  it "updates two instances of the same file correctly" do
    write_file 'one.txt', <<-EOF
      One Two Three
      Four
    EOF

    vim.set_buffer_contents normalize_string_indent(<<-EOF)
      one.txt:1:One Two Three
      --
      one.txt:2:Four
    EOF
    vim.command 'WritableSearch'

    vim.command '%s/One/One\r/g'
    vim.command '%s/Two/Two\r/g'
    vim.command '%s/Four/Five/g'

    vim.write

    IO.read('one.txt').strip.should eq "One\nTwo\nThree\nFive"
  end

  it "can rename files" do
    write_file 'test.txt', 'Test'

    vim.set_buffer_contents normalize_string_indent(<<-EOF)
      test.txt:1:Test
    EOF
    vim.command 'WritableSearch'

    vim.command '%s/test.txt/renamed.txt/g'
    vim.write

    IO.read('renamed.txt').strip.should eq 'Test'
  end
end
