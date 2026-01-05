require 'resolv'
require 'timeout'

class EmailDomainValidator < ActiveModel::EachValidator
  # Common email providers for fast validation
  KNOWN_VALID_DOMAINS = %w[
    gmail.com
    yahoo.com
    outlook.com
    hotmail.com
    aol.com
    icloud.com
    mail.com
    protonmail.com
    zoho.com
    gmx.com
    yandex.com
    live.com
    msn.com
    me.com
    mac.com
    inbox.com
    fastmail.com
    tutanota.com
  ].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    email = value.to_s.strip.downcase
    
    # Extract domain
    domain = email.split('@').last
    
    return if domain.blank?

    # Check if domain is in known valid list (fast path)
    if KNOWN_VALID_DOMAINS.include?(domain)
      return
    end

    # For other domains, check MX records (slower but more thorough)
    unless domain_has_mx_records?(domain)
      record.errors.add(attribute, :invalid_domain, 
        message: "does not appear to be a valid email domain. Please use a real email address from providers like Gmail, Yahoo, Outlook, etc.")
    end
  end

  private

  def domain_has_mx_records?(domain)
    # Check MX records to see if domain accepts email
    # Use timeout to prevent hanging on slow DNS lookups
    begin
      Timeout.timeout(3) do
        resolver = Resolv::DNS.new
        
        # Try to get MX records
        mx_records = resolver.getresources(domain, Resolv::DNS::Resource::IN::MX)
        
        # If MX records exist, domain accepts email
        return true if mx_records.any?
        
        # If no MX records, check if domain has A record (some domains use A records for mail)
        a_records = resolver.getresources(domain, Resolv::DNS::Resource::IN::A)
        return true if a_records.any?
        
        # Also check AAAA records (IPv6)
        aaaa_records = resolver.getresources(domain, Resolv::DNS::Resource::IN::AAAA)
        return true if aaaa_records.any?
        
        false
      end
    rescue Timeout::Error => e
      Rails.logger.warn "DNS lookup timeout for domain #{domain} - allowing email (may be temporary DNS issue)"
      # On timeout, be lenient and allow it (could be temporary DNS issues)
      true
    rescue Resolv::ResolvError => e
      Rails.logger.warn "DNS lookup failed for domain #{domain}: #{e.message}"
      # If DNS lookup fails, we'll be lenient and allow it
      # (could be temporary DNS issues)
      true
    rescue => e
      Rails.logger.error "Error validating email domain #{domain}: #{e.class} - #{e.message}"
      # On error, be lenient and allow it
      true
    end
  end
end

