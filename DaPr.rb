Dir.chdir(__dir__) do
  require './config/config'

  def recreate_folders
    Dir.mkdir("csv") unless Dir.exist?("./csv")
    Dir.chdir("csv") do
      Dir.mkdir("#{@config.user_name}") unless Dir.exist?("./#{@config.user_name}")
      Dir.chdir("#{@config.user_name}") do
        Dir.mkdir("#{@config.language}") unless Dir.exist?("./#{@config.language}")
        Dir.chdir("#{@config.language}") do
          Dir.mkdir("Incoming") unless Dir.exist?("./Incoming")
          Dir.mkdir("Processed") unless Dir.exist?("./Processed")
          File.new("./dapr.log.txt", 'w') unless File.file?("./dapr.log.txt")
        end
      end
    end
  end

  bucket_name = "private-#{@config.server.gsub('.','-')}-#{@config.user_name}"
  key_prefix = "csv-export/v1/#{@config.language}"

  recreate_folders

  s3_resource = Aws::S3::Resource.new
  s3_client = Aws::S3::Client.new

  remote_collection = s3_resource.bucket(bucket_name).objects(prefix: key_prefix, delimiter: "delimiter").collect(&:key)

  Dir.chdir("csv/#{@config.user_name}/#{@config.language}") do
    pending_files = {}
    remote_collection.each do |remote_file_path|
      folder_structure = remote_file_path.gsub(key_prefix,'').split('/').reject(&:empty?)
      local_folder = folder_structure[0]; local_file = folder_structure[1]
      (pending_files[local_folder] ||= []).push(local_file) unless local_file.nil? || File.file?("./Incoming/#{local_folder}/#{local_file}") || File.file?("./Processed/#{local_folder}/#{local_file}")
    end

    pending_files.keys.each do |folder_name|
      ["Incoming", "Processed"].each do |target|
        Dir.chdir(target) do
          Dir.mkdir("#{folder_name}") unless Dir.exist?("./#{folder_name}")
        end
      end
    end

    Dir.chdir ("Incoming") do
      pending_files.each do |folder_name, incoming_files|
        Dir.chdir ("#{folder_name}") do
          incoming_files.each do |file|
            (File.open("../../dapr.log.txt", 'a'){|f| f.write "#{DateTime.now} - Download #{file}\n".gsub("(?:[^-]*-){3}|-#{@config.language}\.csv",'')}) if resp = s3_client.get_object(
              response_target: file,
              bucket: bucket_name,
              key: "#{key_prefix}/#{folder_name}/#{file}")
          end
        end
      end

      system('ruby', @config.processor, @config.language)

    end

  end
end