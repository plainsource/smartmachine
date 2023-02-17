God.watch do |w|
  w.name = "letsencrypt"
  w.start = "/etc/god/process.d/letsencrypt.rb"
  w.keepalive
end
