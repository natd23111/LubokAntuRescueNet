# Admin Dashboard Implementation

## Overview
The admin dashboard has been fully integrated into the RescueNet application. It provides comprehensive analytics, real-time statistics, and quick action management for administrators.

## Features

### 1. **Statistics Cards**
- **Total Reports**: Shows total number of emergency reports (47)
- **Unresolved Reports**: Displays urgent cases needing attention (12)
- **Aid Requests**: Shows pending aid requests (23)
- **Active Users**: Total registered users on platform (1,245)

Each card displays:
- Main metric value
- Change indicator (e.g., "+5 today", "+18 this week")
- Color-coded icon
- Icon background color

### 2. **Analytics Charts**

#### Report Types Distribution (Bar Chart)
- Shows breakdown of reports by type:
  - Flood: 15 reports
  - Fire: 8 reports
  - Accident: 12 reports
  - Medical: 7 reports
  - Landslide: 5 reports

#### Status Distribution (Pie Chart)
- Visualizes report status breakdown:
  - Unresolved (Orange): 12 reports
  - In Progress (Blue): 18 reports
  - Resolved (Green): 17 reports
- Center shows total count

#### Weekly Reports Trend (Line Chart)
- Displays daily report counts for the past week
- Shows trends: Mon-Sun with values ranging from 5-9 reports/day

### 3. **Quick Actions**
Three primary action buttons:
- **Manage Reports** (📋) - Navigate to report management
- **Aid Requests** (🤝) - View and manage aid requests
- **Aid Programs** (📢) - Access aid program management

### 4. **Recent Activity Feed**
Displays latest platform events with:
- Activity title and description
- Timestamp (5 min ago, 15 min ago, etc.)
- Status badge (Unresolved/Resolved)
- Color-coded backgrounds

### 5. **Priority Alerts**
High-visibility alert box showing:
- 3 emergency reports requiring immediate attention
- Direct navigation link to view reports
- Red color scheme for urgency

## Role-Based Navigation

### Login Flow
1. User enters credentials (email + password)
2. Backend returns user data with `role` field:
   - `'admin'` → Routes to AdminDashboardScreen
   - `'resident'` → Routes to HomeScreen (Citizen Dashboard)

### AuthProvider Updates
Added `userRole` property that captures the role during login:
```dart
userRole = response.data['user']['role'] ?? 'citizen';
```

### Main.dart Router
New `HomeRouter` class handles role-based navigation:
```dart
class HomeRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.userRole == 'admin') {
          return AdminDashboardScreen();
        }
        return HomeScreen();
      },
    );
  }
}
```

## Test Accounts

### Admin Account
- **Email**: admin@rescuenet.com
- **Password**: password123
- **IC**: 960115-12-1234

### Citizen Account
- **Email**: citizen@rescuenet.com
- **Password**: password123
- **IC**: 980225-08-5678

## Running the Seeder
To populate test data:
```bash
php artisan migrate:fresh --seed
```

## File Structure
```
Lar-Frontend/
  lib/
    screens/
      admin/
        admin_dashboard_screen.dart  (Main admin dashboard)
    providers/
      auth_provider.dart             (Updated with userRole)
    main.dart                        (Updated with HomeRouter)
```

## Customization Options

### Dynamic Data Integration
Currently using static data. To connect to APIs:
1. Create AdminProvider similar to AuthProvider
2. Add methods to fetch:
   - Reports by type
   - Status distribution
   - Weekly trends
   - Recent activity
3. Update AdminDashboardScreen to use Consumer<AdminProvider>

### Chart Customization
- Bar chart colors: Modify `Color(0xFF10B981)` in `_buildBarChart()`
- Pie chart colors: Update color values in `statusDistributionData`
- Chart heights: Adjust height values in chart builders

### Real-time Updates
Future Firebase integration can:
- Monitor live report submissions
- Update statistics in real-time
- Notify admins of urgent reports
- Track user activity status

## Next Steps
1. Migrate database with: `php artisan migrate`
2. Seed test data: `php artisan db:seed`
3. Login as admin to view dashboard
4. Connect charts to real API endpoints
5. Implement admin-specific features (report management, user management)
