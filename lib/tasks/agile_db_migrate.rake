require 'fileutils'

#########################################################################
# Assemble migration files from gems that have registered form path with Agile.add_forms_path.
#########################################################################
def assemble_migration_files
  destination_dir = Rails.root.join('db/agile_migrate').to_s
  FileUtils.mkdir(destination_dir) unless File.exist?(destination_dir)

  Agile.paths(:forms).map do |path|
    paths = path.to_s.split('/')[0..-3] # remove app/forms
    paths.pop if paths[-1, 1] == 'app'  # there might have been subdir of forms
    migrations_dir = paths.join('/') + '/db/migrate'
    next unless File.exist?(migrations_dir)

    Dir["#{migrations_dir}/*.rb"].each do |file_name|
      destination_file_name = "#{destination_dir}/#{File.basename(file_name)}"
      next if File.exist?(destination_file_name) && File.mtime(destination_file_name) == File.mtime(file_name)

      p "copy migration #{file_name}"
      FileUtils.cp(file_name, destination_file_name, preserve: true)
    end
  end
end

#########################################################################
namespace :agile do
  namespace :db do
    desc "agile:db:migrate, Agile Rails migration assembles migration files from all registered gems and performs migration from assembled collection."
    task :migrate => :environment do
      assemble_migration_files
      Rake::Task["db:migrate"].invoke
    end
  end
end