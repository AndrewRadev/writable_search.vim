require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  plugin_path = File.expand_path('.')

  # Decide how to start a Vim instance. In this block, an instance should be
  # spawned and set up with anything project-specific.
  config.start_vim do
    vim = Vimrunner.start
    vim.add_plugin(plugin_path, 'plugin/writable_search.vim')
    vim.command('let g:writable_search_confirm_file_rename = 0')
    vim.command('let g:writable_search_confirm_directory_creation = 0')

    def vim.buffer_contents
      echo(%<join(getbufline('%', 1, '$'), "\n")>)
    end

    def vim.set_buffer_contents(text)
      command('%delete _')
      echo(%<setline(1, split(#{text.inspect}, "\\n"))>)
    end

    vim
  end
end
