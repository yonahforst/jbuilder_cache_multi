rails_versions = ["~> 3.0.0", "~> 3.1.0", "~> 3.2.0", "~> 4.0.0", "~> 4.1.0", "~> 5.0.0"]
jbuilder_versions = ["~> 1.5.0", "~> 2.0.0"]

rails_versions.each_with_index do |r,ri|
  jbuilder_versions.each do |j|
    appraise "rails_#{r.match(/\d.*/)} jbuilder_#{j.match(/\d.*/)}" do
      gem "railties",   r
      gem "actionpack", r
      gem "jbuilder", j
      gem "activerecord", r
      gem "sqlite3", '~> 1.3.11'
    end
  end
end
