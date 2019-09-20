# =================================================================
# Copyright 2018 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =================================================================

# Cookbook Name:: workflow
# Library:: wf_helper
#
# <> library: Workflow helper
# <> Library Functions for the Workflow Cookbook

include Chef::Mixin::ShellOut

module WF
  # Helper module
  module Helper
    # get sub directories
    def subdirs_to_create(dir, user)
      Chef::Log.info "Dir to create: #{dir}, user: #{user}"
      existing_subdirs = []
      remaining_subdirs = dir.split('/')
      remaining_subdirs.shift # get rid of '/'

      until remaining_subdirs.empty?
        Chef::Log.info "remaining_subdirs: #{remaining_subdirs.inspect}, existing_subdirs: #{existing_subdirs.inspect}"
        path = existing_subdirs.push('/' + remaining_subdirs.shift).join
        break unless File.exist?(path)
        raise "Path #{path} exists and is a file, expecting directory." unless File.directory?(path)
        raise "Directory #{path} exists but is not traversable by #{user}." unless can_traverse?(user, path)
      end

      new_dirs = [existing_subdirs.join]
      new_dirs.push(new_dirs.last + '/' + remaining_subdirs.shift) until remaining_subdirs.empty?
      new_dirs
    end

    # determine if can traverse or not?
    def can_traverse?(user, path)
      return true if user == 'root'
      byme = File.stat(path).uid == -> { Etc.getpwnam(user).uid } && File.stat(path).mode & 64 == 64 # owner has x
      byus = File.stat(path).gid == -> { Etc.getpwnam(user).gid } && File.stat(path).mode & 8 == 8 # group has x
      byall = File.stat(path).mode & 1 == 1 # other has x
      byme || byus || byall
    end

    # determine if the passed-in hostname is host name of current node
    # TODO: consider if support IP as hostname?
    def self.same_node?(hostname, chostname)
      Chef::Log.info "same_node?(#{hostname}, #{chostname})"
      shorthostname = hostname
      shorthostname = hostname[0, hostname.index('.')] if !hostname.nil? && hostname.index('.')
      short_chname = chostname
      short_chname = chostname[0, chostname.index('.')] if !chostname.nil? && chostname.index('.')
      Chef::Log.info "same_node, short hostname: #{shorthostname}, short chostname: #{short_chname}"
      short_chname == shorthostname
    end

    def self.run_jython(os_user, profile_path, host, port, admin_user, admin_pwd, jython_file)
      security_credentials =
        if admin_user.nil?
          ''
        else
          "-user '#{admin_user}' -password '#{admin_pwd}'"
        end

      dmgr_connection_string =
        if host.nil?
          '-conntype NONE'
        else
          "-conntype SOAP -host '#{host}' -port '#{port}'"
        end

      wsadmin_cmd = shell_out!(%Q[ su - #{os_user} -c "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; #{profile_path}/bin/wsadmin.sh -lang jython -f #{jython_file} #{dmgr_connection_string} #{security_credentials}" ])
      wsadmin_cmd.stdout
    end

    def stop_env(runas_user, nodeIndex, serverName, runas_group, install_dir, wfadmin_user, wfadmin_password)
      Chef::Log.info "stop_env(#{runas_user}, #{nodeIndex}, #{serverName}, #{runas_group}, #{install_dir}, #{wfadmin_user}"
      stop_server(runas_user, nodeIndex, serverName, runas_group, install_dir, wfadmin_user, wfadmin_password)
      stop_nodeagent(runas_user, nodeIndex, runas_group, install_dir, wfadmin_user, wfadmin_password)
      stop_dmgr(runas_user, runas_group, install_dir, wfadmin_user, wfadmin_password)
    end

    def start_env(runas_user, nodeIndex, serverName, runas_group, install_dir, dmgr_hostname, wfadmin_user, wfadmin_password)
      Chef::Log.info "start_env(#{runas_user}, #{nodeIndex}, #{serverName}, #{runas_group}, #{install_dir}, #{dmgr_hostname}, #{wfadmin_user}"
      start_dmgr(runas_user, runas_group, install_dir)
      sync_node(runas_user, nodeIndex, runas_group, install_dir, dmgr_hostname, wfadmin_user, wfadmin_password)
      start_nodeagent(runas_user, nodeIndex, runas_group, install_dir)
      start_server(runas_user, nodeIndex, serverName, runas_group, install_dir)
    end

    def start_server(runas_user, nodeIndex, serverName, runas_group, install_dir)
      Chef::Log.info "start_server(#{runas_user}, #{nodeIndex}, #{serverName}, #{runas_group}, #{install_dir}"
      if server_stopped?(runas_user, nodeIndex, serverName)
        cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./startServer.sh #{serverName}"
        cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./startServer.sh SingleClusterMember1" if serverName.nil? || serverName.empty?
        execute 'start Server' do
          cwd "#{install_dir}/profiles/Node#{nodeIndex}Profile/bin"
          command cmd
          user runas_user
          group runas_group
          only_if { Dir.exist?("#{install_dir}/profiles/Node#{nodeIndex}Profile/bin") }
        end
      end
    end

    def stop_server(runas_user, nodeIndex, serverName, runas_group, install_dir, wfadmin_user, wfadmin_password)
      Chef::Log.info "stop_server(#{runas_user}, #{nodeIndex}, #{serverName}, #{runas_group}, #{install_dir}, #{wfadmin_user}"
      unless server_stopped?(runas_user, nodeIndex, serverName)
        cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./stopServer.sh #{serverName} -username #{wfadmin_user} -password #{wfadmin_password}"
        cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./stopServer.sh SingleClusterMember1 -username #{wfadmin_user} -password #{wfadmin_password}" if serverName.nil? || serverName.empty?
        execute 'stop Server' do
          cwd "#{install_dir}/profiles/Node#{nodeIndex}Profile/bin"
          command cmd
          user runas_user
          group runas_group
          only_if { Dir.exist?("#{install_dir}/profiles/Node#{nodeIndex}Profile/bin") }
        end
      end
    end

    def start_nodeagent(runas_user, nodeIndex, runas_group, install_dir)
      Chef::Log.info "start_nodeagent(#{runas_user}, #{nodeIndex}, #{runas_group}, #{install_dir}"
      if nodeagent_stopped?(runas_user, nodeIndex)
        execute 'start Node Agent' do
          cwd "#{install_dir}/profiles/Node#{nodeIndex}Profile/bin"
          command "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./startNode.sh"
          user runas_user
          group runas_group
          only_if { Dir.exist?("#{install_dir}/profiles/Node#{nodeIndex}Profile/bin") }
        end
      end
    end

    def stop_nodeagent(runas_user, nodeIndex, runas_group, install_dir, wfadmin_user, wfadmin_password)
      Chef::Log.info "stop_nodeagent(#{runas_user}, #{nodeIndex}, #{runas_group}, #{install_dir}, #{wfadmin_user}"
      unless nodeagent_stopped?(runas_user, nodeIndex)
        execute 'stop Node Agent' do
          cwd "#{install_dir}/profiles/Node#{nodeIndex}Profile/bin"
          command "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./stopNode.sh -username #{wfadmin_user} -password #{wfadmin_password}"
          user runas_user
          group runas_group
          only_if { Dir.exist?("#{install_dir}/profiles/Node#{nodeIndex}Profile/bin") }
        end
      end
    end

    def start_dmgr(runas_user, runas_group, install_dir)
      Chef::Log.info "start_dmgr(#{runas_user}, #{runas_group}, #{install_dir}"
      if dmgr_stopped?(runas_user)
        execute 'start Dmgr' do
          cwd "#{install_dir}/profiles/DmgrProfile/bin"
          command "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./startManager.sh"
          user runas_user
          group runas_group
          only_if { Dir.exist?("#{install_dir}/profiles/DmgrProfile") }
        end
      end
    end

    def sync_node(runas_user, nodeIndex, runas_group, install_dir, dmgr_hostname, wfadmin_user, wfadmin_password)
      Chef::Log.info "sync_node(#{runas_user}, #{nodeIndex}, #{runas_group}, #{install_dir}, #{dmgr_hostname}, #{wfadmin_user}"
        if nodeagent_stopped?(runas_user, nodeIndex)
            Chef::Log.info "Begin sync node"
            Chef::Log.info "Check soap port"
            (0..20).each do |i|
              ps_soap_out = shell_out("su - #{runas_user} -c \"export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; #{install_dir}/profiles/Node#{nodeIndex}Profile/bin/syncNode.sh  #{dmgr_hostname} 8879 -username #{wfadmin_user} -password #{wfadmin_password}\"")
              Chef::Log.info "#{ps_soap_out.stdout}"
              if ps_soap_out.stdout.include? "The configuration for node Node#{nodeIndex} has been synchronized"
                Chef::Log.info "Soap port ready"
                break
              else
                Chef::Log.info "Soap port not ready, waiting... #{i}"
                sleep(2*60)
                if i == 20
                  raise "Sync Node failed, suggest sync node and restart server manually."
                end
              end
            end

      #      execute 'sync Node' do
      #        cwd "#{install_dir}/profiles/Node#{nodeIndex}Profile/bin"
      #        command "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./syncNode.sh  #{dmgr_hostname} 8879 -username #{wfadmin_user} -password #{wfadmin_password}"
      #        user runas_user
      #        group runas_group
      #        only_if { Dir.exist?("#{install_dir}/profiles/Node#{nodeIndex}Profile") }
      #      end
            Chef::Log.info "End sync node"
        else
            Chef::Log.info "Ignore sync node because node agent is running"
        end
    end

    def stop_dmgr(runas_user, runas_group, install_dir, wfadmin_user, wfadmin_password)
      Chef::Log.info "stop_dmgr(#{runas_user}, #{runas_group}, #{install_dir}, #{wfadmin_user}"
      unless dmgr_stopped?(runas_user)
        execute 'stop Dmgr' do
          cwd "#{install_dir}/profiles/DmgrProfile/bin"
          command "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./stopManager.sh -username #{wfadmin_user} -password #{wfadmin_password}"
          user runas_user
          group runas_group
          only_if { Dir.exist?("#{install_dir}/profiles/DmgrProfile") }
        end
      end
    end

    def server_stopped?(runas_user, nodeIndex, serverName)
      Chef::Log.info "server_stopped?(#{runas_user}, #{nodeIndex}, #{serverName})"
      ps_server_out = shell_out("ps -o args -u #{runas_user} | grep \"Node#{nodeIndex} #{serverName}\"")
      ps_server_out.stdout == ''
    end

    def nodeagent_stopped?(runas_user, nodeIndex)
      Chef::Log.info "nodeagent_stopped?(#{runas_user}, #{nodeIndex})"
      ps_nodeagent_out = shell_out("ps -o args -u #{runas_user} | grep \"Node#{nodeIndex} nodeagent\"")
      ps_nodeagent_out.stdout == ''
    end

    def dmgr_stopped?(runas_user)
      Chef::Log.info "dmgr_stopped?( #{runas_user})"
      ps_dmgr_out = shell_out("ps -o args -u #{runas_user} | grep 'Dmgr dmgr'")
      ps_dmgr_out.stdout == ''
    end

    def get_dmgr_hostname(node_hostnames)
      serverName = nil
      node_hostnames = node_hostnames.split(",")

      index = 0
      valid_hnames = []
      node_hostnames.each do |node_hostname|
        Chef::Log.info("get_dmgr_hostname node: #{node_hostname}")
        # ignore if the node_hostname is not valid
        next if node_hostname.nil? || node_hostname.lstrip.empty?

        # remove the blanks before and after the node hostname
        serverName = node_hostname.lstrip.rstrip
        break
      end
      Chef::Log.info "get_dmgr_hostname result: #{serverName}"
      serverName
    end

    def compute_server_name(node_hostnames, current_hostname)
      Chef::Log.info "server_name(#{node_hostnames}, #{current_hostname})"

      serverName = nil
      node_hostnames = node_hostnames.split(",")

      index = 0
      valid_hnames = []
      node_hostnames.each do |node_hostname|
        Chef::Log.info("node: #{node_hostname}")
        # ignore if the node_hostname is not valid
        next if node_hostname.nil? || node_hostname.lstrip.empty?

        # remove the blanks before and after the node hostname
        node_hostname = node_hostname.lstrip.rstrip

        next if valid_hnames.include?(node_hostname)
        valid_hnames.push(node_hostname)

        index = index + 1

        # record current node's server name
        if WF::Helper.same_node?(node_hostname,current_hostname)
          serverName = "SingleClusterMember#{index}"
          break
        end
      end

      serverName = valid_hnames.at(0) if serverName.nil? && index == 1
      Chef::Log.info "compute_server_name result: #{serverName}"
      serverName
    end

    def compute_node_index(node_hostnames, current_hostname)
      Chef::Log.info "node_index(#{node_hostnames}, #{current_hostname})"

      nodeIndex = nil
      node_hostnames = new_resource.node_hostnames.split(",")

      index = 0
      valid_hnames = []
      node_hostnames.each do |node_hostname|
        Chef::Log.info("node: #{node_hostname}")
        # ignore if the node_hostname is not valid
        next if node_hostname.nil? || node_hostname.lstrip.empty?

        # remove the blanks before and after the node hostname
        node_hostname = node_hostname.lstrip.rstrip

        next if valid_hnames.include?(node_hostname)
        valid_hnames.push(node_hostname)

        index = index + 1

        # record current node's index
        if WF::Helper.same_node?(node_hostname, current_hostname)
          nodeIndex = index
          break
        end
      end

      nodeIndex = 1 if nodeIndex.nil? && index == 1
      Chef::Log.info "compute_node_index result: #{nodeIndex}"
      nodeIndex
    end
  end
end
