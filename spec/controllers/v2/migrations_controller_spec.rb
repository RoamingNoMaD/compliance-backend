# frozen_string_literal: true

require 'rails_helper'

describe V2::MigrationsController do
  let(:attributes) do
    {
      policy_id: :policy_id,
      tailoring_id: :tailoring_id,
      target_os_minor: :target_os_minor,
      diff_only: :diff_only
    }
  end

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:rbac_allowed?) { true }

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  context '/policies/:id/tailorings/:id/migrations' do
    describe 'GET index' do
      let(:canonical_profile) do
        FactoryBot.create(
          :v2_profile,
          security_guide: FactoryBot.create(:v2_security_guide, rule_count: 5, os_major_version: 9),
          ref_id_suffix: 'foo',
          supports_minors: [6, 7, 8],
          rule_count: 5
        )
      end
      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account, profile: canonical_profile) }
      let!(:source_tailoring) do
        FactoryBot.create(
          :v2_tailoring,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 7
        )
      end
      let(:extra_params) do
        {
          policy_id: parent.id,
          tailoring_id: source_tailoring.id,
          parents: [:policy, :tailoring],
          target_os_minor: 8
        }
      end

      context 'comparing tailorings with canonical rulesets' do
        it 'returns comparison' do
          get :index, params: extra_params

          expect(response).to have_http_status :ok

          comparison_result = response.parsed_body
          expect(comparison_result).to be_an(Array)
          expect(comparison_result).not_to be_empty

          comparison_result.each do |rule|
            expect(rule).to have_key('available_in_versions')
            expect(rule['available_in_versions']).to be_an(Array)
            expect(rule['available_in_versions'].length).to eq(2)

            versions = rule['available_in_versions']
            expect(versions.map { |v| v['os_minor_version'] }).to contain_exactly(7, 8)
            expect(versions.all? { |v| v.key?('os_major_version') }).to be(true)
            expect(versions.all? { |v| v.key?('ssg_version') }).to be(true)
          end
        end
      end

      context 'comparing tailorings with mixed and canonical rules' do
        it 'returns comparison' do
          source_tailoring_mixed = FactoryBot.create(
            :v2_tailoring,
            :with_mixed_rules,
            policy: parent,
            profile: canonical_profile,
            os_minor_version: 6
          )

          mixed_params = extra_params.merge(id: source_tailoring_mixed.id)
          get :index, params: mixed_params

          expect(response).to have_http_status :ok

          comparison_result = response.parsed_body
          expect(comparison_result).to be_an(Array)
          expect(comparison_result).not_to be_empty

          single_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 1 }
          dual_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 2 }

          expect(single_version_rules).not_to be_empty
          expect(dual_version_rules).not_to be_empty

          single_version_rules.each do |rule|
            version = rule['available_in_versions'].first
            expect([6, 8]).to include(version['os_minor_version'])
            expect(version).to have_key('os_major_version')
            expect(version).to have_key('ssg_version')
          end

          dual_version_rules.each do |rule|
            versions = rule['available_in_versions']
            expect(versions.map { |v| v['os_minor_version'] }).to contain_exactly(6, 8)
          end
        end

        it 'returns only the difference between the two tailorings' do
          get :index, params: extra_params.merge(diff_only: true)

          comparison_result = response.parsed_body
          expect(comparison_result).to be_an(Array)
          expect(comparison_result).not_to be_empty

          single_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 1 }
          dual_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 2 }

          expect(single_version_rules).not_to be_empty
          expect(dual_version_rules).to be_empty
        end

        it 'includes all required rule attributes in the response' do
          get :index, params: extra_params

          comparison_result = response.parsed_body
          comparison_result.map do |rule|
            expect(rule).to have_key('id')
            expect(rule).to have_key('ref_id')
            expect(rule).to have_key('title')
            expect(rule).to have_key('available_in_versions')
          end
        end
      end

      context 'invalid target os minor version' do
        it 'returns not found when the os minor version is not supported' do
          get :index, params: extra_params.merge(target_os_minor_version: 9)

          expect(response).to have_http_status :not_found
          expect(response.parsed_body).to have_key('errors')
          expect(response.parsed_body['errors']).to include(
            "Profile does not support OS version #{canonical_profile.security_guide.os_major_version}.9"
          )
        end

        it 'returns unprocessable entity when the target version is lower than the source version' do
          get :compare, params: extra_params.merge(target_os_minor_version: 5)

          expect(response).to have_http_status :unprocessable_entity
          expect(response.parsed_body).to have_key('errors')
          expect(response.parsed_body['errors']).to include(
            'Target version 5 is lower than source version 7'
          )
        end
      end
    end
  end
end
