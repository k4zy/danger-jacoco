

### danger-jacoco

Measuring and reporting Java code coverage.
This is done using [jacoco](http://jacoco.org/jacoco/)
Results are passed out as tables in markdown.

<blockquote>Running jacoco with its basic configuration
  <pre>
jacoco.report</pre>
</blockquote>

<blockquote>Running jacoco with a specific gradle task or report_file
  <pre>
jacoco.gradle_task = "app:jacoco" #defalut: jacoco
jacoco.report_file = "app/build/reports/jacoco/jacoco/jacoco.xml"
jacoco.coverage_types = %w(INSTRUCTION BRANCH LINE)
jacoco.report</pre>
</blockquote>



#### Attributes

`gradle_module` - Custom gradle module to run.
This is useful when your project has different flavors.
Defaults to `app`.

`gradle_task` - Custom gradle task to run.
This is useful when your project has different flavors.
Defaults to `jacoco`.

`report_file` - Location of report file
If your jacoco task outputs to a different location, you can specify it here.
Defaults to `build/reports/jacoco_report.xml`.

`coverage_types` - Filtering coverage_types
Defaults to `["INSTRUCTION", "BRANCH"]`.




#### Methods

`report` - Calls jacoco task of your gradle project.
It fails if `gradlew` cannot be found inside current directory.
It fails if `report_file` cannot be found inside current directory.




