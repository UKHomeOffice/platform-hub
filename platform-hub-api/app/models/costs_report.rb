class CostsReport < ApplicationRecord

  ID_REGEX = /\A[0-9]{4}-[0-9]{2}\z/
  ID_REGEX_FOR_ROUTES = /[0-9]{4}-[0-9]{2}/

  include Audited

  audited descriptor_field: :id

  before_validation :set_id

  scope :by_year_and_month, -> (year, month) { where(year: year, month: month) }
  scope :published, -> { where.not(published_at: nil) }

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

  def self.exists_for? year, month, filter_scope = nil
    id = CostsReport.generate_id_for year, month
    if filter_scope.present?
      CostsReport.send(filter_scope.to_sym)
    else
      CostsReport
    end.exists?(id)
  end

  def self.already_published? year, month
    self.exists_for?(year, month, 'published')
  end

  def self.generate_id_for year, month_abbr
    return unless is_valid_month_abbr?(month_abbr)

    month = format('%02d', Date::ABBR_MONTHNAMES.index(month_abbr))
    "#{year}-#{month}"
  end

  def self.is_valid_month_abbr? month_abbr
    Date::ABBR_MONTHNAMES.include? month_abbr
  end

  def publish!
    self.published_at = DateTime.now.utc
    self.save!
  end

  def published?
    self.published_at.present?
  end

  protected

  def readonly?
    if persisted?
      if published? && self.published_at_was != nil  # Because we may be trying to publish!
        raise ActiveRecord::ReadOnlyRecord, 'has already been published'
      end
    end
  end

  private

  def set_id
    return if self.year.blank? || self.month.blank?

    self.id = CostsReport.generate_id_for self.year, self.month
  end

end
