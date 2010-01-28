class AttachmentOptions
  def initialize(defaults = {})
    @scoped_attachment_options = {}
    @global_attachment_options = {
      :storage => :s3,
      :max_size => 2.megabytes,
      :size => 1..2.megabytes
    }
    @default_attachment_options = defaults
  end
  def [](option)
    config_file = File.join(Site.current_config_path, 'attachment_fu.yml')
    @scoped_attachment_options[Site.current.id] ||= (File.exists?(config_file) ? YAML.load_file(config_file).symbolize_keys : {})
    @global_attachment_options[option] || @scoped_attachment_options[Site.current.id][option] || @default_attachment_options[option]
  end
  def []=(option, value)
    @scoped_attachment_options[Site.current.id] ||= {}
    @scoped_attachment_options[Site.current.id][option] = value
  end
end
