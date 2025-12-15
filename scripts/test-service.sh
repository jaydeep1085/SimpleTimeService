#!/bin/bash
# Integration test suite for SimpleTimeService

set -e

BASE_URL="http://localhost:5000"
TESTS_PASSED=0
TESTS_FAILED=0

echo "==============================================="
echo "SimpleTimeService Integration Tests"
echo "==============================================="
echo ""

# Test 1: Main endpoint returns 200 OK
echo "Test 1: Main endpoint responds with 200 OK"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PASS: HTTP 200"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Expected 200, got $HTTP_CODE"
    ((TESTS_FAILED++))
fi

# Test 2: Response is valid JSON
echo ""
echo "Test 2: Response is valid JSON"
RESPONSE=$(curl -s "$BASE_URL/")
if echo "$RESPONSE" | python -m json.tool > /dev/null 2>&1; then
    echo "✅ PASS: Valid JSON response"
    echo "   Response: $RESPONSE"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Invalid JSON response"
    echo "   Response: $RESPONSE"
    ((TESTS_FAILED++))
fi

# Test 3: Response contains 'timestamp' field
echo ""
echo "Test 3: Response contains 'timestamp' field"
if echo "$RESPONSE" | grep -q "timestamp"; then
    echo "✅ PASS: 'timestamp' field present"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: 'timestamp' field missing"
    ((TESTS_FAILED++))
fi

# Test 4: Response contains 'ip' field
echo ""
echo "Test 4: Response contains 'ip' field"
if echo "$RESPONSE" | grep -q "ip"; then
    echo "✅ PASS: 'ip' field present"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: 'ip' field missing"
    ((TESTS_FAILED++))
fi

# Test 5: Timestamp is in ISO 8601 format
echo ""
echo "Test 5: Timestamp is in ISO 8601 format (ends with Z)"
TIMESTAMP=$(echo "$RESPONSE" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
if [[ "$TIMESTAMP" == *"Z" ]]; then
    echo "✅ PASS: ISO 8601 format"
    echo "   Timestamp: $TIMESTAMP"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Not in ISO 8601 format"
    echo "   Timestamp: $TIMESTAMP"
    ((TESTS_FAILED++))
fi

# Test 6: IP address is valid format
echo ""
echo "Test 6: IP address is in valid format"
IP=$(echo "$RESPONSE" | grep -o '"ip":"[^"]*"' | cut -d'"' -f4)
if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "✅ PASS: Valid IP format"
    echo "   IP: $IP"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Invalid IP format"
    echo "   IP: $IP"
    ((TESTS_FAILED++))
fi

# Test 7: Health endpoint responds with 200 OK
echo ""
echo "Test 7: Health endpoint responds with 200 OK"
HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
if [ "$HEALTH_CODE" = "200" ]; then
    echo "✅ PASS: Health endpoint HTTP 200"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Expected 200, got $HEALTH_CODE"
    ((TESTS_FAILED++))
fi

# Test 8: Health endpoint returns 'healthy' status
echo ""
echo "Test 8: Health endpoint returns 'healthy' status"
HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo "✅ PASS: Healthy status returned"
    echo "   Response: $HEALTH_RESPONSE"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Healthy status not found"
    echo "   Response: $HEALTH_RESPONSE"
    ((TESTS_FAILED++))
fi

# Test Summary
echo ""
echo "==============================================="
echo "Test Summary"
echo "==============================================="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
