maintainer       "Sean Porter Consulting"
maintainer_email "portertech@gmail.com"
license          "MIT"
description      "Chef cookbook for multi-tenant Wordpress hosting"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

%w[
  php
  apache2
  mysql
  vsftpd
].each do |cookbook|
  depends cookbook
end
