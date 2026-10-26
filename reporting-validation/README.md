# Reporting-export validation only

This branch tests a candidate against the existing source revision. It does not
sign, archive, distribute, or install an app, and does not alter main.
The patch exports immutable scheduled basal records as Nightscout notes, keeping
schedule-derived amounts distinct from explicitly reported delivered amounts.
It does not change dosing algorithms, therapy settings, or pump commands.
Passing framework tests is not end-to-end clinical reporting validation.
The production server must not interpret these notes as measured basal delivery.
