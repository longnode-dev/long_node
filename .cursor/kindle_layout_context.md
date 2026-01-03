# Kindle Layout Context for Long Node Theme

## Problem Summary
Mobile (iPhone) improvements made today broke Kindle Paperwhite display. Need to fix Kindle without regressing mobile.

## Kindle Experimental Browser Behavior
- **Does NOT reliably evaluate CSS media queries** - rules inside `@media` may be ignored
- **Does evaluate JavaScript** - search toggle, hamburger click work fine
- **Viewport**: ~600-700px CSS pixels (exact unknown)
- **Book detail page works perfectly** - hamburger collapsed, sidebar hidden, proper layout

## What Works on Kindle (from 10-day-old Synology build)
1. **3 columns of books** with correct aspect ratios
2. **Hamburger menu** collapsed by default, expands on click
3. **Sidebar items** accessible via hamburger menu
4. Book covers NOT stretched or distorted

## What's Currently Broken on Kindle
1. Only showing **2 columns** instead of 3
2. OR showing 3 columns but **images stretched thin** (aspect ratio broken)

## Key CSS Files
- `cps/static/css/longnode.css` - Long Node theme styles
- `cps/static/css/style.css` - Base styles (`.row.display-flex` defined here)

## Book Grid HTML Structure
```html
<div class="row display-flex">
  <div class="col-sm-3 col-lg-2 col-xs-6 book session">
    <!-- book content -->
  </div>
</div>
```
- `col-xs-6` = 50% width (<768px) = 2 columns
- `col-sm-3` = 25% width (≥768px) = 4 columns
- `col-lg-2` = 16.67% width (≥1200px) = 6 columns

## Key CSS Rules Added Today (Kindle-compatible = no media query)

### Sidebar Hiding (WORKS - keep this)
```css
body.longnode:not(.book) .container-fluid > .row-fluid > .col-sm-2 {
    display: none;
}
```

### Navbar-collapse Hiding (WORKS - keep this)
```css
body.longnode:not(.book) .navbar-collapse.collapse {
    display: none !important;
}
body.longnode:not(.book) .navbar-collapse.collapse.in {
    display: block !important;
}
```

### Content Full-Width (WORKS - keep this)
```css
body.longnode:not(.book) .container-fluid > .row-fluid > .col-sm-10 {
    width: 100%;
}
```

## What NOT To Do (Causes Image Stretching)
```css
/* DO NOT force column widths like this - breaks aspect ratios */
body.longnode .container-fluid .book.col-xs-6 {
    width: 33.33333333%; /* BREAKS IMAGES */
}
```

## Isotope.js Interaction
- Isotope applies `position: absolute` to `.book` items for masonry layout
- Current override in longnode.css:
```css
body.longnode .container-fluid .book {
    position: relative !important;
    left: auto !important;
    top: auto !important;
}
```
- This override may affect how columns are calculated

## Investigation Needed
1. **Compare CSS from 10-day-old Synology build** to current
2. **Check if Isotope override** is causing the 2-column issue
3. **Understand why col-xs-6 (50%) applies** instead of col-sm-3 (25%) on Kindle
4. **Test removing Isotope override** on Kindle only

## Key Insight
The book detail page (`body.book.longnode`) works perfectly on Kindle because it has explicit CSS rules WITHOUT media queries that:
1. Hide sidebar
2. Hide navbar-collapse by default
3. Show hamburger always

The same approach was applied to list pages today, but something about the book grid is different.

## Files Changed Today
- `cps/static/css/longnode.css` - Mobile spacing, Kindle sidebar/collapse fixes
- `cps/static/js/longnode.js` - Sidebar cloning into hamburger menu
- `cps/templates/layout.html` - Search toggle button

## Synology Production
- 10-day-old build works correctly on Kindle
- Compare `git diff HEAD~20 -- cps/static/css/longnode.css` to find what changed

