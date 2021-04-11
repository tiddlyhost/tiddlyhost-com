App::VERSION = [
  "0.2.0-pre",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
