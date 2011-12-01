require 'rubygems'
require 'net/http'
require 'mechanize'
require 'yaml'
require 'mail'
require 'aws/ses'

class IlFattoQuotidiano2Kindle
  def self.send
    config = YAML::load_file(File.join(Dir.pwd,"config.yml" ) )
    begin
      agent = Mechanize.new { |agent|
        agent.user_agent_alias = 'Mac Safari'
      }

      log("logging in on ilfatto...")
      agent.get(config['site_login_url']) do |page|
        login = page.form_with(:name => 'loginform')
        login.log = config['site_user_name']
        login.pwd = config['site_password']
        login.submit
      end
      log("login done")
      date=Time.now.strftime("%Y%m%d")
      file_name = "/tmp/ilfatto#{date}.pdf"
      log("getting pdf and saving in /tmp...")
      agent.get("#{config['site_hostname']}/openpdf/?n=#{date}").save_as(file_name)
      log("done.")
      mail = Mail.new
      mail.to = config['free_kindle_email']
      mail.from = config['user_email']
      mail.subject = "ilfatto#{date}"
      mail.attachments["ilfatto#{date}.pdf"] = File.read(file_name)
      mail.body = "ilfatto#{date}"
      send_with_gmail(mail)
      # send_with_ses(mail)
      log("email sent")
      log("done.")
    rescue Exception => e
      log("#{e.message}")
      log("#{e.backtrace.inspect}")
    end
  end

  def self.send_with_gmail(mail)
    mail.delivery_method :smtp, { :address              => "smtp.gmail.com",
                                 :port                 => 587,
                                 :domain               => 'gmail.com',
                                 :user_name            => 'a.carpe',
                                 :password             => '',
                                 :authentication       => 'plain',
                                 :enable_starttls_auto => true }
    mail.deliver!
  end

  def self.send_with_ses(mail)
    ses = AWS::SES::Base.new(
            :access_key_id     => '',
            :secret_access_key => ''
            )
    ses.send_raw_email(mail)
  end
  def self.log(message)
     puts "#{Time.now.to_s} - #{message}"
  end

end

IlFattoQuotidiano2Kindle.send
