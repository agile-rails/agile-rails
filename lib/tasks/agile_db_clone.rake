# Thanks to Jimmy https://github.com/kejiro
#
# https://gist.githubusercontent.com/kejiro/484416/raw/56b8f3db8a62aac0fb0d007b1afd7e7b56b3ff07/Rakefile
#
#require 'activerecord'
#require 'yaml'

module DataCopier
  @source = nil
  @destination = nil


  module Source
    class Base < ActiveRecord::Base
      self.abstract_class = true
    end
  end

  module Destination
    class Base < ActiveRecord::Base
      self.abstract_class = true
    end
  end

  class Base
    @source = nil
    @destination = nil

    def write(text="")
      puts(text)# if verbose
    end

    def announce(message)
      text = "#{message}"
      length = [0, 75 - text.length].max
      write "== %s %s" % [text, "=" * length]
    end

    def say(message, subitem=false)
      write "#{subitem ? "   ->" : "--"} #{message}"
    end

    def say_with_time(message)
      say(message)
      result = nil
      time = Benchmark.measure { result = yield }
      say "%.4fs" % time.real, :subitem
      say("#{result} rows", :subitem) if result.is_a?(Integer)
      result
    end

    def initialize(configuration)
      ActiveRecord::Base.configurations = configuration

      @source = Source::Base.establish_connection(:source).connection
      @destination = Destination::Base.establish_connection(:destination).connection

    end


    def create_destination_tables(source = @source, destination = @destination)
      return unless destination.tables.empty?

      schema_definitions = StringIO.new
      ActiveRecord::Base.establish_connection(:destination)

      say_with_time("Dumping the schema from the source"){ActiveRecord::SchemaDumper.dump(source, schema_definitions)}
      say_with_time("Loading the schema in the destination"){eval(schema_definitions.string)}
    end

    def create_models(tables = @source.tables)
      tables.each do |table|
        class_name = table.downcase.classify
        Source.module_eval <<-DECL
          class #{class_name} < Source::Base
            #set_table_name "#{table}"
            self.table_name = "#{table}"
          end        
        DECL

        Destination.module_eval <<-DECL
          class #{class_name} < Destination::Base
            #set_table_name "#{table}"
            self.table_name = "#{table}"
          end
        DECL
      end
    end

    def copy_data(tables = @source.tables)
      skip = %w[schema_migrations ar_journals]
      tables.each do |table|
        next if skip.include?(table)

        source_model = "DataCopier::Source::#{table.downcase.classify}".constantize
        destination_model = "DataCopier::Destination::#{table.downcase.classify}".constantize
        destination_model.delete_all
        rows_to_copy = source_model.count
        rows_copied = 0
        say_with_time("Copying #{rows_to_copy} rows from #{table.downcase}"){
          source_model.all.each do |row|
            destination_model.create(row.attributes)
            rows_copied += 1
          end
          rows_copied
        }
      end
    end


    def run
      create_destination_tables(@source, @destination)
      create_models(@source.tables)
      copy_data(@source.tables)
    end
  end
end

#########################################################################
namespace :agile do
  namespace :db do
    task :setup do
      configuration_file = ENV['config'] || 'config/database.yml'
      raise "Can't find the configuration file, please specify with: env config=<path to file>" unless File.exist?(configuration_file)
      @configuration = YAML.load_file(configuration_file, aliases: true)
    end

    task :clone => :setup do
      DataCopier::Base.new(@configuration).run
    end
  end
end
