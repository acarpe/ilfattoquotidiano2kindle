require 'rubygems'
require 'net/http'
require 'mechanize'
require 'yaml'
require File.join(Dir.pwd,'il_fatto_quotidiano_mailer.rb')

class IlFattoQuotidiano2Kindle
  def self.send
    config = YAML::load_file(File.join(Dir.pwd,"config.yml" ) )
    setting_up_smtp(config)
    begin
      agent = Mechanize.new { |agent|
        agent.user_agent_alias = 'Mac Safari'
      }

      puts "#{Time.now.to_s} - logging in on ilfatto..."
      agent.get(config['site_login_url']) do |page|
        login = page.form_with(:name => 'loginform')
        login.log = config['site_user_name']
        login.pwd = config['site_password']
        login.submit
      end
      puts "#{Time.now.to_s} - login done"
      date=Time.now.strftime("%Y%m%d")
      file_name = "/tmp/ilfatto#{date}.pdf"
      puts "#{Time.now.to_s} - getting pdf and saving in /tmp..."
      agent.get("#{config['site_hostname']}/openpdf/?n=#{date}").save_as(file_name)
      puts "#{Time.now.to_s} - done."
      puts "#{Time.now.to_s} - sending pdf to #{config['free_kindle_email']}..."
      IlFattoQuotidianoMailer.file(config['free_kindle_email'],config['user_email'], file_name, "application/pdf").deliver
      puts "#{Time.now.to_s} - done."
    rescue Exception => e
      puts "#{Time.now.to_s} - #{e.message}"
      puts "#{Time.now.to_s} - #{e.backtrace.inspect}"
    end
  end

  def self.setting_up_smtp config
    ActionMailer::Base.delivery_method = :sendmail
    # ActionMailer::Base.delivery_method = :smtp
    # ActionMailer::Base.smtp_settings = {
        # :enable_starttls_auto => true,
        # :address => "smtp.gmail.com",
        # :port => "587",
        # :domain => "gmail.com",
        # :authentication => :plain,
        # :user_name => config['smtp_user_name'],
        # :password => config['smtp_password']
      # }
  end
end

IlFattoQuotidiano2Kindle.send
