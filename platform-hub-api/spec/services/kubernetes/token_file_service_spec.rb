require 'rails_helper'

describe Kubernetes::TokenFileService, type: :service do

  let(:service) { create :service }

  before do
    @cluster = create :kubernetes_cluster, allocate_to: service
  end

  describe '.generate' do
    let(:user_group_1) { create :kubernetes_group, :not_privileged, :for_user }
    let(:user_group_2) { create :kubernetes_group, :not_privileged, :for_user }
    let(:robot_group_1) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: service }

    before do
      @u1 = create :user_kubernetes_token, cluster: @cluster, groups: "#{user_group_1.name},#{user_group_2.name}"
      @u2 = create :user_kubernetes_token, cluster: @cluster, groups: []
      @r1 = create :robot_kubernetes_token, tokenable: service, cluster: @cluster, groups: [ robot_group_1.name ]
    end

    it 'generates csv tokens file for given cluster name' do
      tokens_csv = subject.generate(@cluster.name)

      parsed = CSV.parse(tokens_csv)
      expect(parsed.size).to eq 3

      parsed.each do |i|
        if i.first == @u1.decrypted_token
          expect(i.first).to eq @u1.decrypted_token
          expect(i.second).to eq @u1.name
          expect(i.third).to eq @u1.uid
          expect(i.fourth).to eq "#{user_group_1.name},#{user_group_2.name}"

        elsif i.first == @u2.decrypted_token
          expect(i.first).to eq @u2.decrypted_token
          expect(i.second).to eq @u2.name
          expect(i.third).to eq @u2.uid
          expect(i.fourth).to eq nil

        elsif i.first == @r1.decrypted_token
          expect(i.first).to eq @r1.decrypted_token
          expect(i.second).to eq @r1.name
          expect(i.third).to eq @r1.uid
          expect(i.fourth).to eq robot_group_1.name
        end
      end
    end
  end

end
