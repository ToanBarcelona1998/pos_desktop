# Database Schema Documentation

This document describes the SQLite database schema used in the POS application.

## Overview

The application uses SQLite for local data storage, managed through the `DatabaseHelper` class in the data layer. The database is user-specific, with each user having their own database file named `PosDemo{userId}.db`.

## Current Version

**Database Version:** 10

## Tables

### 1. System Table

Stores system-level configuration and cached data.

```sql
CREATE TABLE system (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  keyId INTEGER DEFAULT null,
  key TEXT,
  value TEXT
)
```

**Purpose:** Stores key-value pairs for:
- Authentication token (`token`)
- User details (`loggedInUser`)
- User permissions (`user_permissions`)
- Business details (`business`)
- Brands (`brand`)
- Categories (`taxonomy`)
- Sub-categories (`sub_categories`)
- Payment methods (`payment_methods`, `payment_method`)
- Locations (`location`)
- Payment accounts (`payment_accounts`)
- Active subscription (`active-subscription`)
- Last sync timestamps (`products_last_sync`, `customers_last_sync`, `call_logs_last_sync`)

### 2. Contact Table

Stores customer/contact information for offline access.

```sql
CREATE TABLE contact (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  address_line_1 TEXT,
  address_line_2 TEXT,
  zip_code TEXT,
  mobile TEXT
)
```

### 3. Variations Table

Stores product variations/SKUs for offline product lookup.

```sql
CREATE TABLE variations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER,
  variation_id INTEGER,
  product_name TEXT,
  product_variation_name TEXT,
  variation_name TEXT,
  display_name TEXT,
  sku TEXT,
  sub_sku TEXT,
  type TEXT,
  enable_stock INTEGER,
  brand_id INTEGER,
  unit_id INTEGER,
  category_id INTEGER,
  sub_category_id INTEGER,
  tax_id INTEGER,
  default_sell_price REAL,
  sell_price_inc_tax REAL,
  product_image_url TEXT,
  selling_price_group BLOB DEFAULT null,
  product_description TEXT
)
```

### 4. Variations Location Details Table

Stores stock quantities per location for each variation.

```sql
CREATE TABLE variations_location_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER,
  variation_id INTEGER,
  location_id INTEGER,
  qty_available REAL
)
```

### 5. Product Locations Table

Maps products to available locations.

```sql
CREATE TABLE product_locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER,
  location_id INTEGER
)
```

### 6. Sell Table

Stores sales/transactions (local and synced).

```sql
CREATE TABLE sell (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_date TEXT,
  invoice_no TEXT,
  contact_id INTEGER,
  location_id INTEGER,
  status TEXT,
  tax_rate_id INTEGER,
  discount_amount REAL,
  discount_type TEXT,
  sale_note TEXT,
  staff_note TEXT,
  shipping_details TEXT,
  shipping_address TEXT,
  shipping_status TEXT,
  delivered_to TEXT,
  is_quotation INTEGER DEFAULT 0,
  is_suspend INTEGER DEFAULT 0,
  shipping_charges REAL DEFAULT 0.00,
  invoice_amount REAL,
  change_return REAL DEFAULT 0.00,
  pending_amount REAL DEFAULT 0.00,
  is_synced INTEGER,
  transaction_id INTEGER DEFAULT null,
  invoice_url TEXT DEFAULT null
)
```

**Status Values:**
- `final` - Completed sale
- `draft` - Draft sale
- `quotation` - Price quotation (is_quotation = 1)
- `suspend` - Suspended sale (is_suspend = 1)

### 7. Sell Lines Table

Stores line items for each sale.

```sql
CREATE TABLE sell_lines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sell_id INTEGER,
  product_id INTEGER,
  variation_id INTEGER,
  quantity REAL,
  unit_price REAL,
  tax_rate_id INTEGER,
  discount_amount REAL DEFAULT 0.0,
  discount_type TEXT DEFAULT 'fixed',
  note TEXT,
  is_completed INTEGER
)
```

**Foreign Key:** `sell_id` references `sell(id)`

### 8. Sell Payments Table

Stores payment transactions for each sale.

```sql
CREATE TABLE sell_payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sell_id INTEGER,
  payment_id INTEGER DEFAULT null,
  method TEXT,
  amount REAL,
  note TEXT,
  account_id INTEGER DEFAULT null,
  is_return INTEGER DEFAULT 0,
  card_number TEXT,
  card_type TEXT,
  card_holder_name TEXT,
  transaction_date TEXT
)
```

**Foreign Key:** `sell_id` references `sell(id)`

**Payment Methods:**
- `cash`
- `card`
- `cheque`
- `bank_transfer`
- `advance`

## Entity Relationship Diagram

```
+------------+       +-------------+       +---------------+
|   system   |       |   contact   |       |  variations   |
+------------+       +-------------+       +---------------+
| id (PK)    |       | id (PK)     |       | id (PK)       |
| keyId      |       | name        |       | product_id    |
| key        |       | city        |       | variation_id  |
| value      |       | state       |       | display_name  |
+------------+       | country     |       | sku           |
                     | ...         |       | ...           |
                     +-------------+       +---------------+
                                                   |
                                                   | 1:N
                                                   v
                                   +---------------------------+
                                   | variations_location_details|
                                   +---------------------------+
                                   | id (PK)                   |
                                   | product_id                |
                                   | variation_id              |
                                   | location_id               |
                                   | qty_available             |
                                   +---------------------------+

+------------+       +---------------+       +----------------+
|    sell    |------>|  sell_lines   |       | sell_payments  |
+------------+  1:N  +---------------+  1:N  +----------------+
| id (PK)    |       | id (PK)       |<------| id (PK)        |
| contact_id |       | sell_id (FK)  |       | sell_id (FK)   |
| location_id|       | product_id    |       | method         |
| status     |       | variation_id  |       | amount         |
| ...        |       | quantity      |       | ...            |
+------------+       | unit_price    |       +----------------+
                     | ...           |
                     +---------------+
```

## Clean Architecture Data Layer

In the clean architecture implementation, database access is abstracted through:

### Data Sources

```
data/lib/src/data_source/local/
├── database/
│   └── database_helper.dart      # SQLite database management
├── auth_local_data_source.dart   # Auth token storage
└── product_local_data_source.dart # Product caching
```

### Usage Example

```dart
// Initialize database for user
await sl.get<DatabaseHelper>().initDatabase(userId);

// Get products from cache
final products = await productLocalDataSource.getProducts(
  locationId: 1,
  offset: 0,
  limit: 10,
  searchTerm: 'phone',
);

// Save products to cache
await productLocalDataSource.saveProducts(products, locationId);
```

## Migration History

| Version | Changes |
|---------|---------|
| 1 | Initial schema |
| 2 | Updated sell_lines structure |
| 3 | Updated variations structure |
| 4 | Added contact table |
| 5 | Added invoice_url to sell |
| 6 | Added account_id to sell_payments |
| 7 | Added shipping fields to sell |
| 8 | Added discount fields to sell_lines |
| 9 | Added card payment fields |
| 10 | Current version |

## Best Practices

1. **Always use transactions** for batch operations
2. **Use ConflictAlgorithm.replace** for upsert operations
3. **Index frequently queried columns** (variation_id, product_id, location_id)
4. **Clean up old data** periodically to prevent database bloat
5. **Sync with server** when online to keep data fresh

