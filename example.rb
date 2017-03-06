def process(args)
  args.each do |a|
    puts "Argument: #{a}"
  end
  puts "-----"
end

Dir.glob('*').each do |folder_name|
  Dir.chdir(folder_name) do
    Dir.glob("*.csv") do |file|
      if process(File.expand_path(file))
        FileUtils.move(file, "../../Processed/#{folder_name}/")
      else
        # system('ruby', @config.failure_path, File.expand_path(file), @config.server, @config.language)
        break
      end
    end
  end
end
