require "test_helper"

class TspotFetcherTest < ActiveSupport::TestCase

  setup do
    @fetcher = TspotFetcher.new('somesite')
    def @fetcher.fetch_key(key);
      raise "No fetches in tests!"
    end
  end

  test "site key" do
    assert_equal(
      "ts/sites/s/so/som/somesite/index.html",
      @fetcher.send(:site_key, 'index.html'))
  end

  test "private site check" do
    # We look for a particular regex in the .htaccess file
    # to establish the site is public
    htaccess_content = <<-EOT.strip_heredoc
      MoreApacheConfig
      RewriteStuff

      ## --- public site ---

      # protect only controlpanel

      <files "controlpanel.cgi">
      RestOfTheFile
      Whatever
    EOT

    @fetcher.stub(:htaccess_file, htaccess_content) do
      assert @fetcher.is_public?
    end

    # Anything not matching the regex is considered private
    @fetcher.stub(:htaccess_file, 'anything non-matching') do
      assert @fetcher.is_private?
    end
  end

  test "password checking" do
    tn1_crypt = "mulder:#{"trustno1".crypt("mu")}"
    [
      ['mulder', 'trustno1', tn1_crypt, true],
      ['mulder', 'trustn01', tn1_crypt, false],
      ['molder', 'trustno1', tn1_crypt, false],
      ['', 'trustno1', tn1_crypt, false],
      ['mulder', 'trustno1', '', false],
      ['mulder', '', tn1_crypt, false],

    ].each do |user, pass, crypt, expected|
      assert_equal expected, !!TspotFetcher.passwd_match?(user, pass, crypt), "#{user}:#{pass}"
    end
  end

end
