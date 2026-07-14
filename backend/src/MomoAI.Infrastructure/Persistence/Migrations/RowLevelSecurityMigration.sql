-- Row-Level Security (RLS) for memories table
-- Ensures each user can only access their own memories at the database level.
-- Satisfies requirement 13.3.
--
-- USAGE: Run this migration against PostgreSQL after the memories table exists.
-- The application must set the session variable 'app.current_user_id' before querying.

-- Step 1: Enable Row-Level Security on the memories table
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;

-- Step 2: Force RLS even for table owners (prevents bypass)
ALTER TABLE memories FORCE ROW LEVEL SECURITY;

-- Step 3: Create policy that restricts SELECT to rows matching the current user
CREATE POLICY memory_select_policy ON memories
    FOR SELECT
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

-- Step 4: Create policy that restricts INSERT to rows matching the current user
CREATE POLICY memory_insert_policy ON memories
    FOR INSERT
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

-- Step 5: Create policy that restricts UPDATE to rows matching the current user
CREATE POLICY memory_update_policy ON memories
    FOR UPDATE
    USING (user_id = current_setting('app.current_user_id', true)::uuid)
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

-- Step 6: Create policy that restricts DELETE to rows matching the current user
CREATE POLICY memory_delete_policy ON memories
    FOR DELETE
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

-- Step 7: Create an application-level role (if not using Supabase's built-in roles)
-- This ensures the app connects with a role that respects RLS.
-- Note: If using Supabase, the 'authenticated' role already respects RLS policies.
-- 
-- DO NOT FORGET: Grant appropriate permissions to your app's database role:
-- GRANT SELECT, INSERT, UPDATE, DELETE ON memories TO momo_app;
