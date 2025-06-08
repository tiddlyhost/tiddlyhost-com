namespace :bootstrap_email do
  desc "Precompile and cache bootstrap-email sass"
  task sass_precompile: :environment do
    %w[bootstrap-email bootstrap-head].each do |stylesheet|
      puts "Compiling #{stylesheet}..."
      config = BootstrapEmail::Config.new({})
      BootstrapEmail::SassCache.compile(stylesheet, config, style: :expanded)
    end
  end
end
