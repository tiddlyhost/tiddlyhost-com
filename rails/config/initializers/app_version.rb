App::VERSION = [
  "0.0.8-pre",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
