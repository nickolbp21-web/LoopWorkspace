# This runs only on the disposable CI checkout. Production targets are unchanged.
require 'xcodeproj'
require 'rexml/document'

project = Xcodeproj::Project.open('LoopKit/LoopKit.xcodeproj')
target = project.targets.find { |item| item.name == 'LoopKitTests' }
abort 'LoopKitTests target missing' unless target
phase = target.source_build_phase
keep = phase.files.select { |item| File.basename(item.file_ref.path) == 'CarbValueTests.swift' }
abort 'Expected one shared test harness source' unless keep.length == 1
phase.files.to_a.each do |item|
  next if keep.include?(item)
  phase.files.delete(item)
  item.remove_from_project
end
project.save

directory = 'LoopWorkspace.xcworkspace/xcshareddata/xcschemes'
document = REXML::Document.new(File.read("#{directory}/LoopWorkspace.xcscheme"))
REXML::XPath.match(document, 'Scheme/TestAction/Testables/TestableReference').each do |item|
  next if item.elements['BuildableReference'].attributes['BlueprintName'] == 'LoopKitTests'
  item.parent.delete_element(item)
end
REXML::XPath.match(document, 'Scheme/BuildAction/BuildActionEntries/BuildActionEntry').each do |item|
  name = item.elements['BuildableReference'].attributes['BlueprintName']
  next if name == 'LoopKit'
  item.parent.delete_element(item)
end
File.open("#{directory}/MealPreviewValidation.xcscheme", 'w') { |file| document.write(file) }
test_action = document.elements['Scheme/TestAction']
test_action.delete_element('MacroExpansion') if test_action.elements['MacroExpansion']
File.open("#{directory}/MealPreviewValidation.xcscheme", 'w') { |file| document.write(file) }
puts 'Prepared isolated native framework test runner; full app build is separate'
