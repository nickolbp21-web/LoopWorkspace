"""Add optional reporting notes to the exact pinned package, in the CI checkout only."""
from pathlib import Path
import subprocess,sys,stat
root=Path(sys.argv[1]).resolve()
package=root/'checkouts'/'NightscoutKit'
assert package.is_dir(), 'Missing resolved NightscoutKit package'
revision=subprocess.check_output(['git','-C',str(package),'rev-parse','HEAD'],text=True).strip()
assert revision=='4ec9fd12a16b5d6c2de4f11870511361d42e1b7f', 'Unexpected package revision'
patch=Path('reporting-validation/precise-temp-basal.patch').resolve()
subprocess.run(['git','-C',str(package),'apply','--check',str(patch)],check=True)
p=package/'Sources/NightscoutKit/Models/Treatments/TempBasalNightscoutTreatment.swift'
p.chmod(p.stat().st_mode | stat.S_IWUSR)
subprocess.run(['git','-C',str(package),'apply',str(patch)],check=True)
print('Optional notes added to pinned reporting serializer; original fields unchanged.')
