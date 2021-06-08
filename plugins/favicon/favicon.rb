favicon = Lux.root.join('./public/favicon.png')

die './public/favicon.png not found' unless favicon.exist?

favicon = favicon.read

Lux.app.before do
  if ['/favicon.ico', '/apple-touch-icon.png'].include?(request.path.downcase)
    response.send_file('favicon.png', inline: true, content: favicon)
  end
end
