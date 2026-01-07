# MuttPU Tests

This directory contains unit and integration tests for MuttPU.

## Test Files

- `test_muttpu.py` - Unit tests for Python script functionality
- `integration_test.sh` - Integration tests for the complete app
- `README.md` - This file

## Running Tests

### All Tests

Run all tests using the test script:

```bash
./scripts/test.sh
```

### Unit Tests Only

Run Python unit tests:

```bash
python3 tests/test_muttpu.py
```

### Integration Tests Only

Run integration tests:

```bash
bash tests/integration_test.sh
```

## Test Coverage

### Unit Tests (`test_muttpu.py`)

- Filename sanitization
- Email date parsing
- Export state tracking (JSON)
- Color code definitions
- Year-based search formatting
- Configuration directory structure
- Script existence and permissions

### Integration Tests (`integration_test.sh`)

- Script executable permissions
- Help command functionality
- Interactive menu display
- Dependency checking
- App bundle structure validation
- Python script bundling
- Build script permissions
- Test directory structure

## Adding New Tests

### Adding Unit Tests

Add new test cases to `test_muttpu.py`:

```python
class TestMyFeature(unittest.TestCase):
    def test_my_feature(self):
        # Your test code here
        self.assertTrue(True)
```

### Adding Integration Tests

Add new test cases to `integration_test.sh`:

```bash
echo ""
echo "Test N: My new test"
if [ condition ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi
```

## Test Requirements

- Python 3.x
- Bash shell
- Standard Unix utilities (grep, chmod, etc.)

## CI/CD Integration

These tests are designed to run in CI/CD pipelines. Exit codes:
- `0` - All tests passed
- `1` - One or more tests failed

## Notes

- Unit tests do not require M365 credentials
- Integration tests do not require a built app (tests are skipped if not present)
- Tests are designed to be safe and non-destructive
- No actual email operations are performed in tests
