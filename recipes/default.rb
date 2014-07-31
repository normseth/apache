#
# Cookbook Name:: apache
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# httpd should be installed
package "httpd"

if node["apache"]["enable_ssl"] then

  package "mod_ssl"

  template "/etc/httpd/conf.d/ssl.conf" do
    source 'ssl.conf.erb'
  end

  # create ssl cert/key directories
  directory "#{node['apache']['cert_dir']}" do
    recursive true
    owner 'root'
    group 'root'
    mode '0755'
  end

  directory "#{node['apache']['key_dir']}" do
    recursive true
    owner 'root'
    group 'root'
    mode '0700'
  end

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
  # set document root
  document_root = "/srv/apache/#{site_name}"

  # add template for virtual host config
  template "/etc/httpd/conf.d/#{site_name}.conf" do
    source "custom.erb"
    mode "0644"
    variables(
      :site_name => site_name,
      :document_root => document_root,
      :port => site_data["port"],
      :https_port => site_data["https_port"]
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

  # Install site certificate if SSL
  if site_data['https_port'] then

    cert_data = Chef::EncryptedDataBagItem.load("certs", "#{site_name}")

    template "#{node['apache']['cert_dir']}/#{site_name}.crt" do
      source 'site.crt.erb'
      mode '0644'
      variables( :ssl_cert => cert_data['cert'] )
    end

    template  "#{node['apache']['key_dir']}/#{site_name}.key" do
      source 'site.key.erb'
      mode '0600'
      variables( :ssl_key => cert_data['key'] )
    end

  end


end

# The service should be enabled and started
service "httpd" do
  action [:enable, :start]
end
