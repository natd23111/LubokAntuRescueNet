# Aid Program CRUD System - Quick Start Guide

## How to Use the System

### For Admin Users

#### 1. Accessing Aid Programs
1. Open the app and login with admin credentials:
   - Email: `admin@rescuenet.com`
   - Password: `password123`
2. Go to Admin Dashboard
3. Click the "Aid Programs" quick action button
4. You'll see the Manage Aid Programs screen

#### 2. Viewing All Programs
- The Manage Aid Programs screen displays all programs in a list
- Each card shows:
  - Program title
  - Program ID
  - Status badge (green for Active, red for Inactive)
  - Brief description
  - Date range (Start - End)
  - Three action buttons (Edit, Activate/Deactivate, Delete)

#### 3. Creating a New Program
1. Click "Add New Aid Program" button at the top
2. Fill in all required fields:
   - **Program Title**: Name of the program (e.g., "B40 Financial Assistance")
   - **Category**: Select from dropdown (Financial, Medical, Education, Housing, Food, Other)
   - **Description**: Detailed description of what the program offers
   - **Start Date**: Click calendar icon to select program start date
   - **End Date**: Click calendar icon to select program end date
   - **Program Type**: Select from dropdown (Monthly, One-time, Quarterly, Seasonal)
   - **Aid Amount**: Enter in RM (e.g., 500.00)
   - **Eligibility Criteria**: Detailed requirements for recipients
   - **Status**: Select Active or Inactive
3. Click "Submit" to save
4. Success message will appear and you'll return to the list

#### 4. Editing a Program
1. Click the "Edit" button on the program card
2. The Edit form opens with all current data pre-filled
3. Modify any fields as needed
4. Click "Update Program" to save changes
5. Success message appears and returns to the list

#### 5. Toggling Program Status
1. On the program card, click "Activate" (if inactive) or "Deactivate" (if active)
2. The status will toggle immediately
3. Button color changes (orange for deactivate, green for activate)
4. Success snackbar shows the new status

#### 6. Deleting a Program
1. Click the delete icon (trash can) on the program card
2. Confirmation dialog appears asking "Are you sure?"
3. Click "Delete" to confirm or "Cancel" to abort
4. Program is removed from the list
5. Success message appears

---

## Technical Details

### Database Structure
Programs are stored in the `bantuan_programs` table with the following information:
- Title, Description, Category
- Program Type, Aid Amount
- Eligibility Criteria
- Start & End Dates
- Status (Active/Inactive)
- Admin ID (who created/updated)
- Admin Remarks
- Timestamps (created_at, updated_at)

### API Endpoints

**For Admin Operations:**
- Create: `POST /api/admin/bantuan`
- Update: `PUT /api/admin/bantuan/{id}`
- Toggle Status: `PATCH /api/admin/bantuan/{id}/toggle-status`
- Delete: `DELETE /api/admin/bantuan/{id}`

**For Viewing:**
- List All: `GET /api/bantuan`
- Get One: `GET /api/bantuan/{id}`
- By Category: `GET /api/bantuan/category/{category}`
- Get Categories: `GET /api/bantuan/categories`
- Statistics: `GET /api/bantuan/stats`

### State Management
The system uses Flutter's Provider pattern:
- `AidProgramProvider` manages all program state
- Automatically handles API requests with authentication
- Manages loading/error states
- Maintains list of programs locally

---

## Common Scenarios

### Scenario 1: Create a Monthly Aid Program
1. Click "Add New Aid Program"
2. Title: "January B40 Assistance"
3. Category: "Financial"
4. Description: "Monthly financial support for B40 households"
5. Start: Pick 1st January 2025
6. End: Pick 31st January 2025
7. Type: "Monthly"
8. Amount: "350"
9. Criteria: "Household income < RM2000, Malaysian citizen"
10. Status: "Active"
11. Click Submit ✓

### Scenario 2: Temporarily Pause a Program
1. Find the program in the list
2. Click "Deactivate" button
3. Status changes to Inactive ✓
4. To resume: Click "Activate" ✓

### Scenario 3: Update Program Details
1. Click "Edit" on the program
2. Change dates, amount, or criteria as needed
3. Click "Update Program"
4. Changes are saved ✓

### Scenario 4: End-of-Year Cleanup
1. Review all inactive programs
2. Click Delete on programs no longer needed
3. Confirm deletion
4. Programs are removed ✓

---

## Validation Rules

- **Title**: Required, cannot be empty
- **Category**: Must select one option
- **Description**: Required, should be detailed
- **Start Date**: Must be valid date
- **End Date**: Should be after start date
- **Program Type**: Must select one option
- **Aid Amount**: Must be numeric (e.g., 500.00)
- **Eligibility Criteria**: Required field
- **Status**: Must select Active or Inactive

---

## Tips & Best Practices

1. **Be Descriptive**: Write clear descriptions so residents understand the program
2. **Set Realistic Dates**: Make sure program dates make sense
3. **Update Criteria**: Keep eligibility criteria current
4. **Use Categories**: Properly categorize to help residents find relevant programs
5. **Regular Review**: Periodically review and update program details
6. **Admin Remarks**: Use remarks to note why programs are inactive

---

## Troubleshooting

**Q: Program won't save**
- A: Check that all fields are filled in correctly
- A: Make sure you're not closing the form before submission completes

**Q: Can't update a program**
- A: Ensure you're logged in as admin
- A: Try clicking Update again if it fails

**Q: Delete button doesn't work**
- A: Confirm the deletion dialog when it appears
- A: Make sure the program exists (try refreshing)

**Q: Status won't toggle**
- A: Check your internet connection
- A: Refresh the page and try again
- A: Ensure you have admin permissions

---

## Contact Support

If you encounter issues:
1. Note the exact error message
2. Take a screenshot if possible
3. Report to the development team
4. Include the program ID if applicable

---

## File Structure

```
Lar-Frontend/lib/
├── screens/admin/
│   ├── manage_aid_programs_screen.dart    # Main list view
│   ├── add_aid_program_form.dart          # Create form
│   ├── edit_aid_program_form.dart         # Edit form
│   └── admin_dashboard_screen.dart        # Dashboard (has quick access)
├── providers/
│   └── aid_program_provider.dart          # State management
├── models/
│   └── aid_program.dart                   # Data model
└── services/
    └── api_service.dart                   # API client

Lar-Backend/
├── app/Controllers/
│   └── BantuanController.php              # CRUD logic
├── app/Models/
│   └── BantuanProgram.php                 # Database model
├── database/
│   ├── migrations/
│   │   ├── 2025_12_09_074752_create_bantuan_programs_table.php
│   │   └── 2025_12_11_000001_add_fields_to_bantuan_programs_table.php
│   └── seeders/
│       └── DatabaseSeeder.php             # Test data
└── routes/
    └── api.php                            # API routes
```

---

## Version History

- **v1.0** (11 Dec 2025) - Initial implementation with full CRUD
  - Create programs
  - Read/List programs
  - Update programs
  - Delete programs
  - Toggle status
  - Filtering by category/status/search
  - Admin tracking
  - Database seeding with 5 test programs

---

**System Status**: ✅ **FULLY OPERATIONAL**

Ready to deploy and accept user feedback!
