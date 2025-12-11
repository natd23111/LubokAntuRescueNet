# Enhanced BantuanController - Filtering & Search Guide

## Overview

The BantuanController has been enhanced with comprehensive filtering, searching, and pagination capabilities to provide flexible and efficient program discovery for both administrators and residents.

---

## API Endpoints

### 1. Main Listing with Advanced Filtering
**Endpoint**: `GET /api/bantuan`

**Parameters**:
| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `status` | string | Filter by status (active/inactive) | `active` or `inactive` |
| `category` | string | Filter by category | `Financial`, `Medical`, `Education` |
| `program_type` | string | Filter by program type | `Monthly`, `One-time`, `Quarterly` |
| `start_date_from` | date | Filter programs starting from date | `2025-01-01` |
| `start_date_to` | date | Filter programs starting before date | `2025-12-31` |
| `min_amount` | numeric | Minimum aid amount (RM) | `500` |
| `max_amount` | numeric | Maximum aid amount (RM) | `2000` |
| `search` | string | Search in title, description, criteria | `financial` |
| `sort_by` | string | Sort by column | `title`, `aid_amount`, `created_at`, `start_date` |
| `sort_order` | string | Sort direction | `asc` or `desc` |
| `per_page` | integer | Items per page (max 100) | `15` |
| `page` | integer | Page number for pagination | `1` |

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "B40 Financial Assistance",
      "category": "Financial",
      "status": "Active",
      "aid_amount": "350.00",
      ...
    }
  ],
  "count": 5,
  "current_page": 1,
  "total_pages": 1,
  "per_page": 15
}
```

**Example Requests**:

```bash
# Get active programs only
GET /api/bantuan?status=active

# Get financial assistance programs
GET /api/bantuan?category=Financial

# Search for programs containing "medical"
GET /api/bantuan?search=medical

# Get programs with aid amount between RM500-2000
GET /api/bantuan?min_amount=500&max_amount=2000

# Get monthly programs sorted by amount (highest first)
GET /api/bantuan?program_type=Monthly&sort_by=aid_amount&sort_order=desc

# Combined filters: Active education programs, sorted by title
GET /api/bantuan?status=active&category=Education&sort_by=title

# Programs starting in 2025
GET /api/bantuan?start_date_from=2025-01-01&start_date_to=2025-12-31

# Pagination: Get 20 items per page, page 2
GET /api/bantuan?per_page=20&page=2
```

---

### 2. Get Single Program
**Endpoint**: `GET /api/bantuan/{id}`

Returns detailed information about a specific program.

**Response**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "B40 Financial Assistance 2025",
    "description": "Monthly financial assistance...",
    "category": "Financial",
    "program_type": "Monthly",
    "aid_amount": "350.00",
    "criteria": "Household income below RM2000...",
    "start_date": "2025-01-01",
    "end_date": "2025-12-31",
    "status": "Active",
    "admin_id": 1,
    "admin_remarks": "Active program for 2025",
    "created_at": "2025-12-11T...",
    "updated_at": "2025-12-11T..."
  }
}
```

---

### 3. Search Programs
**Endpoint**: `GET /api/bantuan/search`

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `q` | string | Search query (title, description, criteria) |
| `per_page` | integer | Items per page (max 100) |
| `page` | integer | Page number |

**Example**:
```bash
GET /api/bantuan/search?q=education&per_page=10
```

---

### 4. Get Active Programs Only
**Endpoint**: `GET /api/bantuan/active`

Returns only active programs (useful for residents).

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `category` | string | Filter by category |
| `search` | string | Search query |
| `per_page` | integer | Items per page |
| `page` | integer | Page number |

**Example**:
```bash
GET /api/bantuan/active?category=Medical&search=emergency
```

---

### 5. Get Programs by Category
**Endpoint**: `GET /api/bantuan/category/{category}`

Returns all active programs in a specific category.

**Example**:
```bash
GET /api/bantuan/category/Financial
```

---

### 6. Get All Categories
**Endpoint**: `GET /api/bantuan/categories`

Returns a sorted list of all available categories.

**Response**:
```json
{
  "success": true,
  "data": ["Education", "Emergency", "Financial", "Housing", "Medical", "Other"]
}
```

---

### 7. Get All Program Types
**Endpoint**: `GET /api/bantuan/program-types`

Returns a sorted list of all available program types.

**Response**:
```json
{
  "success": true,
  "data": ["Monthly", "One-time", "Quarterly", "Seasonal"]
}
```

---

### 8. Get Statistics
**Endpoint**: `GET /api/bantuan/stats`

Returns comprehensive statistics about programs.

**Response**:
```json
{
  "success": true,
  "data": {
    "total": 5,
    "active": 4,
    "inactive": 1,
    "by_category": [
      {
        "category": "Financial",
        "count": 1
      },
      {
        "category": "Education",
        "count": 1
      }
    ],
    "by_type": [
      {
        "program_type": "Monthly",
        "count": 1
      },
      {
        "program_type": "One-time",
        "count": 4
      }
    ],
    "total_aid_amount": 7350.00,
    "average_aid_amount": 1470.00
  }
}
```

---

## Admin Operations

### Create Program
**Endpoint**: `POST /api/admin/bantuan`

