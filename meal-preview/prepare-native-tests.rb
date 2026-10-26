# This runs only on the disposable CI checkout. Production targets are unchanged.
require 'xcodeproj'
require 'rexml/document'

project = Xcodeproj::Project.open('Loop/Loop.xcodeproj')
target = project.targets.find { |item| item.name == 'LoopTests' }
abort 'LoopTests target missing' unless target
phase = target.source_build_phase
keep = phase.files.select { |item| File.basename(item.file_ref.path) == 'LoopTests.swift' }
abort 'Expected one shared test harness source' unless keep.length == 1
phase.files.to_a.each do |item|
  next if keep.include?(item)
  phase.files.delete(item)
  item.remove_from_project
end
project.save

directory = 'LoopWorkspace.xcworkspace/xcshareddata/xcschemes'
document = REXML::Document.new(File.read("#{directory}/LoopWorkspace.xcscheme"))
document.elements.each('Scheme/TestAction/Testables/TestableReference') do |item|
  next if item.elements['BuildableReference'].attributes['BlueprintName'] == 'LoopTests'
  item.parent.delete_element(item)
end
document.elements.each('Scheme/BuildAction/BuildActionEntries/BuildActionEntry') do |item|
  name = item.elements['BuildableReference'].attributes['BlueprintName']
  next unless name.end_with?('Tests') && name != 'LoopTests'
  item.parent.delete_element(item)
end
File.open("#{directory}/MealPreviewValidation.xcscheme", 'w') { |file| document.write(file) }
puts 'Prepared isolated native handoff test scheme; full app targets retained'
