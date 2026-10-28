# David's Opinions

How David thinks about engineering decisions.
Read this when a task would benefit from being informed by his viewpoints.

## Technical decisions

Do not give much weight to development cost.
Optimize for robustness, scalability, and long-term maintainability instead.

## Bug fixes

Always start by reproducing the bug in an end-to-end setting, as closely aligned with how an end user hits it as possible.
This makes sure you find the real problem, so your fix will actually solve it rather than masking a symptom.

## End-to-end testing

Be picky about the UI you see and be obsessed with pixel perfection.
If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed.

## Engineering excellence

Apply that same high standard to lint, test failures, and test flakiness.
If you see one, even if it is not caused by what you are working on right now, still get it fixed.
