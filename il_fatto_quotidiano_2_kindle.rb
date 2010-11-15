require 'rubygems'
require 'net/http'
require 'mechanize'
require 'yaml'

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
      log("logging into Gmail to send the email")
      page = agent.get("http://www.gmail.com")
      login_form = page.forms.first
      login_form.Email = config['smtp_user_name']
      login_form.Passwd = config['smtp_password']
      home = agent.submit(login_form, login_form.buttons.first)
      log("logged into Gmail")
      log("loading HTML Gmail interface")
      page = agent.get(home.search("//meta").first.attributes['content'].to_s.gsub(/0; url=/,'').gsub(/'/,''))
      page = agent.get(page.uri.to_s.sub(/\?.*$/, "?ui=html&zy=n"))
      log("HTML Gmail interface loaded")
      log("composing email...")
      page = agent.click(page.links.find { |l| l.text =~ /compose/i })
      form = page.forms[1]
      form.to = config['free_kindle_email']
      form.subject = "ilfatto#{date}"
      form.file_uploads.first.file_name = file_name
      form.body = "ilfatto#{date}"
      page = agent.submit(form, form.buttons.first)
      log("email sent")
      log("done.")
    rescue Exception => e
      log("#{e.message}")
      log("#{e.backtrace.inspect}")
    end
  end

  def self.log(message)
     puts "#{Time.now.to_s} - #{message}"
  end

end

IlFattoQuotidiano2Kindle.send
