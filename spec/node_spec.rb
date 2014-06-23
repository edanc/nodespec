require 'nodespec/node'

module NodeSpec
  describe Node do
    shared_examples 'node_attributes' do |attributes|
      it "has the expected attributes" do
        expect(subject.os).to eq(attributes[:os])
        expect(subject.backend).to eq(attributes[:backend])
        expected_remote_connection = attributes[:remote_connection] ? remote_connection : nil
        expect(subject.remote_connection).to eq(expected_remote_connection)
      end
    end

    shared_examples 'run command' do |helper|
      it "has runs a command through a command helper" do
        expect(command_helpers[helper]).to receive(:execute).with('test command')
        
        subject.execute_command('test command')
      end
    end

    let(:rspec_subject) {double('rspec subject')}
    let(:command_helpers) {
      {
        exec_helper:  double('exec_helper'),
        cmd_helper:   double('cmd_helper'),
        ssh_helper:   double('ssh_helper'),
        winrm_helper: double('winrm_helper')
      }
    }

    before do
      CommandHelpers::Exec.stub(:new => command_helpers[:exec_helper])
      CommandHelpers::Cmd.stub(:new => command_helpers[:cmd_helper])
      CommandHelpers::Ssh.stub(:new).with('remote session').and_return(command_helpers[:ssh_helper])
      CommandHelpers::WinRM.stub(:new).with('remote session').and_return(command_helpers[:winrm_helper])
    end

    it 'does not change the original options' do
      Node.new('test_node', {'os' => 'test', 'foo' => 'bar'}.freeze)
    end

    it 'returns the node name' do
      subject = Node.new('test_node', {'os' => 'test', 'foo' => 'bar'})
      expect(subject.name).to eq('test_node')
    end

    context 'no options' do
      let(:subject) {Node.new('test_node')}
      
      include_examples 'node_attributes', {os: nil, backend: 'Exec', remote_connection: nil}
      include_examples 'run command', :exec_helper
    end

    context 'options with unix-like os' do
      let(:subject) {Node.new('test_node', 'os' => 'Solaris')}
      
      include_examples 'node_attributes', {os: 'Solaris', backend: 'Exec', remote_connection: nil}
      include_examples 'run command', :exec_helper
    end

    context 'options with windows os' do
      let(:subject) {Node.new('test_node', 'os' => 'Windows')}

      include_examples 'node_attributes', {os: 'Windows', backend: 'Cmd', remote_connection: nil}
      include_examples 'run command', :cmd_helper
    end

    context 'options with adapter' do
      let(:adapter) {double('adapter')}
      let(:remote_connection) {double('remote connection')}
      before do
        allow(ConnectionAdapters).to receive(:get).with('test_node', 'test_adapter', 'foo' => 'bar').and_return(adapter)
        adapter.stub(connection: remote_connection)
        remote_connection.stub(session: 'remote session')
      end

      context 'no os given' do
        let(:subject) {Node.new('test_node', 'adapter' => 'test_adapter', 'foo' => 'bar')}

        include_examples 'node_attributes', {os: nil, backend: 'Ssh', remote_connection: true}
        include_examples 'run command', :ssh_helper
      end

      context 'unix-like os given' do
        let(:subject) {Node.new('test_node', 'os' => 'Solaris', 'adapter' => 'test_adapter', 'foo' => 'bar')}

        include_examples 'node_attributes', {os: 'Solaris', backend: 'Ssh', remote_connection: true}
        include_examples 'run command', :ssh_helper
      end

      context 'windows os given' do
        let(:subject) {Node.new('test_node', 'os' => 'Windows', 'adapter' => 'test_adapter', 'foo' => 'bar')}

        include_examples 'node_attributes', {os: 'Windows', backend: 'WinRM', remote_connection: true}
        include_examples 'run command', :winrm_helper
      end
    end
  end
end