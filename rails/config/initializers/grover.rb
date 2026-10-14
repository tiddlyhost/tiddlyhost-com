Grover.configure do |config|
  config.options = {
    viewport: {
      width: 1024,
      height: 680,
      device_scale_factor: 0.25,
    },

    # Timeout waiting for the page request to finish
    # (Might be possibly be exceeded by a very large TiddlyWiki)
    request_timeout: 40_000,

    # Timeout making the screenshot
    # (Not sure what would cause this to be exceeded)
    convert_timeout: 40_000,

    # Wait for network to be mostly idle.
    wait_until: 'networkidle2',

    # Take the screenshot after 20 seconds no matter what even if
    # networkidle2 is never reached. (Previously used wait_for_timeout
    # but the underlying method is no longer supported by puppeteer even
    # though grover tries to call it.)
    execute_script: 'new Promise(resolve => setTimeout(resolve, 20000))',
  }
end
