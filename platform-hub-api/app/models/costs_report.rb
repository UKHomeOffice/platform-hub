class CostsReport < ApplicationRecord

  ID_REGEX = /\A[0-9]{4}-[0-9]{2}\z/
  ID_REGEX_FOR_ROUTES = /[0-9]{4}-[0-9]{2}/

  include Audited

  audited descriptor_field: :id

  before_validation :set_id

  scope :by_year_and_month, -> (year, month) { where(year: year, month: month) }

  validates :id,
    format: {
      with: ID_REGEX,
      message: "should be of the form '{year}-{month}', e.g. '2017-01'"
    }

  validates :year,
    presence: true,
    length: { is: 4 }

  validates :month,
    presence: true,
    inclusion: {
      in: Date::ABBR_MONTHNAMES,
      message: 'is not a valid abbreviated month name'
    }

  def self.exists_for? year, month
    id = CostsReport.generate_id_for year, month
    CostsReport.exists? id
  end

  def self.generate_id_for year, month_abbr
    return unless is_valid_month_abbr?(month_abbr)

    month = format('%02d', Date::ABBR_MONTHNAMES.index(month_abbr))
    "#{year}-#{month}"
  end

  def self.is_valid_month_abbr? month_abbr
    Date::ABBR_MONTHNAMES.include? month_abbr
  end

  private

  def set_id
    return if self.year.blank? || self.month.blank?

    self.id = CostsReport.generate_id_for self.year, self.month
  end

end
