#
# Cookbook Name:: apache
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# httpd should be installed
package "httpd" do
  action :install
end

# The service should be enabled and started
service "httpd" do
  action [:enable, :start]
end

# Disable the default virtual host
welcome_file = "/etc/httpd/conf.d/welcome.conf"
execute "mv #{welcome_file} /etc/httpd/conf.d/welcome.conf.disabled" do
  only_if do
    File.exist?(welcome_file)
  end
  notifies :restart, "service[httpd]"
end

# Iterate over the apache sites
node["apache"]["sites"].each do |site_name, site_data|
  
  # Use the LWRP we've created for a new site
  apache_vhost "#{site_name}" do
    site_port site_data['port']
    action :create
    notifies :restart, "service[httpd]"
  end

end

