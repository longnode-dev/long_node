# Page Type Inventory for "Stored" Sort Default

## Summary
The new "stored" sort should sort by: **timestamp (desc) → series → author → title**

This matches Calibre desktop's default sorting behavior.

---

## Page Types Analysis

### ✅ **SHOULD USE DEFAULT "STORED" SORT**

These pages join Series and would benefit from the new default sort:

1. **Root/Books** (`data="root"` or `data="newest"`)
   - **Current**: Falls into `else` branch, uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (lines 420-422)
   - **Recommendation**: ✅ **YES** - This is the main books listing page

2. **New Books** (`data="newbooks"` via URL parameter)
   - **Current**: Falls into `else` branch (treated as "newest"), uses stored preference or defaults to "new"
   - **Series Join**: ✅ Yes (lines 420-422)
   - **Note**: The `/new` route has its own hardcoded sort, but URL `?data=newbooks&sort_param=stored` uses the else branch
   - **Recommendation**: ✅ **YES** - Makes sense to sort new books consistently

3. **Top Rated** (`data="rated"`)
   - **Current**: Uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (lines 434-436)
   - **Recommendation**: ✅ **YES** - Users browsing top rated books would benefit from consistent sorting

4. **Downloaded** (`data="download"`)
   - **Current**: Uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (lines 505-507)
   - **Recommendation**: ✅ **YES** - Downloaded books should be sortable by the standard order

5. **Read Books** (`data="read"`)
   - **Current**: Uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (lines 764-766)
   - **Recommendation**: ✅ **YES** - Makes sense for read books

6. **Unread Books** (`data="unread"`)
   - **Current**: Uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (lines 764-766)
   - **Recommendation**: ✅ **YES** - Makes sense for unread books

7. **Search** (`data="search"`)
   - **Current**: Uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (line 407 in search.py)
   - **Recommendation**: ✅ **YES** - Search results should use consistent sorting

8. **Advanced Search** (`data="advsearch"`)
   - **Current**: Uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (lines 250-251 in search.py)
   - **Recommendation**: ✅ **YES** - Advanced search results should use consistent sorting

9. **Read Next** (redirects to `data="category"` with read next tag)
   - **Current**: Uses stored preference or defaults to "new" (timestamp desc only)
   - **Series Join**: ✅ Yes (lines 684-686, 697-699)
   - **Recommendation**: ✅ **YES** - Read Next is a category view, should use consistent sorting

---

### ⚠️ **ALREADY HAVE CUSTOM SORT LOGIC**

These pages join Series but have their own multi-level sorting that may conflict:

10. **Author** (`data="author"`)
    - **Current**: Already sorts by `[order[0][0], db.Series.name, db.Books.series_index]` (line 529)
    - **Series Join**: ✅ Yes (lines 531-533)
    - **Recommendation**: ⚠️ **MAYBE** - Currently sorts by user's chosen order, then series, then series_index. The new sort would add timestamp first. This might make sense, but could also be confusing since you're already filtering by author.

11. **Publisher** (`data="publisher"`)
    - **Current**: Already sorts by `[db.Series.name, order[0][0], db.Books.series_index]` (lines 560, 576)
    - **Series Join**: ✅ Yes (lines 565-567, 579-581)
    - **Recommendation**: ⚠️ **MAYBE** - Currently sorts by series first, then user's chosen order. Adding timestamp first would change the behavior significantly.

12. **Category** (`data="category"`)
    - **Current**: Already sorts by `[order[0][0], db.Series.name, db.Books.series_index]` (lines 679, 694-695)
    - **Series Join**: ✅ Yes (lines 684-686, 697-699)
    - **Recommendation**: ⚠️ **MAYBE** - Currently sorts by user's chosen order, then series, then series_index. Adding timestamp first would change behavior. However, for "Read Next" (which is a category), this might make sense.

---

### ❌ **SHOULD NOT USE DEFAULT "STORED" SORT**

These pages either don't join Series or have specific sorting requirements:

13. **Series** (`data="series"`)
    - **Current**: Uses stored preference or defaults to "new"
    - **Series Join**: ✅ Yes (but this is a series-specific view)
    - **Recommendation**: ❌ **NO** - When viewing books in a specific series, sorting by series name doesn't make sense (they're all the same series). Should probably sort by series_index or user preference.

14. **Ratings** (`data="ratings"`)
    - **Current**: Uses stored preference or defaults to "new"
    - **Series Join**: ❌ No (lines 626-628, 636)
    - **Recommendation**: ❌ **NO** - Doesn't join Series, would need code changes

15. **Formats** (`data="formats"`)
    - **Current**: Uses stored preference or defaults to "new"
    - **Series Join**: ❌ No (lines 653, 663)
    - **Recommendation**: ❌ **NO** - Doesn't join Series, would need code changes

16. **Language** (`data="language"`)
    - **Current**: Uses stored preference or defaults to "new"
    - **Series Join**: ❌ No (lines 723-725, 730)
    - **Recommendation**: ❌ **NO** - Doesn't join Series, would need code changes

17. **Archived** (`data="archived"`)
    - **Current**: Uses stored preference or defaults to "new"
    - **Series Join**: ❌ No (lines 791-796)
    - **Recommendation**: ❌ **NO** - Doesn't join Series, would need code changes

18. **Hot Books** (`data="hot"`)
    - **Current**: Forces sort by download count (`hotdesc` or `hotasc`)
    - **Series Join**: ❌ No
    - **Recommendation**: ❌ **NO** - Has specific sorting requirement (download count)

19. **Discover** (`data="discover"`)
    - **Current**: Uses random sort
    - **Series Join**: ❌ No
    - **Recommendation**: ❌ **NO** - Random sorting is intentional

---

## Implementation Recommendations

### **Phase 1: Core Pages (High Priority)**
Apply default "stored" sort to:
- ✅ Root/Books (`newest`)
- ✅ New Books (`newbooks` via URL)
- ✅ Top Rated (`rated`)
- ✅ Downloaded (`download`)
- ✅ Read Books (`read`)
- ✅ Unread Books (`unread`)
- ✅ Search (`search`)
- ✅ Advanced Search (`advsearch`)

### **Phase 2: Category Views (Medium Priority)**
Consider applying to:
- ⚠️ Category (`category`) - But note it already has custom sort logic
- ⚠️ Read Next - This is a category, so same consideration

### **Phase 3: Author/Publisher (Low Priority - Needs Discussion)**
These already have multi-level sorting. Adding timestamp first would change behavior:
- ⚠️ Author (`author`) - Currently: [user_order, series, series_index]
- ⚠️ Publisher (`publisher`) - Currently: [series, user_order, series_index]

### **Exclude**
- ❌ Series (doesn't make sense - all books are same series)
- ❌ Ratings, Formats, Language, Archived (don't join Series)
- ❌ Hot Books (has specific sort requirement)
- ❌ Discover (random is intentional)

---

## Technical Notes

- The default sort order should be: `[db.Books.timestamp.desc(), db.Series.name, db.Books.author_sort, db.Books.sort]`
- This requires Series to be joined (which most views already do)
- The change should only apply when `sort_param='stored'` AND no stored user preference exists
- If a user has a stored preference, that should still take precedence
