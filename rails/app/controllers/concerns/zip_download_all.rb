require 'zip'

module ZipDownloadAll
  extend ActiveSupport::Concern

  def download_all
    # Let's respect the filtering when deciding what to
    # download hence it's maybe not actually all the sites
    data = zip_stream(@filtered_sites)

    send_data(
      data.string,
      type: 'application/zip',
      disposition: 'attachment',
      filename: 'thostsites.zip'
    )
  end

  private

  def zip_stream(sites)
    Zip::OutputStream.write_buffer do |zip|
      sites.each do |site|
        # For external core sites we could consider converting it to local
        # core and then including the correct core.js file in the zip file
        # but let's not worry about that for now
        name = "#{'tspot_' if site.is_tspot?}#{site.name}.html"
        zip.put_next_entry(name)
        zip.write(site.download_content)
      end
    end
  end
end
