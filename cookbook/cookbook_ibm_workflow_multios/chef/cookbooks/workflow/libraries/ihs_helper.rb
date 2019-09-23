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
# Library:: ihs_helper
#
# <> library: IHS helper
# <> Library Functions for the Workflow Cookbook

include Chef::Mixin::ShellOut

module IHS
  # Helper module
  module Helper
    # Determine if IHS is already running
    def pid_file(install_dir, user = 'root')
      Chef::Log.info "pid_file(#{install_dir}, #{user})"

      pid_file_cmd = "awk '/^PidFile/ { print $2 }' #{install_dir}/conf/httpd.conf"
      pid_file_cmd_out = run_shell_cmd(pid_file_cmd, user)

      pid_file = "#{install_dir}/" + pid_file_cmd_out.stdout.lstrip.rstrip if !pid_file_cmd_out.stdout.nil?
      Chef::Log.info "PidFile configured: #{pid_file}"
      if pid_file.nil? || !File.exist?("#{pid_file}")
        pid_file = "#{install_dir}/logs/httpd.pid"
      end
      Chef::Log.info "PidFile: #{pid_file}"

      pid_file
    end

    # Run shell command
    def run_shell_cmd(cmd, user)
      shell_command = if user == 'root'
                        cmd
                      else
                        "su - #{user} -s /bin/sh -c \"#{cmd}\""
                      end
      shell_out!(shell_command)
    end
  end
end

Chef::Recipe.send(:include, IHS::Helper)
Chef::Resource.send(:include, IHS::Helper)