default["apache"]["enable_ssl"] = true
default["apache"]["cert_dir"] = '/etc/ssl/certs'
default["apache"]["key_dir"] = '/etc/ssl/private'
default["apache"]["sites"]["www.clowns.com"] = {:port => 80}
default["apache"]["sites"]["www.bears.com"] = {:port => 81, :https_port => 444}
