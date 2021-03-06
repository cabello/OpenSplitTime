(function ($) {

    var utilities = {
        isMobileSafari: function () {
            return navigator.userAgent.match(/(iPod|iPhone|iPad)/) && navigator.userAgent.match(/AppleWebKit/)
        }
    };

    var effortsPopover = {
        init: function () {
            $('[data-toggle="efforts-popover"]')
                .attr('tabindex', '0')
                .attr('role', 'button')
                .data('ajax', null)
                .popover({
                    'html': true,
                    'trigger': 'focus'
                }).on('show.bs.popover', effortsPopover.onShowPopover);
            if ( utilities.isMobileSafari() ) {
                $( 'body' ).css( 'cursor', 'pointer' );
            }
        },
        onShowPopover: function (e) {
            $self = $(this);
            var ajax = $self.data('ajax');
            if ( !ajax || typeof ajax.status == 'undefined' ) {
                var popover = $self.data('bs.popover');
                $(popover.tip).addClass('efforts-popover');
                var data = {
                    effortIds: $self.data('effort-ids')
                };
                $self.data('ajax', $.post('/efforts/mini_table/', data)
                    .done(function (response) {
                        popover.config.content = response;
                        popover.show();
                    }).always(function () {
                        $self.data('ajax', null);
                    })
                );
                e.preventDefault();
            }
        }
    };

    var staticPopover = {
        init: function () {
            $('[data-toggle="static-popover"],[data-toggle="static-popover-dark"]').each( function( i, el ) {
                $( el ).attr( 'tabindex', $( el ).attr( 'tabindex' ) || '0' )
                .attr('role', 'button')
                .popover({
                    'trigger': 'focus',
                    'container': 'body'
                });
            } );
            if ( utilities.isMobileSafari() ) {
                $( 'body' ).css( 'cursor', 'pointer' );
            }
        }
    };

    var switchery = {
    	init: function () {
    		$( '[data-toggle="switchery"]' ).each( function( i, el ) {
				$( el ).data( 'switchery', new Switchery( el, {
					size: $( el ).data( 'size' ),
                    color: '#2A9FD8'
				} ) );
    		} );
    	}
    };


    var datetimepicker = {
        init: function () {
            $.fn.datetimepicker.Constructor.Default = $.extend({}, $.fn.datetimepicker.Constructor.Default, {
                icons: {
                    time: 'far fa-clock',
                    date: 'far fa-calendar-alt',
                    up: 'fas fa-arrow-up',
                    down: 'fas fa-arrow-down',
                    previous: 'fas fa-chevron-left',
                    next: 'fas fa-chevron-right',
                    today: 'far fa-calendar-check',
                    clear: 'fas fa-trash-alt',
                    close: 'fas fa-times'
                }
            });

            $('[id^="datetimepicker"]').datetimepicker({
                sideBySide: true
            });

            $('[id^="datepicker"]').datetimepicker({
                format: 'L',
                viewMode: $(this).find(':input').val() ? 'days' : 'decades',
                viewDate: moment('1900-01-01'),
                useCurrent: false
            });
        }
    };

    var init = function () {
        effortsPopover.init();
        staticPopover.init();
        switchery.init();
        datetimepicker.init();
    };

    document.addEventListener("turbolinks:load", init );
    $(document).bind( 'vue-ready', init );

})(jQuery);
