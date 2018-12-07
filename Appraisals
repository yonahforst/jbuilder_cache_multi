rails_versions = ["~> 4.0.0", "~> 4.1.0", "~> 4.2.0", "~> 5.0"]
jbuilder_versions = ["~> 2.0"]

rails_versions.each do |r|
  jbuilder_versions.each do |j|
    appraise "rails_#{r.match(/\d.*/)} jbuilder_#{j.match(/\d.*/)}" do
      gem "railties", r
      gem "actionpack", r
      gem "jbuilder", j
    end
  end
end