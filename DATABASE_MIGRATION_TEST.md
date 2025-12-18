# Database Migration Test Guide

## Testing Database Version 11 Migration

### Pre-Migration Check (Optional)

If you want to see the before/after, run these queries before updating:

```sql
-- Count records in system table
SELECT key, keyId, COUNT(*) as count 
FROM system 
GROUP BY key, keyId 
HAVING count > 1;

-- Count duplicate variations
SELECT product_id, variation_id, COUNT(*) as count 
FROM variations 
GROUP BY product_id, variation_id 
HAVING count > 1;

-- Count duplicate stock records
SELECT product_id, variation_id, location_id, COUNT(*) as count 
FROM variations_location_details 
GROUP BY product_id, variation_id, location_id 
HAVING count > 1;
```

### Migration Test Steps

1. **Update the App**
   - Build and install the updated version
   - Launch the app

2. **Check Migration Success**
   - Look for this log message:
     ```
     ✅ Database migrated to version 11: Unique constraints added, duplicates cleaned, indexes created
     ```

3. **Verify No Duplicates**
   ```sql
   -- Should return 0 rows (no duplicates)
   SELECT key, keyId, COUNT(*) as count 
   FROM system 
   GROUP BY key, keyId 
   HAVING count > 1;
   
   -- Should return 0 rows (no duplicate products)
   SELECT product_id, variation_id, COUNT(*) as count 
   FROM variations 
   GROUP BY product_id, variation_id 
   HAVING count > 1;
   
   -- Should return 0 rows (no duplicate stock)
   SELECT product_id, variation_id, location_id, COUNT(*) as count 
   FROM variations_location_details 
   GROUP BY product_id, variation_id, location_id 
   HAVING count > 1;
   ```

4. **Test Sync Behavior**
   - Trigger a full sync (logout/login)
   - Sync again 2-3 more times
   - Run the duplicate check queries again
   - **Expected Result**: Still 0 duplicates

5. **Test Product Operations**
   - Add products to cart
   - Check stock validation works correctly
   - Complete a sale
   - Verify stock deducted correctly

6. **Test Layout Bill Caching**
   ```sql
   -- Should return exactly 1 row per location
   SELECT keyId as location_id, COUNT(*) as count 
   FROM system 
   WHERE key = 'layout_bill' 
   GROUP BY keyId;
   ```

### Performance Test

Before (with duplicates):
```sql
-- Time this query
EXPLAIN QUERY PLAN SELECT * FROM variations WHERE product_id = 1 AND variation_id = 1;
```

After (with unique constraints and indexes):
```sql
-- Should show "USING INDEX idx_variations_product_variation"
EXPLAIN QUERY PLAN SELECT * FROM variations WHERE product_id = 1 AND variation_id = 1;
```

### Rollback Plan (Emergency)

If migration fails catastrophically:

1. Uninstall the app
2. Reinstall previous version
3. Database will be at version 10
4. Report the error logs

### Expected Database State After Migration

| Table | Unique Constraint | Index |
|-------|------------------|-------|
| system | ✅ (key, keyId) | ✅ idx_system_key_keyId |
| variations | ✅ (product_id, variation_id) | ✅ idx_variations_product_variation |
| variations_location_details | ✅ (product_id, variation_id, location_id) | ✅ idx_variation_location |
| product_locations | ✅ (product_id, location_id) | ✅ idx_product_locations |
| contact | ✅ PRIMARY KEY (no autoincrement) | ✅ idx_contact_id |
| sell_payments | ✅ (sell_id, payment_id) | ✅ idx_sell_payments_sell_id |

### Common Issues and Solutions

**Issue**: App crashes on launch after update
- **Cause**: Migration failed due to corrupted data
- **Solution**: Check logs for specific SQL error, may need to clear app data and re-sync

**Issue**: Still seeing duplicates after migration
- **Cause**: Migration didn't run (app didn't restart properly)
- **Solution**: Force close app completely and relaunch

**Issue**: "UNIQUE constraint failed" error
- **Cause**: Trying to insert duplicate that violates new constraint
- **Solution**: This is expected behavior! The app should handle this gracefully with ConflictAlgorithm.replace

### Success Criteria

✅ No duplicates in any table
✅ Sync doesn't create new duplicates
✅ Queries use indexes (check with EXPLAIN QUERY PLAN)
✅ Stock validation works correctly
✅ App performance improved
✅ Database size stable after multiple syncs

### Database Size Check

Before migration:
```sql
-- Note this number
SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size();
```

After migration (after deleting duplicates):
```sql
-- Should be smaller
SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size();
```

After 5 syncs:
```sql
-- Should be approximately the same as "After migration"
SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size();
```

### Reporting

If migration successful:
- ✅ No action needed

If migration fails:
- 📝 Collect device logs
- 📝 Note the error message
- 📝 Record database version before/after
- 📝 Share reproduction steps

---

## Automated Test Script

You can also run this Dart test:

```dart
void testDatabaseMigration() async {
  final db = await DatabaseHelper.instance.database;
  
  // Test 1: Check version
  final version = await db.getVersion();
  assert(version == 11, 'Database should be version 11');
  
  // Test 2: Check for duplicates in system table
  final systemDuplicates = await db.rawQuery('''
    SELECT key, keyId, COUNT(*) as count 
    FROM system 
    GROUP BY key, keyId 
    HAVING count > 1
  ''');
  assert(systemDuplicates.isEmpty, 'No duplicates should exist in system table');
  
  // Test 3: Check for duplicates in variations
  final variationDuplicates = await db.rawQuery('''
    SELECT product_id, variation_id, COUNT(*) as count 
    FROM variations 
    GROUP BY product_id, variation_id 
    HAVING count > 1
  ''');
  assert(variationDuplicates.isEmpty, 'No duplicates should exist in variations table');
  
  // Test 4: Verify indexes exist
  final indexes = await db.rawQuery('''
    SELECT name FROM sqlite_master 
    WHERE type='index' AND name LIKE 'idx_%'
  ''');
  assert(indexes.length >= 9, 'All indexes should be created');
  
  print('✅ All database migration tests passed!');
}
```

