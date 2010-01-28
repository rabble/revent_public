class Cartographer::Header
  def self.load_configuration(config_path)
    @@keys = YAML.load_file(config_path)
    @@key = @@keys.values.first
  end
  def has_key?(uri)
    true
  end
  def value_for(uri)
    @@key
  end
end
