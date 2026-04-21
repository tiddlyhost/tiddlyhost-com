class CreateCustomDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_domains do |t|
      # Foreign key to sites table
      t.bigint :site_id, null: false, index: { unique: true }

      # Domain configuration
      t.string :domain, null: false, index: { unique: true }

      # Verification status
      # 0: pending_verification, 1: verified, 2: active, 3: failed
      t.integer :status, null: false, default: 0
      t.datetime :verified_at
      t.string :verification_token
      t.datetime :last_verified_check_at

      # SSL certificate status
      # 0: pending, 1: issued, 2: expired, 3: failed
      t.integer :ssl_status, default: 0
      t.datetime :ssl_issued_at
      t.datetime :ssl_expires_at
      t.datetime :certificate_renewal_attempted_at

      # Error tracking
      t.text :last_error

      t.timestamps
    end

    add_foreign_key :custom_domains, :sites
  end
end
