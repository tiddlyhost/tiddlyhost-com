App::VERSION = [
  "1.0.2-pre",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
