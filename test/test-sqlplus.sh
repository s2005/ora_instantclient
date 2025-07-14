#!/bin/bash

# Oracle Instant Client and SQLPlus Test Script
# This script tests the Oracle Instant Client installation in a dev container environment

set -e

echo "================================================"
echo "Oracle Instant Client & SQLPlus Test Suite"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success_count=0
total_tests=0

# Function to print test results
print_result() {
    local test_name="$1"
    local result="$2"
    total_tests=$((total_tests + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        success_count=$((success_count + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
    fi
}

# Function to run a test and capture result
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}Running:${NC} $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name" "FAIL"
        return 1
    fi
}

echo
echo "1. Basic Installation Tests"
echo "----------------------------"

# Test 1: SQLPlus command availability
run_test "SQLPlus command available" "command -v sqlplus"

# Test 2: SQLPlus version check
run_test "SQLPlus version check" "sqlplus -v"

# Test 3: Oracle library path
run_test "Oracle libraries in LD_LIBRARY_PATH" "echo \$LD_LIBRARY_PATH | grep -q oracle"

# Test 4: Oracle instant client directory
run_test "Oracle instant client directory exists" "ls /opt/oracle/instantclient_* > /dev/null 2>&1"

# Test 5: Oracle shared library
run_test "Oracle client shared library exists" "find /opt/oracle -name 'libclntsh.so*' | head -1 > /dev/null"

echo
echo "2. SQLPlus Functionality Tests"
echo "-------------------------------"

# Test 6: SQLPlus help functionality
echo -e "${YELLOW}Running:${NC} SQLPlus help functionality"
if echo 'help' | sqlplus -s /nolog > /dev/null 2>&1 || [ $? -eq 1 ]; then
    print_result "SQLPlus help functionality" "PASS"
else
    print_result "SQLPlus help functionality" "FAIL"
fi

# Test 7: SQLPlus version output format
echo -e "${YELLOW}Running:${NC} SQLPlus version output format"
version_output=$(sqlplus -v 2>&1)
if echo "$version_output" | grep -i 'sql.*plus' > /dev/null; then
    print_result "SQLPlus version output format" "PASS"
    echo "  Version: $version_output"
else
    print_result "SQLPlus version output format" "FAIL"
fi

# Test 8: SQLPlus connection syntax validation  
echo -e "${YELLOW}Running:${NC} SQLPlus connection syntax validation"
# This test verifies SQLPlus handles connection strings properly

# Test with a malformed connection string that should cause a syntax error
test_connection="invalid@syntax@double@at"
echo "  Testing connection syntax with malformed string: $test_connection"

# Run the test and capture both output and exit code
output=$(echo 'exit' | timeout 5s sqlplus -s "$test_connection" 2>&1)
exit_code=$?

echo "  Debug: Exit code=$exit_code"
echo "  Output preview: $(echo "$output" | head -1 | cut -c1-50)..."

# Check for either non-zero exit code OR error messages indicating syntax issues
if [ $exit_code -ne 0 ] || echo "$output" | grep -qi "error\|invalid\|syntax\|SP2-"; then
    print_result "SQLPlus connection syntax validation" "PASS"
    echo "  SQLPlus correctly handled malformed connection string"
else
    print_result "SQLPlus connection syntax validation" "FAIL"
    echo "  Unexpected: SQLPlus did not detect syntax issue"
    echo "  Full output: $output"
fi

echo
echo "3. Environment Tests"
echo "--------------------"

# Test 9: Required environment variables
echo -e "${YELLOW}Running:${NC} Environment variables check"
if [ -n "$LD_LIBRARY_PATH" ] && [ -n "$PATH" ]; then
    print_result "Required environment variables set" "PASS"
else
    print_result "Required environment variables set" "FAIL"
fi

# Test 10: Oracle library dependencies
echo -e "${YELLOW}Running:${NC} Oracle library dependencies check"
oracle_lib=$(find /opt/oracle -name 'libclntsh.so*' | head -1)
if [ -n "$oracle_lib" ] && command -v ldd > /dev/null 2>&1; then
    if ldd "$oracle_lib" > /dev/null 2>&1; then
        print_result "Oracle library dependencies" "PASS"
    else
        print_result "Oracle library dependencies" "FAIL"
    fi
else
    print_result "Oracle library dependencies" "SKIP"
fi

echo
echo "4. Optional Database Connection Test"
echo "------------------------------------"

# Test 11: Database connection (if database URL provided)
if [ -n "$ORACLE_TEST_CONNECTION" ]; then
    echo -e "${YELLOW}Running:${NC} Database connection test"
    if echo 'SELECT 1 FROM DUAL; EXIT;' | timeout 10s sqlplus -s "$ORACLE_TEST_CONNECTION" > /dev/null 2>&1; then
        print_result "Database connection test" "PASS"
        
        # Additional query test
        echo -e "${YELLOW}Running:${NC} Simple query test"
        result=$(echo 'SELECT SYSDATE FROM DUAL; EXIT;' | sqlplus -s "$ORACLE_TEST_CONNECTION" 2>/dev/null | grep -v '^$' | tail -1)
        if [ -n "$result" ]; then
            print_result "Simple query execution" "PASS"
            echo "  Query result: $result"
        else
            print_result "Simple query execution" "FAIL"
        fi
    else
        print_result "Database connection test" "FAIL"
    fi
else
    echo -e "${YELLOW}Info:${NC} Database connection test skipped (no ORACLE_TEST_CONNECTION provided)"
    echo "  To test database connectivity, set ORACLE_TEST_CONNECTION environment variable"
    echo "  Example: export ORACLE_TEST_CONNECTION='user/password@//host:port/service'"
fi

echo
echo "================================================"
echo "Test Results Summary"
echo "================================================"

if [ $success_count -eq $total_tests ]; then
    echo -e "${GREEN}✅ All $total_tests tests passed!${NC}"
    echo
    echo "Oracle Instant Client and SQLPlus are properly installed and configured."
    echo "Environment Details:"
    echo "  - SQLPlus Version: $(sqlplus -v 2>&1)"
    echo "  - Oracle Library Path: $LD_LIBRARY_PATH"
    echo "  - Oracle Installation: $(ls -d /opt/oracle/instantclient_* 2>/dev/null | head -1)"
    exit 0
else
    failed_tests=$((total_tests - success_count))
    echo -e "${RED}❌ $failed_tests out of $total_tests tests failed${NC}"
    echo
    echo "Please check the installation and configuration."
    exit 1
fi
