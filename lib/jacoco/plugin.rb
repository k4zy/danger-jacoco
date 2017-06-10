module Danger
  # Measuring and reporting Java code coverage.
  # This is done using [jacoco](http://jacoco.org/jacoco/)
  # Results are passed out as tables in markdown.
  #
  # @example Running jacoco with its basic configuration
  #
  #          jacoco.report
  #
  # @example Running jacoco with a specific gradle task or report_file
  #
  #          jacoco.gradle_task = "app:jacoco" #defalut: jacoco
  #          jacoco.report_file = "app/build/reports/jacoco/jacoco/jacoco.xml"
  #          jacoco.coverage_types = %w(INSTRUCTION BRANCH LINE)
  #          jacoco.report
  #
  # @see  kazy1991/danger-jacoco
  # @tags danger, jacoco, android, java
  #
  class DangerJacoco < Plugin

    # Custom gradle module to run.
    # This is useful when your project has different flavors.
    # Defaults to `app`.
    # @return [String]
    attr_writer :gradle_module
    # Custom gradle task to run.
    # This is useful when your project has different flavors.
    # Defaults to `jacoco`.
    # @return [String]
    attr_writer :gradle_task
    # Location of report file
    # If your jacoco task outputs to a different location, you can specify it here.
    # Defaults to `build/reports/jacoco_report.xml`.
    # @return [String]
    attr_writer :report_file

    # Filtering coverage_types
    # Defaults to `["INSTRUCTION", "BRANCH"]`.
    attr_writer :coverage_types

    # Calls jacoco task of your gradle project.
    # It fails if `gradlew` cannot be found inside current directory.
    # It fails if `report_file` cannot be found inside current directory.
    # @return [void]
    #
    def report(inline_mode = false)
      return fail(GRADLEW_NOT_FOUND) unless gradlew_exists?
      exec_gradle_task
      return fail(REPORT_FILE_NOT_FOUND) unless report_file_exist?

      if inline_mode
        # TODO not implemented
      else
        message = "### Jacoco report\n\n"
        message << table_header
        file_reports
        .select do |it|
          target_files.include?(it.file_name)
        end
        .each do |it|
          message << table_content(it)
        end
        markdown(message)
      end
    end

    # A getter for `gradle_module`, returning "app" if value is nil.
    # @return [String]
    def gradle_module
      @gradle_module ||= 'app'
    end

    # A getter for `gradle_task`, returning "jacoco" if value is nil.
    # @return [String]
    def gradle_task
      @gradle_task  ||= 'jacoco'
    end

    # A getter for `report_file`, returning "build/reports/jacoco_report.xml" if value is nil.
    # @return [String]
    def report_file
      @report_file ||= 'build/reports/jacoco/jacoco/jacoco.xml'
    end

    # A getter for `report_file`, returning ["INSTRUCTION", "BRANCH"] if value is nil.
    # @return [Array[String]]
    def coverage_types
      @coverage_types ||= ["INSTRUCTION", "BRANCH"]
    end

    private
    # A getter for current updated files
    # @return [Array[String]]
    def target_files
      @target_files ||= (git.modified_files - git.deleted_files) + git.added_files
    end

    def table_header
      header = ""
      colums = ["FILE"] + coverage_types
      header << "|" + colums.map { |it| " #{it} " }.join("|") + "|"
      header << "\n"
      header << "|" + colums.map { |it| " :------- " }.join("|") + "|"
      header << "\n"
    end

    def table_content(file_report)
      short_name = file_report.file_name.sub("#{path_prefix}/","")
      values = ["`#{short_name}`"]
      filterd_coverages = file_report.coverages
      .select do |it|
        coverage_types.include?(it.type)
      end
      .each do |it|
        values << "#{it.coverage.round(2)}%"
      end
      content = ""
      content << "|" + values.map { |it| " #{it} "}.join("|") + "|"
      content << "\n"
    end

    # Run gradle task
    # @return [void]
    def exec_gradle_task
      system "./gradlew #{gradle_task}"
    end

    # Check gradlew file exists in current directory
    # @return [Bool]
    def gradlew_exists?
      `ls gradlew`.strip.empty? == false
    end

    # Check report_file exists in current directory
    # @return [Bool]
    def report_file_exist?
      File.exists?(report_file)
    end

    FileReport = Struct.new(:file_name, :coverages)
    Coverage = Struct.new(:type, :found, :covered, :missed, :coverage)

    def counter_to_report(counter)
      type = counter.attribute("type").to_s
      missed = counter.get("missed").to_i
      covered = counter.get("covered").to_i
      found = missed + covered
      coverage = 100.0 * covered / found
      Coverage.new(type, found, covered, missed, coverage)
    end

    def root_node
      require "oga"
      Oga.parse_xml(File.open(report_file))
    end

    def packages
      root_node.xpath("//package")
    end

    def path_prefix
      @path_prefix ||= "#{gradle_module}/src/main/java"
    end

    def counters_node(node)
      counters = node.xpath("//counter")
      counters = node.xpath("//line/counter") if counters.empty?
      counters.to_a
    end

    def inner_node(sourcefile)
      require "oga"
      Oga.parse_xml(sourcefile.to_xml)
    end

    def file_reports
      packages.map do |package|
        package_name = package.attribute("name")
        package.xpath("//sourcefile").map do  |sourcefile|
          file_name = sourcefile.attribute("name").to_s
          file_report = FileReport.new("#{path_prefix}/#{package_name}/#{file_name}", [])
          counters_node(inner_node(sourcefile)).map do |it|
            file_report.coverages << counter_to_report(it)
          end
          file_report
        end
      end.flatten
    end

  end
end
