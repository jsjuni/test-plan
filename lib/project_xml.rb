# frozen_string_literal: true

require 'date'
require 'rexml/document'
require 'securerandom'

module ProjectXML

  class Task < REXML::Element

    def initialize(id, name, duration = 1, start = Date.today.iso8601)
      super('task')
      self.attributes['id'] = id
      self.attributes['uid'] = SecureRandom.uuid
      self.attributes['name'] = name
      self.attributes['start'] = start
      self.attributes['duration'] = duration.round.to_s
    end

    def add_successor(id)
      depend = REXML::Element.new('depend')
      depend.attributes['id'] = id
      depend.attributes['type'] = '2'
      depend.attributes['difference'] = '0'
      depend.attributes['hardness'] = 'Strong'
      add_element(depend)
    end

  end

  class Project

    def initialize(template)
      @template = REXML::Document.new(template)
    end

    def replace_tasks(tasks)
      tasks_parent = @template.elements['//tasks']
      tasks_parent.each_element('task') { |t| tasks_parent.delete(t) }
      tasks_parent.texts.each { |t| tasks_parent.delete(t) }
      tasks.each do |t|
        @template.elements['//tasks'].add_element(t)
      end
    end

    def to_s
      REXML::Formatters::Pretty.new.write(@template, String.new)
    end
  end

end
