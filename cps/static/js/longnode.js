/* Long Node Theme - Custom JavaScript */
/* Theme-specific interactions and functionality */

(function() {
    'use strict';
    
    // Long Node Theme initialization
    console.log('Long Node Theme loaded');
    
    // For book detail page: ensure sidebar items are in hamburger menu
    $(document).ready(function() {
        if ($('body').hasClass('book') && $('body').hasClass('longnode')) {
            // Check if we already have a cloned sidebar (avoid duplicates)
            var alreadyCloned = $('.navbar-collapse .longnode-sidebar-clone').length > 0;
            
            // Check if Intention.js has already moved items (mobile viewport)
            var intentionMoved = $('.navbar-collapse #scnd-nav').length > 0;
            
            if (!alreadyCloned && !intentionMoved) {
                // Clone sidebar navigation items into navbar-collapse (desktop only)
                var sidebarNav = $('.container-fluid > .row-fluid > .col-sm-2 nav.navigation ul').clone();
                if (sidebarNav.length) {
                    // Remove the ID to avoid duplicates
                    sidebarNav.removeAttr('id');
                    sidebarNav.addClass('nav navbar-nav longnode-sidebar-clone');
                    
                    // Remove unnecessary items: Browse heading, Shelves heading, Create a Shelf
                    sidebarNav.find('.nav-head').remove();
                    sidebarNav.find('.create-shelf').remove();
                    sidebarNav.find('#nav_createshelf').remove();
                    
                    $('.navbar-collapse').append(sidebarNav);
                }
            }
            
            // Also clean up items moved by Intention.js on mobile
            if (intentionMoved) {
                var movedNav = $('.navbar-collapse #scnd-nav');
                movedNav.find('.nav-head').hide();
                movedNav.find('.create-shelf').hide();
                movedNav.find('#nav_createshelf').hide();
            }
        }
    });
    
})();
