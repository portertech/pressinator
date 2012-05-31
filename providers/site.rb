#
# Cookbook Name:: pressinator
# Provider:: site
#
# Copyright 2012, Sean Porter Consulting
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

class Chef::Provider
  include Pressinator::OpenSSL
end

action :create do
  site_path = ::File.join(node.wordpress.root, new_resource.vhost)

  remote_file "/usr/src/wordpress-#{node.wordpress.version}.tar.gz" do
    checksum node.wordpress.checksum
    source "http://wordpress.org/wordpress-#{node.wordpress.version}.tar.gz"
    mode 0644
  end

  execute "echo '/bin/false' >> /etc/shells" do
    not_if "grep /bin/false /etc/shells"
  end

  user new_resource.ftp_user do
    home site_path
    password shadow_hash(new_resource.ftp_password)
    shell "/bin/false"
  end

  directory site_path do
    recursive true
    owner new_resource.ftp_user
    mode 0755
  end

  execute "untar-wordpress-#{new_resource.vhost}" do
    command "tar --strip-components 1 -xzf /usr/src/wordpress-#{node.wordpress.version}.tar.gz"
    cwd site_path
    user new_resource.ftp_user
    action :nothing
    subscribes :run, resources(:directory => site_path), :immediately
    only_if { (::Dir.entries(site_path) - %w[. ..]).count == 0 }
  end

  bash "mysql-setup-#{new_resource.vhost}" do
    code <<-EOH
    mysql -u root -p#{node.mysql.server_root_password} -e "
    CREATE DATABASE #{new_resource.db_name};
    GRANT ALL ON #{new_resource.db_name}.* TO '#{new_resource.db_user}'@'%' IDENTIFIED BY '#{new_resource.db_password}';
    FLUSH PRIVILEGES;
    "
    EOH
    action :nothing
    subscribes :run, resources(:directory => site_path), :immediately
  end

  template ::File.join(site_path, "wp-config.php") do
    owner new_resource.ftp_user
    mode 0644
    variables(
      :db_name => new_resource.db_name,
      :db_user => new_resource.db_user,
      :db_password => new_resource.db_password,
      :auth_key => secure_password(64),
      :secure_auth_key => secure_password(64),
      :logged_in_key => secure_password(64),
      :nonce_key => secure_password(64),
      :auth_salt => secure_password(64),
      :secure_auth_salt => secure_password(64),
      :logged_in_salt => secure_password(64),
      :nonce_salt => secure_password(64)
    )
    action :nothing
    subscribes :create, resources(:execute => "untar-wordpress-#{new_resource.vhost}"), :immediately
  end
end
