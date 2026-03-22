# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Onboard::Runners::Provision do
  let(:provisioner) { Class.new { include Legion::Extensions::Onboard::Runners::Provision }.new }

  describe '#provision' do
    context 'when all steps succeed' do
      before do
        allow(provisioner).to receive(:create_vault_namespace).and_return({ result: true })
        allow(provisioner).to receive(:create_consul_partition).and_return({ result: true })
        allow(provisioner).to receive(:create_tfe_project).and_return({ result: true })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns completed status' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:status]).to eq('completed')
      end

      it 'includes the askid' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:askid]).to eq('app-12345')
      end

      it 'reports all steps as passed' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:steps].size).to eq(4)
        expect(result[:steps].all? { |s| s[:status] == 'ok' }).to be true
      end
    end

    context 'when vault namespace creation fails' do
      before do
        allow(provisioner).to receive(:create_vault_namespace).and_raise(StandardError, 'Vault 403')
        allow(provisioner).to receive(:create_consul_partition).and_return({ result: true })
        allow(provisioner).to receive(:create_tfe_project).and_return({ result: true })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns failed status' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:status]).to eq('failed')
      end

      it 'identifies the failed step' do
        result = provisioner.provision(askid: 'app-12345')
        vault_step = result[:steps].find { |s| s[:name] == 'vault_namespace' }
        expect(vault_step[:status]).to eq('error')
        expect(vault_step[:error]).to include('Vault 403')
      end

      it 'still attempts remaining steps' do
        result = provisioner.provision(askid: 'app-12345')
        consul_step = result[:steps].find { |s| s[:name] == 'consul_partition' }
        expect(consul_step[:status]).to eq('ok')
      end
    end

    context 'when consul partition creation fails' do
      before do
        allow(provisioner).to receive(:create_vault_namespace).and_return({ result: true })
        allow(provisioner).to receive(:create_consul_partition).and_raise(StandardError, 'Consul 500')
        allow(provisioner).to receive(:create_tfe_project).and_return({ result: true })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns failed status' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:status]).to eq('failed')
      end
    end

    context 'when tfe project creation fails' do
      before do
        allow(provisioner).to receive(:create_vault_namespace).and_return({ result: true })
        allow(provisioner).to receive(:create_consul_partition).and_return({ result: true })
        allow(provisioner).to receive(:create_tfe_project).and_raise(StandardError, 'TFE timeout')
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns failed status' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:status]).to eq('failed')
      end
    end

    context 'with custom organization' do
      before do
        allow(provisioner).to receive(:create_vault_namespace).and_return({ result: true })
        allow(provisioner).to receive(:create_consul_partition).and_return({ result: true })
        allow(provisioner).to receive(:create_tfe_project).and_return({ result: true })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'accepts a custom tfe_organization' do
        result = provisioner.provision(askid: 'app-99', tfe_organization: 'custom.tfe.com')
        expect(result[:status]).to eq('completed')
      end
    end

    context 'with slack webhook for notification' do
      before do
        allow(provisioner).to receive(:create_vault_namespace).and_return({ result: true })
        allow(provisioner).to receive(:create_consul_partition).and_return({ result: true })
        allow(provisioner).to receive(:create_tfe_project).and_return({ result: true })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'includes notification step' do
        result = provisioner.provision(askid: 'app-12345', requester_slack_webhook: '/services/T/B/x')
        notify_step = result[:steps].find { |s| s[:name] == 'notify' }
        expect(notify_step[:status]).to eq('ok')
      end
    end
  end
end
