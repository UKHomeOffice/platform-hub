FactoryGirl.define do
  factory :costs_report do
    sequence(:year) { |n| 2000 + n }
    month 'Dec'
    billing_file 'billing.csv'
    metrics_file 'metrics.csv'
    config { {} }
    results { {} }
    published_at nil
  end
end
