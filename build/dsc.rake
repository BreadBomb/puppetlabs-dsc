namespace :dsc do

  # local pathes
  dsc_build_path             = Pathname.new(__FILE__).dirname
  dsc_repo_url               = %x(git config --get remote.origin.url).strip
  dsc_repo_branch            = %x(git rev-parse --abbrev-ref HEAD).strip
  # defaults
  default_dsc_module_path    = dsc_build_path.parent
  default_dsc_resources_path = "#{default_dsc_module_path}/#{Dsc::Config['import_folder']}/#{Dsc::Config['dsc_modules_folder']}"

  default_repofile           = "#{default_dsc_module_path}/Repofile"
  default_types_path         = "#{default_dsc_module_path}/lib/puppet/type"
  default_type_specs_path    = "#{default_dsc_module_path}/spec/unit/puppet/type"

  desc "Import and build all"
  task :build, [:dsc_module_path] do |t, args|
    dsc_module_path = args[:dsc_module_path] || default_dsc_module_path

    if args[:dsc_module_path]
      Rake::Task['dsc:module:skeleton'].invoke(dsc_module_path)
    end

    Rake::Task['dsc:dmtf:import'].invoke

    repofile = "#{dsc_module_path}/Repofile"
    raise "#{repofile} does not exist. Exiting" unless File.exists?(repofile)
    Rake::Task['dsc:resources:import'].invoke(repofile)

    Rake::Task['dsc:types:build'].invoke(dsc_module_path)
  end

  desc "Cleanup all"
  task :clean, [:dsc_module_path] do |t, args|
    dsc_module_path = args[:dsc_module_path] || default_dsc_module_path

    Rake::Task['dsc:types:clean'].invoke(dsc_module_path)

    Rake::Task['dsc:resources:clean'].invoke(default_dsc_resources_path)

    Rake::Task['dsc:dmtf:clean'].invoke
  end

  namespace :dmtf do

    item_name = 'DMTF CIM MOF Schema files'

    desc "Import #{item_name}"
    task :import do
      sh "librarian-repo install --verbose --path #{Dsc::Config['import_folder']} --Repofile 'build/dmtf.repo'"
    end

    desc "Cleanup #{item_name}"
    task :clean do
      sh "librarian-repo clean --verbose --path #{Dsc::Config['import_folder']}/#{Dsc::Config['dmtf_mof_folder']}"
    end

  end

  namespace :resources do

    item_name = 'DSC Powershell modules files'
    desc <<-eod
    Import #{item_name}

Default values:
  dsc_resources_path: #{default_dsc_resources_path}
  repofile:           #{default_repofile}
eod

    task :import, [:repo_file, :dsc_resources_path] do |t, args|
      repo_file          = args[:repo_file] || default_repofile
      dsc_resources_path = args[:dsc_resources_path] || default_dsc_resources_path

      puts "Downloading and Importing #{item_name}"
      sh "librarian-repo install --verbose --path #{dsc_resources_path} --Repofile #{repo_file}"
    end

    desc <<-eod
    Cleanup #{item_name}

Default values:
  dsc_resources_path: #{default_dsc_resources_path}"
eod

    task :clean, [:dsc_resources_path] do |t, args|
      dsc_resources_path = args[:dsc_resources_path] || default_dsc_resources_path
      puts "Cleaning #{item_name}"
      sh "librarian-repo clean --verbose --path #{dsc_resources_path}"
    end

  end

  namespace :types do

    item_name = 'DSC types and type specs'

    desc "Build #{item_name}"
    task :build, [:module_path] do |t, args|
      module_path = args[:module_path] || default_module_path
      m = Dsc::Manager.new
      m.target_module_path = module_path
      msgs = m.build_dsc_types
      msgs.each{|m| puts "#{m}"}
    end

    desc "Cleanup #{item_name}"
    task :clean, [:module_path] do |t, args|
      module_path = args[:module_path] || default_module_path
      puts "Cleaning #{item_name}"
      m = Dsc::Manager.new
      m.target_module_path = module_path
      msgs = m.clean_dsc_types
      msgs.each{|m| puts "#{m}"}
      msgs = m.clean_dsc_type_specs
      msgs.each{|m| puts "#{m}"}
    end

  end

  namespace :module do

    item_name = 'External DSC module'

    desc "Generate skeleton for #{item_name}"
    task :skeleton, [:dsc_module_path] do |t, args|
      dsc_module_path = args[:dsc_module_path] || default_module_path
      ext_module_files = [
        '.gitignore',
        '.pmtignore',
        'Gemfile',
        'LICENSE',
        'README.md',
        'Rakefile',
        'Repofile',
        'spec/*.rb'
      ]
      ext_module_files.each do |module_pathes|
        Dir[module_pathes].each do |path|
          if File.directory?(path)
            unless File.exists?("#{dsc_module_path}/#{path}")
              puts "Creating directory #{path}"
              FileUtils.mkdir_p("#{dsc_module_path}/#{path}")
            end
          else
            directory = Pathname.new(path).dirname
            unless File.exists?("#{dsc_module_path}/#{directory}")
              puts "Creating directory #{dsc_module_path}/#{directory}"
              FileUtils.mkdir_p("#{dsc_module_path}/#{directory}")
            end
            unless File.exists?("#{dsc_module_path}/#{path}")
              puts "Copying file #{path} to #{dsc_module_path}/#{path}"
              FileUtils.cp(path, "#{dsc_module_path}/#{path}")
            end
          end
        end
      end

      unless File.exists?("#{dsc_module_path}/Puppetfile")
        puts "Creating #{dsc_module_path}/Puppetfile"

        # Generate Puppetfile with dependency on this dsc module
        Puppetfile_content = <<-eos
forge "https://forgeapi.puppetlabs.com"
mod '#{dsc_build_path.parent.basename}', :git => '#{dsc_repo_url}', :ref => '#{dsc_repo_branch}'
eos

        File.open("#{dsc_module_path}/Puppetfile", 'w') do |file|
          file.write Puppetfile_content
        end

      end

    end

  end

end
