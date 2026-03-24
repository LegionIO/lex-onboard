# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Onboard::Runners::Provision do
  let(:provisioner) { Class.new { include Legion::Extensions::Onboard::Runners::Provision }.new }

  describe '#provision' do
    context 'when all steps succeed' do
      before do
        allow(provisioner).to receive(:vault_namespace).and_return({ step: :vault_namespace, status: 'completed' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'completed' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'completed' })
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

      it 'reports all steps as completed' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:steps].size).to eq(3)
        expect(result[:steps].all? { |s| s[:status] == 'completed' }).to be true
        expect(result[:rollback]).to eq([])
      end
    end

    context 'when vault namespace creation fails' do
      before do
        allow(provisioner).to receive(:vault_namespace).and_return({ step: :vault_namespace, status: 'error', error: 'Vault 403' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'completed' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'completed' })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns failed status' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:status]).to eq('failed')
      end

      it 'identifies the failed step' do
        result = provisioner.provision(askid: 'app-12345')
        vault_step = result[:steps].find { |s| s[:step] == :vault_namespace }
        expect(vault_step[:status]).to eq('error')
        expect(vault_step[:error]).to include('Vault 403')
      end

      it 'exits after the failed step without running remaining steps' do
        result = provisioner.provision(askid: 'app-12345')
        consul_step = result[:steps].find { |s| s[:step] == :consul_partition }
        expect(consul_step).to be_nil
        expect(result[:rollback]).to eq([])
      end
    end

    context 'when consul partition creation fails' do
      before do
        allow(provisioner).to receive(:vault_namespace).and_return({ step: :vault_namespace, status: 'completed' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'error', error: 'Consul 500' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'completed' })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns failed status' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:status]).to eq('failed')
      end
    end

    context 'when tfe project creation fails' do
      before do
        allow(provisioner).to receive(:vault_namespace).and_return({ step: :vault_namespace, status: 'completed' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'completed' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'error', error: 'TFE timeout' })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns failed status' do
        result = provisioner.provision(askid: 'app-12345')
        expect(result[:status]).to eq('failed')
      end
    end

    context 'with custom organization' do
      before do
        allow(provisioner).to receive(:vault_namespace).and_return({ step: :vault_namespace, status: 'completed' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'completed' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'completed' })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'accepts a custom tfe_organization' do
        result = provisioner.provision(askid: 'app-99', tfe_organization: 'custom.tfe.com')
        expect(result[:status]).to eq('completed')
      end
    end

    context 'with slack webhook for notification' do
      before do
        allow(provisioner).to receive(:vault_namespace).and_return({ step: :vault_namespace, status: 'completed' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'completed' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'completed' })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'calls notify_requester when webhook provided' do
        provisioner.provision(askid: 'app-12345', requester_slack_webhook: '/services/T/B/x')
        expect(provisioner).to have_received(:notify_requester)
      end
    end

    context 'notification step sends correct parameters' do
      let(:slack_client) { double('slack_client') }

      before do
        stub_const('Legion::Extensions::Slack::Client', Class.new)
        allow(Legion::Extensions::Slack::Client).to receive(:new).and_return(slack_client)
        allow(slack_client).to receive(:send_webhook)
        allow(provisioner).to receive(:vault_namespace).and_return({ step: :vault_namespace, status: 'completed' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'completed' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'completed' })
      end

      it 'calls send_webhook with message: parameter' do
        provisioner.provision(askid: 'test-app', requester_slack_webhook: 'https://hooks.slack.com/test')
        expect(slack_client).to have_received(:send_webhook).with(
          hash_including(message: anything, webhook: 'https://hooks.slack.com/test')
        )
      end
    end

    context 'when tfe_project step fails' do
      let(:vault_client) { double('vault_client') }
      let(:consul_client) { double('consul_client') }
      let(:tfe_client) { double('tfe_client') }

      before do
        stub_const('Legion::Extensions::Vault::Client', Class.new)
        stub_const('Legion::Extensions::Consul::Client', Class.new)
        stub_const('Legion::Extensions::Tfe::Client', Class.new)
        allow(Legion::Extensions::Vault::Client).to receive(:new).and_return(vault_client)
        allow(Legion::Extensions::Consul::Client).to receive(:new).and_return(consul_client)
        allow(Legion::Extensions::Tfe::Client).to receive(:new).and_return(tfe_client)
        allow(vault_client).to receive(:list_namespaces).and_return({ namespaces: [] })
        allow(vault_client).to receive(:create_namespace).and_return({ success: true })
        allow(vault_client).to receive(:delete_namespace)
        allow(consul_client).to receive(:list_partitions).and_return({ partitions: [] })
        allow(consul_client).to receive(:create_partition).and_return({ success: true })
        allow(consul_client).to receive(:delete_partition)
        allow(tfe_client).to receive(:list_projects).and_return({ projects: [] })
        allow(tfe_client).to receive(:create_project).and_raise(StandardError, 'TFE API error')
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'returns failed status' do
        result = provisioner.provision(askid: 'test-app')
        expect(result[:status]).to eq('failed')
      end

      it 'rolls back consul partition and vault namespace' do
        result = provisioner.provision(askid: 'test-app')
        expect(result[:rollback]).not_to be_empty
        expect(consul_client).to have_received(:delete_partition)
        expect(vault_client).to have_received(:delete_namespace)
      end
    end

    context 'with invalid askid' do
      it 'rejects without attempting any steps' do
        result = provisioner.provision(askid: 'INVALID_APP')
        expect(result[:status]).to eq('rejected')
        expect(result[:reason]).to include('format')
      end
    end

    context 'with conflicting askid' do
      before do
        allow(provisioner).to receive(:check_conflicts).and_return(
          { conflicts: [:vault], askid: 'existing-app' }
        )
      end

      it 'rejects with conflict details' do
        result = provisioner.provision(askid: 'existing-app')
        expect(result[:status]).to eq('rejected')
        expect(result[:reason]).to include('conflict')
      end
    end

    context 'when vault namespace already exists' do
      let(:vault_client) { double('vault_client') }

      before do
        stub_const('Legion::Extensions::Vault::Client', Class.new)
        allow(Legion::Extensions::Vault::Client).to receive(:new).and_return(vault_client)
        allow(vault_client).to receive(:list_namespaces).and_return({ namespaces: ['test-app'] })
        allow(vault_client).to receive(:create_namespace)
        allow(provisioner).to receive(:check_conflicts).and_return({ conflicts: [], askid: 'test-app' })
        allow(provisioner).to receive(:consul_partition).and_return({ step: :consul_partition, status: 'completed' })
        allow(provisioner).to receive(:tfe_project).and_return({ step: :tfe_project, status: 'completed' })
        allow(provisioner).to receive(:notify_requester).and_return(true)
      end

      it 'skips vault namespace creation' do
        result = provisioner.provision(askid: 'test-app')
        vault_step = result[:steps].find { |s| s[:step] == :vault_namespace }
        expect(vault_step[:status]).to eq('skipped')
        expect(vault_client).not_to have_received(:create_namespace)
      end
    end
  end
end
