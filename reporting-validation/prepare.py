from pathlib import Path
import xml.etree.ElementTree as ET
import subprocess
subprocess.run(['git','-C','NightscoutService','apply','--check','../reporting-validation/reporting-only.patch'],check=True)
subprocess.run(['git','-C','NightscoutService','apply','../reporting-validation/reporting-only.patch'],check=True)
for repo, patch in [('LoopKit','snapshot-loopkit.patch'),('Loop','snapshot-loop.patch')]:
 subprocess.run(['git','-C',repo,'apply','--check','../reporting-validation/'+patch],check=True)
 subprocess.run(['git','-C',repo,'apply','../reporting-validation/'+patch],check=True)
scheme=ET.parse('NightscoutService/NightscoutService.xcodeproj/xcshareddata/xcschemes/Shared.xcscheme')
scheme.getroot().find('BuildAction').set('buildImplicitDependencies','YES')
for ref in scheme.iter('BuildableReference'):
 ref.set('ReferencedContainer','container:NightscoutService/NightscoutService.xcodeproj')
dest=Path('LoopWorkspace.xcworkspace/xcshareddata/xcschemes/ReportingValidation.xcscheme')
scheme.write(dest,encoding='utf-8',xml_declaration=True)
tests=Path('NightscoutService/NightscoutServiceKitTests/BolusRemoteNotificationTestCase.swift')
tests.write_text(tests.read_text()+Path('reporting-validation/BasalExportTests.swift').read_text())
