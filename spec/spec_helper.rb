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
    vim
  end
end
