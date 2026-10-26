# Meal preview handoff

Status: proposed custom Loop integration. Requires a rebuilt app; the existing TestFlight installation does not support this URL. Install the replacement candidate before enabling Open URLs. Before using it for a saved meal, verify the populated form and Cancel behavior on the phone.

Flow: existing meal lookup and sources â†’ editable grams and absorption minutes â†’ confirmation â†’ Loop's populated meal form â†’ review and save in Loop. Opening the URL does not store a carb entry, start a bolus, or change settings. Saving a carb entry in closed Loop can affect automatic insulin delivery.

The patch targets Loop commit `c2fddb76a20500bbbd0be5d4133d64382feae689` as pinned by this workspace. It preserves the existing carb-entry URL and existing native quantity warnings and limits. It uses Loop's internal new-carb activity to restore grams, meal time, and absorption time. This handoff explicitly opens the full meal editor, including when the optional Simple Bolus Calculator is enabled; that simpler screen otherwise drops absorption. Normal meal-entry actions retain their existing UI preference. It rejects malformed/duplicate/unknown parameters, unsupported versions, nonfinite/nonpositive values, out-of-range absorption, quantities above Loop's maximum, stale meal times, and presentation while another modal is open. Invalid links return failure and do not create entries. The supported meal time is within the previous five minutes or next one minute; older meals must use the normal manual form. Reopening a valid URL may reopen a preview; it is not a save receipt. Never retry saving without checking Loop for an existing entry.

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

The PR validation applies this exact patch to the pinned source, tests the actual Swift parser, and builds an unsigned simulator app without signing secrets. It does not upload to TestFlight or communicate with a pump. Parser and build success do not establish on-device delivery or clinical correctness.

Before release, exercise the complete UI path in a simulator: valid preview has exact grams/minutes/time; Cancel creates no entry; invalid/stale/duplicate links create no entry; existing carb-entry and other deep links still work; modal presentation is not replaced; native high-carb warning remains. Use synthetic data only in a disconnected simulator. Do not test by saving synthetic meals on a phone controlling insulin delivery.

The manual `Upload meal preview candidate to TestFlight` workflow applies both the existing reporting patches and the meal patch, checks successful validation of the exact app source, and reuses existing certificates read-only. Internal candidates can be uploaded for phone preview verification. The initial build 5 is superseded by the replacement that forces the full meal editor. Use the final build number reported after Apple processing verification. Before saving a real meal, verify the filled fields and Cancel on the phone. Never save synthetic test meals on a phone controlling insulin. Keep this PR as a draft until that check is complete; merging does not automatically upload a new build.

Sources: [pinned Loop deep link code](https://github.com/LoopKit/Loop/blob/c2fddb76a20500bbbd0be5d4133d64382feae689/Loop/Managers/DeeplinkManager.swift), [Loop meal entry documentation](https://loopkit.github.io/loopdocs/operation/features/carbs/).
