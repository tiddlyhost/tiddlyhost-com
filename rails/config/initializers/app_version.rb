App::VERSION = [
  "0.1.0-pre",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
