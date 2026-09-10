class FutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    record.errors.add(attribute, "must be in the future") if value <= Time.current
  end
end
