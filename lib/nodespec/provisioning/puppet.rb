require 'shellwords'
require 'nodespec/node_proxy'

module NodeSpec
  module Provisioning
    class Puppet
      include NodeProxy

      def set_modulepaths(*paths)
        @modulepath_option = "--modulepath #{paths.join(':').shellescape}" unless paths.empty?
      end

      def set_facts(facts)
        @facts = facts.reduce("") { |fact, pair| "FACTER_#{pair[0]}=#{pair[1].shellescape} #{fact}" }
      end

      def puppet_apply_execute(snippet, options = [])
        execute_command("#{group_command_options(options)} -e #{snippet.shellescape}")
      end

      def puppet_apply_manifest(manifest_file, options = [])
        execute_command("#{group_command_options(options)} #{manifest_file.shellescape}")
      end

      private

      def group_command_options(options)
        %Q[#{@facts}puppet apply #{@modulepath_option} #{options.join(' ')}]
      end
    end
  end
end