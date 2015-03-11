require 'spec_helper'

describe "Renaming files" do
  it "can rename files" do
    write_file 'one.txt', 'One Two'
    write_file 'two.txt', 'Two'

    vim.command 'WritableSearch Two'

    vim.command '%s/two.txt/three.txt/g'
    vim.write

    expect(IO.read('one.txt').strip).to eq 'One Two'
    expect(File.exists?('two.txt')).to eq false
    expect(IO.read('three.txt').strip).to eq 'Two'
  end

  it "can handle two renames of a single file" do
    write_file 'one.txt', "One\nOne"
    vim.command 'WritableSearch One'

    vim.command '%s/one.txt/two.txt/g'
    vim.command '%s/One/Two/g'

    vim.write

    expect(IO.read('two.txt').strip).to eq "Two\nTwo"
    expect(File.exists?('one.txt')).to eq false
  end

  it "can move files to new directories" do
    FileUtils.mkdir('dir')
    write_file 'dir/one.txt', 'One Two'
    write_file 'dir/two.txt', 'Two'

    vim.command 'WritableSearch Two'

    vim.command '%s?dir/two.txt?other_dir/three.txt?g'
    vim.write

    expect(IO.read('dir/one.txt').strip).to eq 'One Two'
    expect(File.exists?('dir/two.txt')).to eq false
    expect(IO.read('other_dir/three.txt').strip).to eq 'Two'
  end
end
