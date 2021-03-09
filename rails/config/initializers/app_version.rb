App::VERSION = [
  "0.0.7",
  ENV['APP_VERSION_BUILD'].presence,
].compact.join("-")
