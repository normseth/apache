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

# Use the LWRP we've created for a new site
apache_vhost "lions" do
  site_port 8080
  action :create
  notifies :restart, "service[httpd]"
end

# Iterate over the apache sites
node["apache"]["sites"].each do |site_name, site_data|
  # set document root
  document_root = "/srv/apache#{site_name}"
  
  # add template for virtual host config
  template "/etc/httpd/conf.d/#{site_name}.conf" do
    source "custom.erb"
    mode "0644"
    variables(
      :document_root => document_root,
      :port => site_data["port"]      
     )
     notifies :restart, "service[httpd]"
  end
  
  # Add a dir resource to create the document_root
  directory document_root do
    mode "0755"
    recursive true
  end
  
  # Add a template resource for the virtual host's index.html
  template "#{document_root}/index.html" do
    source "index.html.erb"
    mode "0644"
    variables(:site_name => site_name, :port => site_data["port"])
  end
end

