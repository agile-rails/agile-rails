#Rails.initialize!

#########################################################################
#
#########################################################################
def agile_db_export_to_yaml
  h = {}
  all_models = (ActiveRecord::Base.connection.tables - %w[schema_migrations sessions])
  all_models.each do |model_name|
    p model_name

    model = model_name.classify.constantize rescue nil
    next if model.nil?
    next unless model.all.count > 0

    p model.column_names
    a = []
    model.all.each do |record|
      a << model.column_names.each_with_object({}) do |column, r|
        r[column] = record[column] if record[column].present?
      end
    end
    h[model_name] = a
  end
  File.write('out.txt', h.to_yaml)
end

#########################################################################
namespace :agile do
  namespace :db do
    desc "agile:db:export, export database to text file in yaml format"
    task :export => :environment do
      agile_db_export_to_yaml
    end
  end

end