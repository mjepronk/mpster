$(document).ready(function() {
    $('a[href*=#]:not([href=#])').each(function (i, elem) {
        var $elem = $(elem);
        if ($elem.data('slide')) return;
        $elem.click(function(e) {
            e.stopPropagation();
            if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') &&
                location.hostname == this.hostname) {
                var target = $(this.hash);
                target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
                if (target.length) {
                    $('html,body').animate({
                        scrollTop: target.offset().top
                    }, 1000, 'easeOutCubic');
                    return false;
                }
            }
        });
    });
});
