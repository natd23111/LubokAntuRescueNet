# Firebase Database Seeding Guide 🌱

## Quick Start

The app now includes one-click database seeding for easy testing and demo setup.

### What Gets Seeded?

When you click "📥 Seed Database", these are automatically created:

**1. User Accounts** (2 accounts)
- Admin User: `admin@rescuenet.com` / `password123`
- Citizen: `citizen@rescuenet.com` / `password123`

**2. Aid Programs** (5 programs)
- B40 Financial Assistance 2025 (RM350/month)
- Disaster Relief Fund (RM1,500 one-time)
- Medical Emergency Fund (RM2,000 one-time)
- Education Scholarship Program (RM500 quarterly)
- Housing Assistance Program (RM3,000 one-time)

**3. Emergency Reports** (8 reports)
- House Fire (HIGH priority, unresolved)
- Flood (HIGH priority, in-progress)
- Medical Emergency (multiple variations)
- Car Accidents (2 reports)
- Landslide (MEDIUM priority, in-progress)
- Fire (MEDIUM priority, resolved)

---

## How to Use

### Step 1: Start the App
```bash
cd Lar-Frontend
flutter run -d chrome
```

### Step 2: Login as Admin
- Email: `admin@rescuenet.com`
- Password: `password123`

### Step 3: Navigate to Manage Section
- Click "Admin" in the sidebar
- Go to **Aid Programs** or **Manage Reports**

### Step 4: Seed the Database
```
Click the ⋮ (menu) button in the top-right corner
    ↓
Select "📥 Seed Database"
    ↓
Wait for ✅ confirmation message
    ↓
List auto-refreshes with sample data
```

---

## Where Seeding Buttons Appear

### Aid Programs Screen
- **Path:** Admin Dashboard → Aid Programs
- **Button:** Menu (⋮) top-right
- **Options:** 
  - 📥 Seed Database (creates 5 programs)
  - 🗑️ Clear Database (removes all programs)

### Manage Reports Screen  
- **Path:** Admin Dashboard → Manage Reports
- **Button:** Menu (⋮) top-right
- **Options:**
  - 📥 Seed Database (creates 8 reports)
  - 🗑️ Clear Database (removes all reports)

---

## What Each Button Does

### 📥 Seed Database
```
✅ Creates admin user if not exists
✅ Creates citizen user if not exists
✅ Creates 5 aid programs
✅ Creates 8 emergency reports
✅ Links reports to citizen user
✅ Auto-refreshes the list
✅ Shows success notification
```

**Result:** Your app has sample data ready for testing

### 🗑️ Clear Database
```
⚠️ Shows confirmation dialog
❌ Deletes ALL aid programs
❌ Deletes ALL emergency reports  
❌ Deletes ALL user profiles (except admin)
✅ Ready for fresh seed
```

**Result:** Clean slate for testing again

---

## Data Structure in Firestore

### Users Collection
```
users/{userId}
├── full_name: "John Citizen"
├── email: "citizen@rescuenet.com"
├── ic_no: "980225-08-5678"
├── phone_no: "0129876543"
├── address: "Block A, Jalan Sejahtera, Lubok Antu"
├── role: "resident" (or "admin")
├── status: "active"
├── created_at: 2025-12-30T...
└── updated_at: 2025-12-30T...
```

### Aid Programs Collection
```
aid_programs/{programId}
├── title: "B40 Financial Assistance 2025"
├── description: "Monthly financial assistance..."
├── category: "financial"
├── program_type: "Monthly"
├── aid_amount: "350"
├── criteria: "Household monthly income below RM2000..."
├── status: "active"
├── start_date: "2025-01-01"
├── end_date: "2025-12-31"
├── created_at: 2025-12-30T...
└── updated_at: 2025-12-30T...
```

