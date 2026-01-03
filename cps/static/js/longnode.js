/* Long Node Theme - Custom JavaScript */
/* Theme-specific interactions and functionality */

(function() {
    'use strict';
    
    // Long Node Theme initialization
    console.log('Long Node Theme loaded');
    
    // Mobile search toggle functionality
    $(document).ready(function() {
        if ($('body').hasClass('longnode')) {
            var $searchToggle = $('#ln-search-toggle');
            var $searchForm = $('#ln-search-form');
            
            if ($searchToggle.length && $searchForm.length) {
                $searchToggle.on('click', function(e) {
                    e.preventDefault();
                    $searchToggle.toggleClass('active');
                    $searchForm.toggleClass('ln-search-expanded');
                    
                    // Focus input when expanding
                    if ($searchForm.hasClass('ln-search-expanded')) {
                        $searchForm.find('#query').focus();
                    }
                });
            }
        }
    });
    
    // For Long Node pages: Clone sidebar items into hamburger (for Kindle where Intention.js may not work)
    $(document).ready(function() {
        if ($('body').hasClass('longnode')) {
            function cloneSidebarToHamburger() {
                // Check if we already have a cloned sidebar (avoid duplicates)
                if ($('.navbar-collapse .longnode-sidebar-clone').length > 0) return;
                
                // Check if Intention.js has already moved items - if so, don't clone
                var intentionMoved = $('.navbar-collapse #scnd-nav').length > 0;
                if (intentionMoved) {
                    // Just clean up Intention.js items
                    var movedNav = $('.navbar-collapse #scnd-nav');
                    movedNav.find('.nav-head').hide();
                    movedNav.find('.create-shelf').hide();
                    movedNav.find('#nav_createshelf').hide();
                    movedNav.find('#nav_about').hide();
                    return;
                }
                
                // Check if sidebar items exist in their original location
                var sidebar = $('#scnd-nav');
                if (sidebar.length === 0) return;
                
                // Check if sidebar is in its original location (not moved by Intention.js)
                var sidebarParent = sidebar.parent();
                if (!sidebarParent.hasClass('navigation')) return; // Already moved
                
                // Clone sidebar items
                var sidebarNav = sidebar.clone();
                sidebarNav.removeAttr('id');
                sidebarNav.addClass('nav navbar-nav longnode-sidebar-clone');
                
                // Remove unnecessary items
                sidebarNav.find('.nav-head').remove();
                sidebarNav.find('.create-shelf').remove();
                sidebarNav.find('#nav_createshelf').remove();
                sidebarNav.find('#nav_about').remove();
                
                $('.navbar-collapse').append(sidebarNav);
            }
            
            // Run after a delay to let Intention.js run first
            setTimeout(cloneSidebarToHamburger, 200);
            setTimeout(cloneSidebarToHamburger, 500);
        }
    });
    
})();

// ========================================
// Book Cover Tooltips
// ========================================

