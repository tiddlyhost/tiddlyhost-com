App::VERSION = [
  "0.3.0-pre",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
