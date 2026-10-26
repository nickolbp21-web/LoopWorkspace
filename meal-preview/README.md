# Meal preview handoff

Status: proposed custom Loop integration. Requires a rebuilt app; the existing TestFlight installation does not support this URL. Install the replacement candidate before enabling Open URLs. Before using it for a saved meal, verify the populated form and Cancel behavior on the phone.

Flow: existing meal lookup and sources â†’ editable grams and absorption minutes â†’ confirmation â†’ Loop's populated meal form â†’ review and save in Loop. Opening the URL does not store a carb entry, start a bolus, or change settings. Saving a carb entry in closed Loop can affect automatic insulin delivery.

The patch targets Loop commit `c2fddb76a20500bbbd0be5d4133d64382feae689` as pinned by this workspace. It preserves the existing carb-entry URL and existing native quantity warnings and limits. It uses Loop's internal new-carb activity to restore grams, meal time, and absorption time. This handoff explicitly opens the full meal editor, including when the optional Simple Bolus Calculator is enabled; that simpler screen otherwise drops absorption. Normal meal-entry actions retain their existing UI preference. It rejects malformed/duplicate/unknown parameters, unsupported versions, nonfinite/nonpositive values, out-of-range absorption, quantities above Loop's maximum, stale meal times, and presentation while another modal is open. Invalid links return failure and do not create entries. The supported meal time is within the previous five minutes or next one minute; older meals must use the normal manual form. Reopening a valid URL may reopen a preview; it is not a save receipt. Never retry saving without checking Loop for an existing entry.

## Accept typed meals, receipt screenshots, and meal photos

Configure the same Meal Notes shortcut to appear in the Share Sheet and accept Images and Text (or Any if iOS requires one combined setting). Add an input branch before the existing lookup:

- If `Shortcut Input` has content, set `Meal Evidence` to that input. From Photos, select one or more receipt screenshots or a meal picture, tap Share, then run Meal Notes.
- Otherwise show a menu: `Choose photo` runs `Select Photos` with Select Multiple enabled and sets `Meal Evidence` to the selected image(s); `Type meal` runs `Ask for Input` and sets `Meal Evidence` to that text.
- In the existing Use Model prompt, replace the typed-only meal variable with `Meal Evidence`. Keep the source lookup, Follow Up, and missing-portion questions. Apple's model action supports photos as input; actual image readability and model usage limits still depend on the device/account.

Add image-specific instructions to the lookup prompt: for receipts, transcribe all readable items and quantities before checking current nutrition sources; receipt prices do not establish nutrition, and unreadable abbreviations/size options require clarification. For meal photos, list visible foods and label portion sizes as visual estimates; do not claim to know exact weights, hidden ingredients, or quantities from the image. Ask one bundled clarification when a material item/portion is uncertain. If it remains unresolved, mark the meal incomplete and do not pass a subtotal to Loop. The carb and absorption confirmation and Loop review steps below still apply unchanged.

## Shortcut changes after installation

Keep your existing meal lookup, source display, and missing-portion questions. Never transfer a subtotal or a result with unresolved portions.

1. After the complete result is shown, add a second Use Model action (no browsing needed) to convert that result into JSON. Prompt: `Extract from the preceding meal result only. Return JSON only with keys complete (boolean), total_carbs_g (number or null), absorption_minutes (number or null). Complete must be false if any portions are unresolved, the result is a subtotal, or either value is missing. Preserve TOTAL carbs, never net carbs. Convert H:MM absorption to minutes: 3:00 = 180, 5:00 = 300, 0:30 = 30. Do not invent or recompute values. Result: [Response from first Use Model]` Insert the actual response variable.
2. Use Get Dictionary from Input, then Get Dictionary Value for each of the three keys. If complete is not true, show `Meal incompleteâ€”resolve portions first` and Stop This Shortcut. Also stop if either number is absent or nonpositive. The model output is an estimate to review, not an authority to save.
3. Ask for Input, Number, `Review TOTAL carbs (grams)`; set Default Answer to total_carbs_g. Save answer as ReviewedGrams.
4. Ask for Input, Number, `Review absorption (MINUTES: 180 = 3 hours)`; set Default Answer to absorption_minutes. Save answer as ReviewedMinutes. Keep values within your app's supported bounds; this source uses 30â€“480 minutes. Zero-carb meals need no carb entry through this handoff.
5. Get Current Date and save as MealTime. This version is for a meal being eaten now. Display it in the confirmation. For an earlier meal, cancel and enter the original time manually in Loop.
6. Show Alert with Cancel enabled: `Open Loop for review? TOTAL carbs: [ReviewedGrams] g. Absorption: [ReviewedMinutes] minutes. Meal time: [MealTime]. Loop will open a draft; review it there before saving. Saving carbs can affect automated insulin delivery.` Insert the actual variables. Cancel must end the shortcut.
7. Create a Date action with ISO timestamp `1970-01-01T00:00:00Z`. Get Time Between Dates from that date to MealTime, in Seconds; save as MealEpoch. Build a Text action with the URL below using actual magic variables, then Open URLs. Use plain decimal numbers, a dot for any fraction, and no grouping separators. The receiver rejects other formats. Do not ask AI to generate the URL.

`Loop://meal-preview?v=1&grams=[ReviewedGrams]&absorption_minutes=[ReviewedMinutes]&meal_time=[MealEpoch]`

8. In Loop, verify grams, meal date/time, and absorption. Cancel if anything differs. Saving remains an explicit action in Loop. This flow does not return a success receipt to Shortcuts; check the actual meal entry before considering any retry.

## Validation and release

[Native validation passed](https://github.com/nickolbp21-web/LoopWorkspace/actions/runs/40290318684): 34 parser cases and an iOS Simulator payload test covering four combinations of grams and absorption with a meal time two minutes before creation. CI extracts the production parser and entry factory unchanged from the patched app file and tests the round trip through real LoopKit carb-entry and NSUserActivity APIs. The actual native assertion ran with zero failures. Tests create and serialize draft objects; they do not store meal entries.

The full signed iPhone Release build and archive validation run separately in the manual TestFlight workflow. The pinned source's unrelated legacy tests have compile errors, and its full Debug simulator host has plug-in packaging issues; the focused data test does not launch that host. Phone UI preview/cancel verification is still required. Source and test checks do not establish clinical correctness of an AI food estimate.

The manual `Upload meal preview candidate to TestFlight` workflow applies the existing reporting patches and the meal patch, checks successful native validation and its actual assertion output, confirms that app source matches the validated revision, and reuses existing certificates read-only. It does not run automatically on push. Build 5 was the preliminary candidate and is superseded by the replacement that always opens the full editor and preserves both timestamps. Use the final build number reported after Apple processing verification.

Install that candidate through TestFlight, then add the Shortcut steps above. Use your intended real meal to check the filled grams, absorption, and meal time; Cancel the preview to check cancellation. Never save synthetic test meals on a phone controlling insulin. Keep this PR as a draft until that phone check is complete. Merging does not automatically upload another build.

Sources: [pinned Loop deep link code](https://github.com/LoopKit/Loop/blob/c2fddb76a20500bbbd0be5d4133d64382feae689/Loop/Managers/DeeplinkManager.swift), [Loop meal entry documentation](https://loopkit.github.io/loopdocs/operation/features/carbs/).
