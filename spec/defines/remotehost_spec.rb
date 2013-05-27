require 'spec_helper'

describe 'ssh-userconfig::remotehost' do
  some_unix_user = 'unixuser'
  some_host = 'github.com'
  default_port = '22'
  some_git_remote_user = 'git'
  some_hostalias = "github_com_somerepo"

  some_private_key_content = 'some private content'
  some_public_key_content = 'some public content'
  ssh_config_dir_prefix = "/home/#{some_unix_user}/.ssh"
  ssh_config_file = "#{ssh_config_dir_prefix}/config"
  synthesized_privkey_path = "#{ssh_config_dir_prefix}/id_rsa_#{some_hostalias}"
  synthesized_pubkey_path = "#{ssh_config_dir_prefix}/id_rsa_#{some_hostalias}.pub"

  let(:facts) { {
    :concat_basedir => '/var/lib/puppet/concat'
  } }

  let (:title) { some_hostalias }
  let (:params) {
    {
      :unix_user => some_unix_user,
      :remote_hostname => some_host,
      :remote_username => some_git_remote_user,
      :private_key_content => some_private_key_content,
      :public_key_content => some_public_key_content
    }
  }

  it 'should create a host config for a given unix user => hostalias/host/user/port/privkey/pubkey/' do

    should contain_concat(ssh_config_file) \
      .with({
        :owner => some_unix_user,
      })

    should contain_concat__fragment("ssh_userconfig_#{some_unix_user}_#{some_hostalias}")\
      .with_content(%r{Host #{some_hostalias}
  HostName #{some_host}
  Port #{default_port}
  User #{some_git_remote_user}
  IdentityFile #{synthesized_privkey_path}}u)\
      .with_target(ssh_config_file)
  end

  it 'should create the pubkey/privkey files for a given unix user => hostalias/host/user/port/privkey/pubkey key' do
    should contain_file(synthesized_privkey_path).with_content(some_private_key_content)
    should contain_file("/home/#{some_unix_user}/.ssh/id_rsa_#{some_hostalias}.pub").with_content(some_public_key_content)
  end

  it 'should set the appropriate rights for keypair' do
    {
      synthesized_privkey_path => some_private_key_content,
      synthesized_pubkey_path => some_public_key_content
    }.each_pair do |path, content|
      should contain_file(path) \
        .with ({
          :ensure   => 'present',
          :content  => content,
          :owner    => some_unix_user,
          :mode     => '600',
          :require  => "File[#{ssh_config_dir_prefix}]"
        })
    end
  end

  it 'should create the .ssh folder for the given unix user' do
    should contain_file(ssh_config_dir_prefix) \
      .with ({
        :ensure => 'directory',
        :owner  => some_unix_user,
        :mode   => '700'
      })
  end

  it 'should have a configurable port' do
    params[:remote_port] = 2022
    should contain_concat__fragment("ssh_userconfig_#{some_unix_user}_#{some_hostalias}")\
      .with_content(%r{^\s+Port 2022$})
  end

end