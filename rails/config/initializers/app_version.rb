App::VERSION = [
  "0.0.5",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
