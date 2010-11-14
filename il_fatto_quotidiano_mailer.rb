require 'action_mailer'

class IlFattoQuotidianoMailer < ActionMailer::Base
  def file(to, sender, file_name, content_type, strip_ext = true)
      # strip any directory fluff 
      subj = file_name.gsub(/.*\//,'')
      #remove the file extension if required
      subj = subj.gsub(/\.\w*/,'') if strip_ext
      #set up the attachment
      attachments[file_name.gsub(/.*\//,'')] = File.read(file_name)
      mail(:to => to, :from => sender, :subject => subj, :body => subj, :date => Time.now)
  end
end
