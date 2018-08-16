Rails.application.eager_load!

module Ktc
  def self.concurrent_serialization
    tokens = {}
    admin = User.find_by name: 'Jiten Bhagat'
    t1 = Thread.new do
      token1 = KubernetesToken.robot.where(tokenable_id: "738fffea-5fc2-4f3c-80e5-6f4379e9afa8").first
      tokens[:first] = KubernetesTokenSerializer.new(token1, scope: Hashie::Mash.new(id: admin.id)).to_json
    end
    t2 = Thread.new do
      token2 = KubernetesToken.robot.where(tokenable_id: "0261e6c3-e57b-4faa-a828-9873b2fad449").first
      tokens[:second] = KubernetesTokenSerializer.new(token2, scope: Hashie::Mash.new(id: admin.id)).to_json
    end
    t1.join
    t2.join
    pp JSON.parse(tokens[:first])['service']
    pp JSON.parse(tokens[:second])['service']
    nil
  end
end