### Emergency Reports Collection
```
emergency_reports/{reportId}
├── title: "House Fire in Taman Sejahtera"
├── type: "Fire"
├── location: "Taman Sejahtera, Lubok Antu"
├── description: "House fire reported at Taman Sejahtera..."
├── status: "unresolved"
├── priority: "high"
├── reporter_name: "John Doe"
├── reporter_ic: "901234-12-3456"
├── reporter_contact: "011-9876 5432"
├── date_reported: 2025-12-29T...
├── date_updated: null
├── admin_notes: null
├── user_id: "citizen_uid"
├── created_at: 2025-12-30T...
└── updated_at: 2025-12-30T...
```

---

## Testing Scenarios

### Scenario 1: Test Aid Program Management
1. Seed database
2. Go to Aid Programs
3. View 5 programs
4. Try creating a new program
5. Try editing a program
6. Try deleting a program

### Scenario 2: Test Report Management
1. Seed database
2. Go to Manage Reports
3. View 8 reports sorted by priority
4. Filter by status (Unresolved/In Progress/Resolved)
5. Search for a report
6. Update a report status
7. Add admin notes

### Scenario 3: Test Citizen View
1. Login as citizen: `citizen@rescuenet.com` / `password123`
2. View available aid programs
3. View own emergency reports (should see the 8 seeded reports)

### Scenario 4: Test Fresh Install
1. Clear database
2. Verify all data deleted
3. Seed database again
4. Verify fresh data created

---

## Important Notes

### ⚠️ Before Going to Production

**Remove these buttons:**
- Delete seed/clear buttons from manage_aid_programs_screen.dart
- Delete seed/clear buttons from manage_reports_screen.dart
- Delete lib/scripts/seed_firebase.dart file

**Update Firestore rules:**
```javascript
match /emergency_reports/{document=**} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update: if request.auth.token.admin == true;
  allow delete: if request.auth.token.admin == true;
}
```

### ✅ Safe for Testing
- Seed/clear buttons only appear on admin screens
- Requires admin login to access
- Confirmation dialog before clear
- Won't create duplicate users
- Full error handling

### 🔄 How to Reset Frequently
1. Click Admin → Aid Programs
2. Click ⋮ → Clear Database
3. Click ⋮ → Seed Database
4. Takes 2-3 seconds
5. All sample data restored

---

## Troubleshooting

**Q: Seed button not appearing?**
- A: Make sure you're logged in as admin
- A: Navigate to Admin → Aid Programs or Manage Reports
- A: Refresh the page if needed

**Q: "Database seeded successfully" but no data appears?**
- A: Wait a few seconds for Firestore to sync
- A: Refresh the page (browser F5)
- A: Check Firestore console for documents

**Q: Clear button didn't work?**
- A: Check Firestore console - documents might still be there
- A: Try clicking Clear again
- A: Check network connection

**Q: Getting permission errors?**
- A: Verify you're logged in as admin
- A: Check Firestore security rules are set correctly
- A: Check Firestore rules allow read/write

**Q: Want to seed manually?**
- A: Use Firestore Console to add documents directly
- A: Or run: `await FirebaseSeeder.seedDatabase();` in debug console

---

## Sample Credentials for Testing

| User | Email | Password | Role |
|------|-------|----------|------|
| Admin | admin@rescuenet.com | password123 | admin |
| Citizen | citizen@rescuenet.com | password123 | resident |

---

## Files Involved

- `lib/scripts/seed_firebase.dart` - Seeding logic
- `lib/screens/admin/manage_aid_programs_screen.dart` - Seed/clear buttons
- `lib/screens/admin/manage_reports_screen.dart` - Seed/clear buttons
- `lib/providers/aid_program_provider.dart` - Firebase operations
- `lib/providers/reports_provider.dart` - Firebase operations

---

## Next Steps

- [ ] Test seeding in your local environment
- [ ] Verify all 5 aid programs created
- [ ] Verify all 8 reports created
- [ ] Test filtering and search
- [ ] Test editing programs/reports
- [ ] Test deleting programs/reports
- [ ] Test clearing and reseeding

---

**Happy Testing! 🚀**
