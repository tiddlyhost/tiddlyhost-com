App::VERSION = [
  "1.0.1-pre",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
