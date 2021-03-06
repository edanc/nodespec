require 'spec_helper'
require 'nodespec/communication_adapters/vagrant'

module NodeSpec
  module CommunicationAdapters
    describe Vagrant do
      [['test_vm', 'test_os'], ['test_node', {'vm_name' => 'test_vm'}]].each do |args|
        describe "#communicator_for" do
          let(:cmd_status) { double('status') }

          before(:each) do
            expect(Open3).to receive(:capture2e).with('vagrant --machine-readable ssh-config test_vm').and_return([cmd_output, cmd_status])
          end

          context 'vm not running' do
            let(:cmd_output) {
              '1402310908,,error-exit,Vagrant::Errors::SSHNotReady,The provider...'
            }

            it 'raises an error' do
              allow(cmd_status).to receive(:success?).and_return(false)

              expect {Vagrant.communicator_for(*args)}.to raise_error 'Vagrant::Errors::SSHNotReady,The provider...'
            end
          end

          context 'vm running' do
            let(:cmd_output) {
              <<-EOS
Host test_vm
  HostName test.host.name
  User testuser
  Port 1234
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /test/path/private_key
  IdentitiesOnly yes
  LogLevel FATAL
EOS
            }

            include_context 'new_ssh_communicator', 'test.host.name', {
              'user' => 'testuser',
              'port' => 1234,
              'keys' => '/test/path/private_key'
            } do
              before do
                allow(cmd_status).to receive(:success?).and_return(true)
              end

              it 'returns and ssh communicator initialized from the vagrant command output' do
                expect(Vagrant.communicator_for(*args)).to eq('ssh communicator')
              end
            end
          end
        end
      end
    end
  end
end