class PasswordComplexityValidator < ActiveModel::EachValidator
  MIN_LENGTH = 12

  def validate_each(record, attribute, value)
    return if value.blank?

    record.errors.add(attribute, :too_short, count: MIN_LENGTH) if value.length < MIN_LENGTH
    record.errors.add(attribute, "must include an uppercase letter") unless value.match?(/[A-Z]/)
    record.errors.add(attribute, "must include a lowercase letter") unless value.match?(/[a-z]/)
    record.errors.add(attribute, "must include a number") unless value.match?(/\d/)
    record.errors.add(attribute, "must include a symbol") unless value.match?(/[^A-Za-z0-9]/)
  end
end
