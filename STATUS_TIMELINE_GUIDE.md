# Status Timeline - Full Implementation Guide

## Overview
The Status Timeline is now fully functional and automatically tracks the progression of an emergency report through different statuses.

## How It Works

### Timeline Stages

The timeline shows 3 stages that a report progresses through:

1. **Report Submitted** ✅
   - **Status**: Always Active (green dot)
   - **Date**: Automatically set when report is created
   - **Field**: `dateReported`
   - Shows the exact date and time the report was submitted

2. **Under Review** 🔄
   - **Status**: Becomes active when admin changes status to "In Progress"
   - **Date**: Automatically captured when status changes to "In Progress"
   - **Field**: `dateUnderReview`
   - Shows "Pending" until the report is picked up by admin

3. **Resolved** ✅
   - **Status**: Becomes active when admin changes status to "Resolved"
   - **Date**: Automatically captured when status changes to "Resolved"
   - **Field**: `dateDispatched`
   - Shows "Pending" until the report is resolved

## Code Changes Made

### 1. Report Model Enhancement ([reports_provider.dart](lib/providers/reports_provider.dart#L1-L80))
Added three new date tracking fields:
```dart
final DateTime? dateUnderReview;    // When status changed to in-progress
final DateTime? dateDispatched;     // When status changed to resolved
```

These are automatically captured in Firestore when status transitions occur.

### 2. updateReport Method Enhancement ([reports_provider.dart](lib/providers/reports_provider.dart#L230-L272))
Updated to automatically track status transitions:
```dart
// When status changes to in-progress
if (statusLower == 'in-progress') {
  updateData['date_under_review'] = DateTime.now();
}

// When status changes to resolved
if (statusLower == 'resolved') {
  updateData['date_dispatched'] = DateTime.now();
}
```

### 3. Timeline Display Update ([view_reports_screen.dart](lib/screens/citizen/view_reports_screen.dart#L694-L732))
Updated to show actual dates for each transition:
- Uses `dateReported` for "Report Submitted"
- Uses `dateUnderReview` for "Under Review" (shows "Pending" if not yet updated)
- Uses `dateDispatched` for "Resolved" (shows "Pending" if not yet updated)

## How Citizens See It

When a citizen views a report's details:

### New Report (Status: Unresolved)
```
Status Timeline
● Report Submitted       Dec 30, 2025 - 10:30 AM
○ Under Review           Pending
○ Resolved               Pending
```

### Report Being Processed (Status: In Progress)
```
Status Timeline
● Report Submitted       Dec 30, 2025 - 10:30 AM
● Under Review           Dec 30, 2025 - 10:45 AM
○ Resolved               Pending
```

### Resolved Report (Status: Resolved)
```
Status Timeline
● Report Submitted       Dec 30, 2025 - 10:30 AM
● Under Review           Dec 30, 2025 - 10:45 AM
● Resolved               Dec 30, 2025 - 11:15 AM
```

## Admin Panel Integration

For the admin side to work properly with this timeline, ensure:

1. **Status dropdown** has these three options (case-insensitive):
   - `unresolved` or `pending` (initial state)
   - `in-progress` (when admin starts working on it)
   - `resolved` (when issue is fixed)

2. **When updating a report**, use the existing `updateReport()` method:
   ```dart
   await reportsProvider.updateReport(
     reportId: 'ER20250001',
     status: 'in-progress',
     priority: 'high',
     adminNotes: 'Response team dispatched',
   );
   ```

3. **Dates are captured automatically** - admins don't need to manually set timeline dates

## Database Fields

The following fields are now stored in Firebase for each report:

| Field | Type | Set When | Purpose |
|-------|------|----------|---------|
| `date_reported` | DateTime | Report created | When report was submitted |
| `date_under_review` | DateTime | Status → In Progress | When admin started handling |
| `date_dispatched` | DateTime | Status → Resolved | When issue was resolved |
| `date_updated` | DateTime | Any status change | Last update timestamp |

## Testing the Timeline

### Test Case 1: New Report
1. Submit an emergency report
2. Go to "Report Status" → "My Reports"
3. Click on the report
4. Verify timeline shows:
   - ✅ Report Submitted with current date/time
   - ⏳ Under Review: Pending
   - ⏳ Resolved: Pending

### Test Case 2: Report Status Update (requires admin panel)
1. Have admin update report status to "In Progress"
2. Refresh the report details
3. Verify timeline shows:
   - ✅ Report Submitted: Original date
   - ✅ Under Review: New date/time
   - ⏳ Resolved: Pending

### Test Case 3: Report Fully Resolved
1. Have admin update report status to "Resolved"
2. Refresh the report details
3. Verify timeline shows:
   - ✅ Report Submitted: Original date
   - ✅ Under Review: Earlier date
   - ✅ Resolved: Final date/time

## Firestore Security Rules

Ensure your Firestore rules allow:
- Citizens to read their own reports' timeline data
- Admins to update status and have the dates automatically captured

## Visual Indicators

- **Green dot (●)**: Completed stage with date
- **Gray dot (○)**: Not yet reached, shows "Pending"
- Dots are connected with a vertical line for visual continuity

## Future Enhancements

Possible improvements:
1. Add more granular statuses (e.g., "Assigned", "Investigating", "In Transit")
2. Add notes/comments at each timeline stage
3. Send notifications to citizen when status changes
4. Add estimated resolution time
5. Show response team member names (when assigned)

## Troubleshooting

**Timeline shows all "Pending"?**
- Check that the report has a valid `dateReported` value
- Ensure the report was created with the new code

**Dates not updating when admin changes status?**
- Verify the admin is using the `updateReport()` method
- Check Firestore console to see if `date_under_review` is being set
- Ensure the Flutter app is using the latest ReportsProvider code

**Timeline shows old dates?**
- Dates are captured at the moment status changes
- They reflect the actual transition times from your Firestore database
- This is correct behavior (shows historical progression)

## Summary

The Status Timeline is now:
✅ Fully automatic - no manual date entry needed
✅ Tracked at each stage - captures exact transition times
✅ Citizen-visible - shows clear progress through report lifecycle
✅ Admin-integrated - dates set automatically when status changes
✅ Persistent - historical dates saved in Firestore for record-keeping
