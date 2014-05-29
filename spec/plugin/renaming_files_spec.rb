require 'spec_helper'

describe "Renaming files" do
  it "can rename files" do
    write_file 'one.txt', 'One'
    write_file 'two.txt', 'Two'

    vim.set_buffer_contents normalize_string_indent(<<-EOF)
      one.txt:1:One
      --
      two.txt:1:Two
    EOF
    vim.command 'call writable_search#Parse()'

    vim.command '%s/two.txt/three.txt/g'
    vim.write

    IO.read('one.txt').strip.should eq 'One'
    File.exists?('two.txt').should be_false
    IO.read('three.txt').strip.should eq 'Two'
  end

  it "can move files to new directories" do
    FileUtils.mkdir('dir')
    write_file 'dir/one.txt', 'One'
    write_file 'dir/two.txt', 'Two'

    vim.set_buffer_contents normalize_string_indent(<<-EOF)
      dir/one.txt:1:One
      --
      dir/two.txt:1:Two
    EOF
    vim.command 'call writable_search#Parse()'

    vim.command '%s?dir/two.txt?other_dir/three.txt?g'
    vim.write

    IO.read('dir/one.txt').strip.should eq 'One'
    File.exists?('dir/two.txt').should be_false
    IO.read('other_dir/three.txt').strip.should eq 'Two'
  end
end
