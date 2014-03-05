	jQuery(function() {
	  jQblink = function($obj, t) {
	    $obj.fadeOut(t);
		$obj.fadeIn(t);
		return $obj;
	  };
      jQuery(window).scrollTop(2);
      jQuery('#read_site')[0].innerHTML = (window.location.host)? window.location.host : window.location;
	  jQblink( jQblink( jQblink(jQuery('#mode'),600), 600), 600);
	  
	  jQuery('#toggle_control').click(function($evt) {
		var $this = jQuery(this);
		$this.unbind();
		return toggleControl( 'off', $this );
	  } ).html( 
	  	"Hide Control" 
	  );
		
		jQuery('img').each(function(idx) {
			if( this.src.match(/svg/) !== null ) {
				this.style.width = "480px";
				this.style.width = "270px";
			}
		});
    });
	
	function toggleControl( on_off, $this ) {
		var on_off = on_off || 'off',
			$background = jQuery('#transparent_background');
		if( on_off === 'off' ) {
			$background.animate({ 
				'height': "0px",
				'min-height': "0px",
				'max-height': "0px"
			}, 1100)
			$this.html( "Show Control" );
			$this.click(function($evt) {
				var $this = jQuery(this);
				$this.unbind();
				return toggleControl( 'on', $this );
	  		} );
			
		} else {
			$background.animate({ 
				'height': "6400px",
				'min-height': "6400px",
				'max-height': "6400px"
			}, 1100);
			$this.html( "Hide Control" );
			$this.click(function($evt) {
				var $this = jQuery(this);
				$this.unbind();
				return toggleControl( 'off', $this );
	  		} );
		}
		return true;
	}
