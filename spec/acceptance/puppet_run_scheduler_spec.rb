# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'puppet_run_scheduler' do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<~PUPPET
        # the cron type needs crontab, which container images don't ship
        $cron_package = $facts['os']['family'] ? {
          'RedHat' => 'cronie',
          default  => 'cron',
        }
        package { $cron_package:
          ensure => installed,
          before => Class['puppet_run_scheduler'],
        }

        class { 'puppet_run_scheduler':
          run_interval => '4h',
          splaylimit   => '1h',
        }
      PUPPET
    end
  end

  describe command('crontab -l -u root') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{^# Puppet Name: puppet-run-scheduler$} }
    its(:stdout) { is_expected.to match %r{^\d+ (\d+,){5}\d+ \* \* \* /opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --splay --splaylimit=60s >/dev/null 2>&1$} }
  end

  describe service('puppet') do
    it { is_expected.not_to be_enabled }
    it { is_expected.not_to be_running }
  end
end
