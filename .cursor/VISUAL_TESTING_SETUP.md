# Visual Regression Testing Setup - Complete Guide

## What Was Set Up

I've created a complete visual regression testing system for your Calibre-Web project using **Playwright** and **pytest**. This system allows you to:

✅ **Capture screenshots** of pages and components  
✅ **Compare** current visuals against baseline images  
✅ **Detect visual regressions** automatically  
✅ **Review differences** through diff images  
✅ **Point out visual changes** by sharing screenshots and diffs  

## Files Created

```
test/playwright/
├── __init__.py                    # Package marker
├── conftest.py                    # Pytest fixtures (auth, browser config)
├── test_pages.py                  # Full page visual tests
├── test_components.py             # Component-level visual tests
├── capture_baselines.py           # Script to capture baseline screenshots
├── run_tests.ps1                  # PowerShell helper script
├── view_diffs.ps1                 # PowerShell script to view results
├── pytest.ini                     # Pytest configuration
├── README.md                      # Detailed documentation
├── QUICKSTART.md                  # Quick reference guide
└── CURSOR_INTEGRATION.md          # Guide for using with Cursor

.cursor/test-requirements.txt      # Test dependencies
```

## Quick Start

### 1. Install Dependencies

```powershell
pip install -r .cursor/test-requirements.txt
playwright install chromium
```

### 2. Start Calibre-Web

```powershell
venv\Scripts\python.exe cps.py
```

### 3. Capture Initial Baselines

```powershell
python tests\visual\capture_baselines.py
```

This creates baseline images in `test/playwright/baselines/` representing your current "known good" state.

### 4. Run Tests

```powershell
# Simple
pytest test\playwright\ -v

# Or use helper script
.\test\playwright\run_tests.ps1

# With HTML report
.\test\playwright\run_tests.ps1 -Report
```

## Workflow for Visual Changes

### Making Changes

1. **Edit** your UI files (templates, CSS, JS)
2. **Run tests:**
   ```powershell
   pytest test\playwright\ -v
   ```
3. **Review results:**
   - If tests pass: ✓ No visual regressions
   - If tests fail: Check `test/playwright/screenshots/diffs/` for visual differences

### After Intentional Changes

When you make intentional visual improvements:

```powershell
.\test\playwright\run_tests.ps1 -UpdateBaselines
```

This updates the baseline images to match your new design.

## Viewing Results in Cursor

### Option 1: Direct File Viewing

1. Navigate to `test/playwright/screenshots/diffs/` in Cursor's file explorer
2. Cursor can display PNG images inline
3. Compare baseline vs current screenshots side-by-side

### Option 2: Helper Script

```powershell
.\test\playwright\view_diffs.ps1
```

Opens Windows Explorer with diffs and shows a summary.

### Option 3: HTML Report

```powershell
pytest tests\visual\ --html=visual_report.html --self-contained-html
```

Open `visual_report.html` in your browser for detailed results.

## Pointing Out Visual Changes

When you need to point out visual changes:

1. **Run tests** to generate current screenshots
2. **Review diff images** - they highlight differences in red
3. **Share specific files:**
   - Diff images: `test/playwright/screenshots/diffs/diff_*.png`
   - Current screenshots: `test/playwright/screenshots/*.png`
   - Baseline screenshots: `test/playwright/baselines/*.png`

4. **Annotate if needed:**
   - Use image editing tools to add arrows/notes
   - Reference specific test cases in code reviews

## Customization

### Adding New Test Cases

Edit `test_pages.py` or `test_components.py`:

```python
def test_my_new_page(self, authenticated_page, screenshot_dir):
    """Test my new page."""
    authenticated_page.goto(f"{base_url}/my-new-page")
    authenticated_page.wait_for_load_state("networkidle")
    
    screenshot_path = os.path.join(screenshot_dir, "my_new_page.png")
    authenticated_page.screenshot(path=screenshot_path, full_page=True)
    
    baseline_path = os.path.join(
        os.path.dirname(screenshot_dir), "baselines", "my_new_page.png"
    )
    if os.path.exists(baseline_path):
        self._compare_screenshots(screenshot_path, baseline_path)
```

### Adjusting Sensitivity

Edit the `threshold` and `tolerance` in `_compare_screenshots` methods:

```python
num_diff_pixels = pixelmatch(
    current_img, baseline_img, diff_img,
    threshold=0.1,  # Lower = more strict
    includeAA=True
)

tolerance = int(total_pixels * 0.001)  # 0.1% tolerance
```

### Testing Different Viewports

Edit `conftest.py`:

```python
@pytest.fixture(scope="session")
def browser_context_args(browser_context_args):
    return {
        **browser_context_args,
        "viewport": {"width": 1280, "height": 720},  # Custom viewport
        "device_scale_factor": 1,
    }
```

## Integration with Cursor

See `tests/visual/CURSOR_INTEGRATION.md` for detailed instructions on:
- Setting up Cursor tasks
- Using Cursor's test runner
- Viewing results inline
- Creating watch scripts

## Troubleshooting

**"Calibre-Web is not running"**
- Start app: `venv\Scripts\python.exe cps.py`
- Check URL: Default is `http://localhost:8083`

**"Element not found"**
- Verify selectors match your UI structure
- Ensure you're using `authenticated_page` fixture for logged-in pages

**Too many false positives**
- Increase tolerance in comparison methods
- Use Playwright's `mask` option to ignore dynamic elements
- Adjust threshold parameter

**Tests are slow**
- Run specific tests: `pytest tests/visual/test_pages.py::TestMainPages::test_home_page`
- Use `pytest-xdist` for parallel execution

## Next Steps

1. **Read the guides:**
   - `test/playwright/README.md` - Full documentation
   - `test/playwright/QUICKSTART.md` - Quick reference
   - `test/playwright/CURSOR_INTEGRATION.md` - Cursor-specific tips

2. **Customize tests** for your specific UI components

3. **Add to CI/CD** for automated visual regression detection

4. **Expand coverage** - Add tests for mobile views, different themes, etc.

## Benefits

- ✅ **Catch visual bugs** before they reach production
- ✅ **Document visual changes** through screenshots
- ✅ **Regression testing** ensures UI consistency
- ✅ **Easy collaboration** - share screenshots to point out changes
- ✅ **Automated validation** in CI/CD pipelines

---

**Ready to start?** Run `python test\playwright\capture_baselines.py` to create your first baseline images!
