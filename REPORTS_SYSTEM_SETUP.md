# Reports Management System - Backend Integration

## Summary

The Manage Reports screen is now fully integrated with your Laravel backend. Here's what has been implemented:

## Backend Setup

### 1. Database Migration (`create_reports_table.php`)
Created a new reports table with the following fields:
- `id` - Primary key
- `title` - Report title (nullable)
- `type` - Report type (Fire, Flood, Medical Emergency, Accident, Landslide, etc.)
- `location` - Report location
- `description` - Detailed description
- `status` - (unresolved, in-progress, resolved)
- `priority` - (low, medium, high)
- `reporter_name` - Name of reporter
- `reporter_ic` - IC number of reporter
- `reporter_contact` - Contact information
- `date_reported` - When report was submitted
- `date_updated` - Last update timestamp
- `admin_notes` - Admin comments
- `image_url` - Photo/image URL

### 2. Model (`Report.php`)
- Full fillable attributes
- Date casting for `date_reported` and `date_updated`

### 3. Controller (`ReportsController.php`)
Complete CRUD operations with features:

**Endpoints:**
- `GET /api/reports` - List reports with filtering/sorting/pagination
- `GET /api/reports/{id}` - Get single report
- `POST /api/reports` - Create new report
- `PUT /api/reports/{id}` - Update report
- `DELETE /api/reports/{id}` - Delete report
- `GET /api/reports/stats` - Get reports statistics

**Filter Parameters:**
- `status` - Filter by status (unresolved, in-progress, resolved)
- `priority` - Filter by priority (low, medium, high)
- `type` - Filter by report type
- `search` - Full-text search across title, location, type, reporter name
- `sort_by` - Sort column (default: date_reported)
- `sort_order` - Sort direction (asc/desc)
- `per_page` - Pagination (default: 15)

### 4. Routes (`api.php`)
Added admin-only routes under `auth:sanctum` middleware:
```
GET    /reports              - List reports
GET    /reports/stats        - Get statistics
POST   /reports              - Create report
GET    /reports/{id}         - Get report details
PUT    /reports/{id}         - Update report
DELETE /reports/{id}         - Delete report
```

### 5. Seeder (`ReportsSeeder.php`)
Populated database with 8 sample reports:
- 2 Unresolved (Fire, Accident)
- 2 In Progress (Flood, Landslide)
- 3 Resolved (Medical Emergency, Fire, Accident)
- Plus additional high-priority medical emergency

## Frontend Setup

### 1. Provider (`reports_provider.dart`)
State management class with:
- `Report` model with JSON serialization
- `ReportsProvider` class extending `ChangeNotifier`

**Key Methods:**
- `fetchReports()` - Load reports from API
- `fetchReportDetails(id)` - Get single report
- `updateReport()` - Update status/priority/notes
- `deleteReport()` - Delete report
- `setActiveTab(tab)` - Change active tab
- `setSearchQuery(query)` - Search reports

**Features:**
- Automatic filtering by tab and search query
- Error handling and timeout management (10 seconds)
- Android emulator localhost support (`10.0.2.2:8000`)

### 2. Screen (`manage_reports_screen.dart`)
Complete UI with three views:

**List View:**
- Tabbed interface (Unresolved, In Progress, Resolved)
- Search functionality
- Report cards with priority badges
- Loading states and empty states

**Detail View:**
- Full report information
- Reporter contact details
- Status display
- Admin notes display
- Image placeholder

**Edit View:**
- Status dropdown (Unresolved, In Progress, Resolved)
- Priority dropdown (High, Medium, Low)
- Admin notes textarea
- Last updated timestamp
- Success/error feedback

### 3. Integration
Connected to admin dashboard:
- Quick action "Manage Reports" navigates to reports screen
- Provider integration for real-time updates
- Proper error handling and snackbar notifications

## Deployment Steps

### Backend:
1. Run migration:
```bash
php artisan migrate
```

2. Seed database:
```bash
php artisan db:seed
```

Or both together:
```bash
php artisan migrate:fresh --seed
```

### Frontend:
1. The provider is created and ready to use
2. No additional dependencies needed (http package already included)
3. URL is configured for Android emulator: `http://10.0.2.2:8000/api`

**Note:** For physical device or iOS, update the base URL in `reports_provider.dart`:
```dart
final String baseUrl = 'http://YOUR_ACTUAL_IP:8000/api';
```

## Sample Data
8 reports have been seeded across all statuses and priorities:
- Fire emergency (unresolved, high priority)
- Flood (in-progress, high priority)
- Medical emergencies (mixed statuses)
- Traffic accidents (mixed statuses)
- Landslide (in-progress, medium priority)

## Features
✅ Dynamic data from backend
✅ Create/Read/Update/Delete operations
✅ Tab filtering (by status)
✅ Search functionality
✅ Priority color coding
✅ Status tracking
✅ Admin notes
✅ Responsive design
✅ Error handling
✅ Loading states
✅ Success feedback

## API Response Format
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "House Fire",
      "type": "Fire",
      "location": "Taman Sejahtera",
      "description": "...",
      "status": "unresolved",
      "priority": "high",
      "reporter_name": "John Doe",
      "reporter_ic": "901234-12-3456",
      "reporter_contact": "011-9876 5432",
      "date_reported": "2025-12-13 09:30:00",
      "date_updated": null,
      "admin_notes": null,
      "image_url": null,
      "created_at": "2025-12-14T00:00:00.000000Z",
      "updated_at": "2025-12-14T00:00:00.000000Z"
    }
  ],
  "pagination": {
    "total": 8,
    "per_page": 15,
    "current_page": 1,
    "last_page": 1
  }
}
```

The reports system is now fully functional and ready to use!
