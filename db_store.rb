require 'pg'
require 'csv'
require 'fileutils'

language = ARGV[0]
db_connection = PG.connect(dbname: "edn_summaries", user: 'vagrant', password: 'vagrant')

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

def add_columns_to_table(columns, table_name, connection)
  columns.each do |new_column|
    begin
      connection.exec("ALTER TABLE #{table_name} ADD #{new_column} text")
    rescue PG::DuplicateColumn
      next
    end
  end
end

Dir.glob('*').each do |folder_name|
  table_name = folder_name.underscore
  db_connection.exec("CREATE TABLE IF NOT EXISTS #{table_name} (id int4 PRIMARY KEY)")
  Dir.chdir(folder_name) do
    next if (files = Dir.glob("*.csv").sort_by{|file_name| file_name}).empty?
    column_names = CSV.read(files.last).first
    add_columns_to_table(column_names,table_name,db_connection)

    files.each do |file|
      csv = CSV.new(File.read(file), :headers => true, :header_converters => :symbol, :converters => :all)

      csv.each do |row|
        columns = row.to_h.keys.join(",")
        values = row.to_h.values.map{|v| v.to_s.gsub("'","\"")}.join("\',\' ")

        first_attempt = true
        begin
          db_connection.exec("INSERT INTO #{table_name} (#{columns}) VALUES (\'#{values}\') ON CONFLICT (id) DO UPDATE SET id = EXCLUDED.id;")
        rescue PG::UndefinedColumn
          add_columns_to_table(row.to_h.keys,table_name,db_connection)
          first_attempt ? (first_attempt= false ; retry) : (puts "Unable to create columns in #{table_name} - Aborting..."; exit)
        end

      end
      File.open("../../dapr.log.txt", 'a'){|f| f.write "#{DateTime.now} - Processed #{file}\n".gsub("(?:[^-]*-){3}|-#{language}\.csv",'')}
      FileUtils.move(file, "../../Processed/#{folder_name}/")

    end

  end
end

db_connection.close