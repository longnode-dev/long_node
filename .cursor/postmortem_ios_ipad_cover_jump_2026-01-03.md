# Postmortem: iOS/iPad/Desktop "book covers jump" regression (Long Node theme)

Date: 2026-01-03  
Scope: Long Node Theme (theme 2) multi-book list pages (All Books / New Books / Search / Shelf / Author grids)

## Summary
Book covers would visibly "fly" or "jump" and then snap back during:
- iPhone/iPad: scrolling
- Desktop: window resize
- iPad: rotation (portrait ↔ landscape)
- iPad: browser back navigation from book detail

Root cause was **Isotope + Flexbox conflict**. Fixed by completely disabling Isotope for Long Node theme.

---

## What we were trying to achieve (intended changes)
The original request was intentionally small:
- **iPhone**: make the 2-column book grid feel symmetrical/centered.
- **Kindle**: avoid auto-expanding the sidebar; keep navigation behind the hamburger.

These were Long Node (theme 2) UX adjustments and were not meant to alter core grid layout behavior.

---

## What regressed (symptoms)
1. **iOS scroll**: every scroll up/down triggered visible reflow
2. **Desktop resize**: dragging window edge caused covers to fly around
3. **iPad rotation**: portrait ↔ landscape caused flying covers
4. **iPad back navigation**: returning from book detail caused flying covers
5. **Sidebar duplication**: sidebar items appeared both in left sidebar AND top navbar

---

## Root cause: Isotope + Flexbox conflict

### What is Isotope?
**Isotope** is a JavaScript library (part of upstream Calibre-Web) that provides masonry/grid layouts:
- Takes absolute control of item positioning using CSS `transform: translate(x, y)`
- Recalculates and animates positions on resize, filter, sort, append, etc.
- Used for masonry layout, filtering by letter, sorting animations, infinite scroll integration

### Why it conflicted with Long Node
**Long Node's CSS** uses **flexbox** (`.row.display-flex`) for responsive grid layout:
- Controls item positioning via normal document flow + flex rules
- Naturally handles responsive column changes via CSS breakpoints (`col-xs-6`, `col-sm-3`, etc.)
- Doesn't need JavaScript for resize/layout

**The conflict**: When Isotope called `isotope("layout")`:
1. Isotope calculated new positions
2. Applied `transform` to move items to those positions
3. But flexbox was *also* positioning items via CSS
4. Result: items would visually "fly" to Isotope's calculated position, then "snap back" to where flexbox wanted them

### Why it surfaced now
The Isotope-on-resize behavior already existed, but Long Node's recent layout adjustments (removing nested scroll containers, switching to page-level scroll) increased exposure to:
- iOS dynamic viewport behavior (resize events during scroll)
- Normal desktop/iPad resize and rotation events

Small changes to scroll containers/layout primitives activated hidden coupling with global Isotope handlers.

---

## The fix: Disable Isotope for Long Node

In `cps/static/js/main.js`, we added guards to skip Isotope entirely for Long Node (theme 2):

```javascript
// Isotope initialization - skip for Long Node
if (!$("body").hasClass("longnode")) {
    $(".discover .row").isotope({...});
}

// Isotope append (infinite scroll) - skip for Long Node
if (!$("body").hasClass("longnode")) {
    $(".load-more .row").isotope("appended", $(data), null);
}

// Isotope resize handler - skip for Long Node
if (!$("body").hasClass("longnode")) {
    $(window).resize(function() {
        $(".discover .row").isotope("layout");
    });
}
```

**Why this works**: Flexbox handles responsive layout natively without JavaScript. No Isotope = no transform conflicts = no flying covers.

**Themes 0 and 1**: Keep Isotope (they don't use flexbox for the grid).

---

## Additional fix: Sidebar duplication

The `longnode.js` clones sidebar items into the hamburger menu for mobile/Kindle. On desktop, both were visible.

Fix: Added CSS to hide cloned items on desktop:
```css
@media (min-width: 768px) {
    body.longnode:not(.book) .navbar-collapse .longnode-sidebar-clone {
        display: none !important;
    }
}
```

---

## Verification
- User verified on real **iPhone + iPad**: scrolling smooth, no jumping
- User verified on **desktop**: resize instant, no flying covers
- User verified on **iPad**: rotation and back navigation instant, no flying
- Sidebar duplication resolved

## Key lesson: Isotope is disabled for Long Node

**Long Node uses flexbox for grid layout. Isotope is completely disabled for theme 2.**

Before touching layout-related CSS/JS for Long Node:
- Know that Isotope exists in main.js but is guarded by `!$("body").hasClass("longnode")`
- If you see `isotope()` calls, don't add more for Long Node
- Flexbox handles responsive layout natively; no JS layout library needed

---

## Long Node UI change checklist (to prevent future regressions + token burn)
Use this for any theme-2 UI tweak, especially anything involving layout/scroll:

### 1) Scope + blast radius
- Confirm: **theme 2 only** (`body.longnode` or `g.current_theme == 2`).
- Name the target pages explicitly (e.g., Search + All Books only).
- If a change touches shared JS/CSS used by other themes, stop and confirm.

### 2) Identify the layout engine(s) before editing
- Long Node uses **flexbox** (`.row.display-flex`) — no JS layout library.
- Isotope is **disabled** for Long Node; don't re-enable it.
- If you see resize/scroll handlers in main.js, check if they're guarded for Long Node.

### 3) Make the smallest possible diff
- One concept per change (e.g., "center grid on iPhone" only).
- Review `git diff` after each micro-change; avoid "drive-by" edits.

### 4) Run the fixed test matrix (fast + consistent)
- Desktop: resize width + refresh.
- iPhone emulation: scroll list page.
- iPad emulation: scroll + rotate + back navigation.
- Kindle sanity: confirm hamburger/sidebar behavior on list pages.

### 5) When a regression appears: confirm-first debugging
- Instrument with DevTools (events + layout triggers) before changing code.
- Prefer narrow guards over broad layout refactors.
- Check for JS libraries (Isotope, masonry, etc.) that might conflict with CSS layout.


