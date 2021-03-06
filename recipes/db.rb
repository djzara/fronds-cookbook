mysql_service 'fronds' do
  port '3306'
  version node['fronds']['db']['version']
  initial_root_password node['fronds']['db']['initial_root']
  bind_address '*'
  action [:create, :start]
end

mysql_client 'fronds' do
  action :create
end

mysql2_chef_gem 'default' do
  action :install
end

has_database = true
has_test_database = true
ruby_block 'create fronds database' do
  block do
    require 'mysql2'
    client = Mysql2::Client.new(:username => 'root', :password => node['fronds']['db']['initial_root'], :host => '127.0.0.1')
    begin

      client.select_db(node['fronds']['db']['name'])
    rescue Mysql2::Error
      has_database = false
    end

    begin
      client.select_db(node['fronds']['db']['test_name'])
    rescue Mysql2::Error
      has_test_database = false
    end

  end
end

execute 'create fronds database' do
  command "echo 'create database #{node['fronds']['db']['name']}' | mysql -u root -h 127.0.0.1 -p#{node['fronds']['db']['initial_root']}"
  only_if { !has_database }
end

execute 'create tcc test database' do
  command "echo 'create database #{node['fronds']['db']['test_name']}' | mysql -u root -h 127.0.0.1 -p#{node['fronds']['db']['initial_root']}"
  only_if { !has_test_database }
end
execute 'grants' do
  command "echo 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" IDENTIFIED BY
 \"#{node['fronds']['db']['initial_root']}\" WITH GRANT OPTION' | mysql -u root -h 127.0.0.1 -p#{node['fronds']['db']['initial_root']}"
  only_if { !has_test_database || !has_database}
end