(function() {
    'use strict';
    
    // Configuration (easy to modify)
    const TOOLTIP_CONFIG = {
        maxChars: 500,  // Maximum characters to show
        positionKey: 'data-tooltip-position',  // Data attribute for position
        edgeThreshold: 50,  // Pixels from edge to trigger repositioning
        tooltipWidth: 400,  // Approximate tooltip width for positioning calculations
        ellipsis: '…'  // Character to use for truncation
    };
    
    // Truncate text with ellipsis
    function truncateText(text, maxLength) {
        if (!text || text.length <= maxLength) {
            return text;
        }
        
        // Find the last space before maxLength to avoid cutting words
        let truncated = text.substring(0, maxLength);
        const lastSpace = truncated.lastIndexOf(' ');
        
        if (lastSpace > maxLength * 0.8) {  // Only use space if it's reasonably close
            truncated = truncated.substring(0, lastSpace);
        }
        
        return truncated.trim() + TOOLTIP_CONFIG.ellipsis;
    }
    
    // Strip HTML tags from description while preserving line breaks
    function stripHtml(html) {
        if (!html) return '';
        
        // Convert block elements and <br> to newlines before stripping
        let text = html
            .replace(/<\/p>/gi, '\n\n')           // Paragraph end -> double newline
            .replace(/<p[^>]*>/gi, '')             // Remove <p> opening tags
            .replace(/<br\s*\/?>/gi, '\n')         // <br> -> newline
            .replace(/<\/div>/gi, '\n')            // Div end -> newline
            .replace(/<div[^>]*>/gi, '')           // Remove <div> opening tags
            .replace(/<\/li>/gi, '\n')             // List item end -> newline
            .replace(/<li[^>]*>/gi, '• ');         // List item start -> bullet
        
        // Now strip remaining HTML tags
        const temp = document.createElement('div');
        temp.innerHTML = text;
        text = temp.textContent || temp.innerText || '';
        
        // Clean up excessive whitespace but preserve intentional line breaks
        text = text
            .replace(/\n\s*\n\s*\n/g, '\n\n')      // Max 2 consecutive newlines
            .replace(/[ \t]+/g, ' ')                // Multiple spaces -> single space
            .trim();
        
        return text;
    }
    
    // Calculate best tooltip position based on element position
    function calculateTooltipPosition(element) {
        const rect = element.getBoundingClientRect();
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;
        
        const spaceTop = rect.top;
        const spaceRight = viewportWidth - rect.right;
        const spaceBottom = viewportHeight - rect.bottom;
        const spaceLeft = rect.left;
        
        // For books in the first column (left edge), strongly prefer right positioning
        // This ensures tooltip overlays the main content area, not the left sidebar
        const isLeftColumn = rect.left < 300; // Approximate width of sidebar + first column
        
        // Calculate if tooltip would fit in each direction
        const fitsTop = spaceTop > 250;
        const fitsRight = spaceRight > (TOOLTIP_CONFIG.tooltipWidth + 20);
        const fitsBottom = spaceBottom > 250;
        const fitsLeft = spaceLeft > (TOOLTIP_CONFIG.tooltipWidth + 20);
        
        // Special handling for left column: always prefer right if there's any space
        if (isLeftColumn && spaceRight > 200) {
            return 'right';
        }
        
        // Priority: top > right > bottom > left (but only if it fits!)
        if (fitsTop) {
            return 'top';
        } else if (fitsRight) {
            return 'right';
        } else if (fitsBottom) {
            return 'bottom';
        } else if (fitsLeft) {
            return 'left';
        }
        
        // If nothing fits perfectly, choose the side with most space
        const maxSpace = Math.max(spaceTop, spaceRight, spaceBottom, spaceLeft);
        if (maxSpace === spaceTop) return 'top';
        if (maxSpace === spaceRight) return 'right';
        if (maxSpace === spaceBottom) return 'bottom';
        return 'left';
    }
    
    // Apply tooltip position classes
    function applyTooltipPosition(element) {
        // Remove existing position classes
        element.classList.remove('ln-tooltip-top', 'ln-tooltip-right', 'ln-tooltip-bottom', 'ln-tooltip-left');
        
        // Get or calculate position
        let position = element.getAttribute(TOOLTIP_CONFIG.positionKey);
        if (!position) {
            position = calculateTooltipPosition(element);
            element.setAttribute(TOOLTIP_CONFIG.positionKey, position);
        }
        
        // Apply position class
        element.classList.add(`ln-tooltip-${position}`);
    }
    
    // Initialize tooltip for a book cover element
    function initTooltip(element) {
        // Check if this is an img element with data-description
        const img = element.querySelector('img[data-description]');
        if (!img) return;
        
        // Get description from data attribute and restore newlines
        let description = img.getAttribute('data-description');
        if (description) {
            // Convert the placeholder back to actual newlines
            description = description.replace(/\|\|\|NL\|\|\|/g, '\n');
        }
        const title = element.getAttribute('title');
        
        // Prepare tooltip text
        let tooltipText = '';
        if (description && description.trim() !== '') {
            // Strip any remaining HTML and truncate
            const cleanDescription = stripHtml(description);
            tooltipText = truncateText(cleanDescription, TOOLTIP_CONFIG.maxChars);
        } else {
            // Fallback to title
            tooltipText = title || 'No description available';
        }
        
        // Set tooltip data attribute
        element.setAttribute('data-tooltip', tooltipText);
        
        // Remove title attribute to prevent native browser tooltip
        element.removeAttribute('title');
        
        // Add tooltip classes
        element.classList.add('ln-tooltip', 'ln-tooltip-top');  // Default to top initially
        
        // Set up hover event for position calculation
        element.addEventListener('mouseenter', function() {
            applyTooltipPosition(element);
        });
    }
    
    // Initialize all book cover tooltips on the page
    function initAllTooltips() {
        // Find all book cover spans in Long Node theme
        const bookCovers = document.querySelectorAll('body.longnode .book .cover span.img');
        
        bookCovers.forEach(cover => {
            initTooltip(cover);
        });
        
        console.log(`Initialized ${bookCovers.length} book cover tooltips`);
    }
    
    // Initialize on page load
    $(document).ready(function() {
        if ($('body').hasClass('longnode')) {
            initAllTooltips();
        }
    });
    
    // Re-initialize on dynamic content changes (e.g., infinite scroll, filters)
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.addedNodes.length) {
                mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === 1 && node.querySelector) {
                        const newCovers = node.querySelectorAll('.book .cover span.img');
                        newCovers.forEach(cover => {
                            if (!cover.classList.contains('ln-tooltip')) {
                                initTooltip(cover);
                            }
                        });
                    }
                });
            }
        });
    });
    
    // Observe the main content area for changes
    if ($('body').hasClass('longnode')) {
        const targetNode = document.querySelector('.container-fluid');
        if (targetNode) {
            observer.observe(targetNode, {
                childList: true,
                subtree: true
            });
        }
    }
    
})();
