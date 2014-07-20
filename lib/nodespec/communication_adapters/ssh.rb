require 'net/ssh'
require_relative 'ssh_communicator'

module NodeSpec
  module CommunicationAdapters
    class Ssh
      def self.communicator_for(node_name, os = nil, options = {})
        opts = options.dup
        host = opts.delete('host') || node_name
        SshCommunicator.new(host, os, opts)
      end
    end
  end
end