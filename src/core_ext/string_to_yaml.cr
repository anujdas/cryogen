require "yaml"

class String
  # Override default ScalarStyle for String serialisation from `ANY` to
  # `LITERAL` to preserve original string formatting for multiline strings.
  # This ensures that round-tripping multiline strings through `YAML.parse` and
  # `YAML.dump` does not clobber styles from
  #   key: |-
  #     secret
  #     value
  # to
  #   key: 'secret
  #
  #     value'
  # which is ugly and unreadable, even if it is exactly identical in usage.
  def to_yaml(yaml : YAML::Nodes::Builder)
    if YAML::Schema::Core.reserved_string?(self)
      yaml.scalar self, style: YAML::ScalarStyle::DOUBLE_QUOTED
    elsif lines.size > 1 # don't screw around with multiline strings
      yaml.scalar self, style: YAML::ScalarStyle::LITERAL
    else
      previous_def
    end
  end
end
