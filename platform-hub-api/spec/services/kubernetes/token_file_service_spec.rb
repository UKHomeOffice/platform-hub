require 'rails_helper'

describe Kubernetes::TokenFileService, type: :service do

  before do
    @cluster = create :kubernetes_cluster
  end

  describe '.generate' do
    before do
      @u1 = create :user_kubernetes_token, cluster: @cluster, groups: "g1,g2"
      @u2 = create :user_kubernetes_token, cluster: @cluster, groups: []
      @r1 = create :robot_kubernetes_token, cluster: @cluster, groups: "g3"
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
          expect(i.fourth).to eq @u1.groups.join(',')

        elsif i.first == @u2.decrypted_token
          expect(i.first).to eq @u2.decrypted_token
          expect(i.second).to eq @u2.name
          expect(i.third).to eq @u2.uid
          expect(i.fourth).to eq nil

        elsif i.first == @r1.decrypted_token
          expect(i.first).to eq @r1.decrypted_token
          expect(i.second).to eq @r1.name
          expect(i.third).to eq @r1.uid
          expect(i.fourth).to eq @r1.groups.join(',')
        end
      end
    end
  end

end