**Request Body**:
```json
{
  "title": "New Program",
  "category": "Financial",
  "description": "Program details",
  "program_type": "Monthly",
  "aid_amount": 500,
  "criteria": "Eligibility criteria",
  "start_date": "2025-01-01",
  "end_date": "2025-12-31",
  "status": "Active"
}
```

---

### Update Program
**Endpoint**: `PUT /api/admin/bantuan/{id}`

All fields are optional.

---

### Toggle Program Status
**Endpoint**: `PATCH /api/admin/bantuan/{id}/toggle-status`

Toggles between Active and Inactive.

---

### Delete Program
**Endpoint**: `DELETE /api/admin/bantuan/{id}`

---

## Real-World Usage Examples

### Example 1: Dashboard Statistics
Get total programs and breakdown by category:
```bash
GET /api/bantuan/stats
```

### Example 2: Resident Browsing
Show all active programs:
```bash
GET /api/bantuan/active?per_page=10
```

Filter by medical programs:
```bash
GET /api/bantuan/active?category=Medical
```

### Example 3: Admin Management
Get all programs with status filters:
```bash
GET /api/bantuan?status=active&sort_by=created_at&sort_order=desc
```

Get all inactive programs for review:
```bash
GET /api/bantuan?status=inactive
```

### Example 4: Search Functionality
Search for programs containing "assistance":
```bash
GET /api/bantuan/search?q=assistance
```

### Example 5: Filter by Amount Range
Find programs offering RM500-RM1000:
```bash
GET /api/bantuan?min_amount=500&max_amount=1000
```

---

## Pagination

All list endpoints support pagination with the following parameters:

- `per_page`: Items per page (default: 15, max: 100)
- `page`: Page number (default: 1)

Response includes pagination metadata:
```json
{
  "count": 5,
  "current_page": 1,
  "total_pages": 1,
  "per_page": 15
}
```

---

## Sorting

Supported sort columns:
- `id` - Program ID
- `title` - Program title
- `status` - Program status
- `aid_amount` - Aid amount
- `created_at` - Creation date (default)
- `start_date` - Start date

Sort orders:
- `asc` - Ascending (A-Z, lowest first)
- `desc` - Descending (Z-A, highest first) (default)

---

## Filtering Logic

### Status Filter
- Case-insensitive: `active`, `Active`, `ACTIVE` all work
- Accepts: `active`, `inactive`

### Category Filter
- Exact match: `Financial`, `Medical`, etc.
- Use `/api/bantuan/categories` to get valid values

### Program Type Filter
- Exact match: `Monthly`, `One-time`, `Quarterly`, `Seasonal`
- Use `/api/bantuan/program-types` to get valid values

### Date Range Filter
- Format: `YYYY-MM-DD`
- `start_date_from`: Programs starting on or after this date
- `start_date_to`: Programs starting on or before this date

### Amount Range Filter
- Numeric values in RM
- `min_amount`: Minimum aid amount (inclusive)
- `max_amount`: Maximum aid amount (inclusive)

### Search Filter
- Case-insensitive
- Searches in: title, description, criteria
- Supports partial matches

---

## Combining Multiple Filters

All filters can be combined in a single request:

```bash
GET /api/bantuan?status=active&category=Financial&min_amount=500&max_amount=2000&search=B40&sort_by=aid_amount&sort_order=asc&per_page=10
```

This request retrieves:
- Active programs
- In the Financial category
- With aid amounts between RM500-2000
- Matching search term "B40"
- Sorted by aid amount (ascending)
- 10 items per page

---

## Error Handling

All endpoints return appropriate HTTP status codes:

- `200 OK` - Successful request
- `201 Created` - Resource created
- `400 Bad Request` - Invalid parameters
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Admin authorization required
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation failed
- `500 Internal Server Error` - Server error

---

## Performance Considerations

- Pagination is recommended for large result sets
- Sorting is done at database level for efficiency
- Filtering is optimized with database queries
- Maximum 100 items per page to prevent large payloads
- Indexes on frequently filtered columns (status, category, created_at)

---

## Authentication

All endpoints require Bearer token authentication:

```bash
Authorization: Bearer {token}
```

Admin endpoints additionally require:
```bash
X-Admin-Role: true
```

(This is automatically validated by the `role:admin` middleware)

---

## Implementation in Flutter

To use these endpoints in your Flutter provider:

```dart
// Example: Fetch active programs in Financial category
Future<void> fetchFinancialPrograms() async {
  try {
    final response = await apiService.get(
      '/bantuan/active',
      queryParameters: {
        'category': 'Financial',
        'per_page': 20,
        'page': 1,
      },
    );
    
    final data = response['data'] as List;
    _programs = data.map((p) => AidProgram.fromJson(p)).toList();
    notifyListeners();
  } catch (e) {
    _error = e.toString();
  }
}
```

---

## Summary

The enhanced BantuanController provides:

✅ Advanced filtering (status, category, type, amount, date range)  
✅ Full-text search (title, description, criteria)  
✅ Flexible sorting (multiple columns, asc/desc)  
✅ Pagination (customizable per_page)  
✅ Statistics and breakdowns  
✅ Category and type lookups  
✅ Resident-focused view (active programs only)  
✅ Admin-focused view (all programs)  
✅ Efficient database queries  
✅ Comprehensive error handling  

**Status**: ✅ **Fully Implemented**
