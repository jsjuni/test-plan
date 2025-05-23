# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

require 'project_xml'

class GenerateGanttProject < Logger::Application
  def initialize
    super('generate-gantt-project')

    logger.level = Logger::DEBUG
  end

  def run

    @options = {}
    OptParse.new do |parser|
      parser.on('-t', '--template TEMPLATE', 'template file')
    end.parse!(into: @options)

    template = File.read(@options[:template])
    project = ProjectXML::Project.new(template)

    tests = JSON.parse(ARGF.read)['tests']

    max_duration = tests.inject(0) do |m, t|
      d = (t['apply'] + t['retract']).inject(0) { |s, r| s + r }
      m > d ? m : d
    end.to_f
    log(Logger::DEBUG, "max duration: #{max_duration}")

    parent_task = ProjectXML::Task.new(10000, 'Test Campaign', 0)

    prev_task = nil
    tests.each do |t|
      test_id = t['id']
      task_id = test_id * 10
      parent_task << task = ProjectXML::Task.new(task_id, "Test #{test_id}", 0)
      config_duration = (t['apply'] + t['retract']).inject(0) { |s, r| s + r } / max_duration * 5
      log(Logger::DEBUG, "test #{test_id} config duration: #{config_duration}")
      task << config_task = ProjectXML::Task.new(task_id + 1, "Test #{test_id} Configuration", config_duration)
      exec_duration = 1
      task << execut_task = ProjectXML::Task.new(task_id + 2, "Test #{test_id} Execution", exec_duration)
      config_task.add_successor(execut_task.attributes['id'])
      prev_task.add_successor(task_id) if prev_task
      prev_task = task
    end

    project.replace_tasks([parent_task])

    puts project.to_s

    0
  end
end

GenerateGanttProject.new.start
