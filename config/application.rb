require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module UcscHyrax
  class Application < Rails::Application
    
    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    config.autoload_paths += %W(#{config.root}/app/presenters)

    config.tinymce.install = :copy

#    This setting is now only in environments/production.rb
#    config.active_job.queue_adapter = :resque

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
