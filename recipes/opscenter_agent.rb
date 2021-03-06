include_recipe "ark"

ark "#{node[:cassandra][:opscenter][:agent][:install_folder_name]}" do
  path node[:cassandra][:opscenter][:agent][:install_dir]
  url node[:cassandra][:opscenter][:agent][:download_url]
  checksum node[:cassandra][:opscenter][:agent][:checksum]
  action :put
end

server_ip = node[:cassandra][:opscenter][:agent][:server_host]
if !server_ip
  search_results = search(:node, "roles:#{node[:cassandra][:opscenter][:agent][:server_role]}")
  unless search_results.empty?
    server_ip = search_results[0]['ipaddress']
  else
    return # Continue until opscenter will come up
  end
end 

agent_dir = "#{node[:cassandra][:opscenter][:agent][:install_dir]}/#{node[:cassandra][:opscenter][:agent][:install_folder_name]}"

template "#{agent_dir}/conf/address.yaml" do
  mode 0644
  source "opscenter-agent.conf.erb"
  variables({
    :server_ip => server_ip
  })
  notifies :restart, "service[opscenter-agent]"
end

service "opscenter-agent" do
  provider Chef::Provider::Service::Simple
  supports :start => true, :status => true, :stop => true
  start_command "#{agent_dir}/bin/opscenter-agent"
  status_command "ps aux | grep -q '[o]pscenter-agent'"
  stop_command "kill $(ps aux | grep '[o]pscenter-agent' | awk '{print $2}')"
  action :start
end
