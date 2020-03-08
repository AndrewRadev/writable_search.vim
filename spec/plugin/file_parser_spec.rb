require 'spec_helper'

describe "file parser" do
  def parse_line(line)
    string_array = vim.command("echo writable_search#file_parser#New().ParseLine(#{line.inspect})")
    eval(string_array)
  end

  it "correctly detects simple file patterns" do
    write_file 'one.txt', 'One Two Three'

    expect(parse_line('one.txt:1:One Two Three')).to eq ['one.txt', '1']
    expect(parse_line('one.txt-1-One Two Three')).to eq ['one.txt', '1']
  end

  it "correctly detects file patterns with a delimiter and number in them" do
    write_file 'one:2:three.txt', 'One Two Three'
    write_file 'one-2-three.txt', 'One Two Three'

    expect(parse_line('one:2:three.txt:1:One Two Three')).to eq ['one:2:three.txt', '1']
    expect(parse_line('one-2-three.txt-1-One Two Three')).to eq ['one-2-three.txt', '1']
  end
end
