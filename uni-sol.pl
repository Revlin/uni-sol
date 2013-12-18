#!/usr/bin/perl
use Mojolicious::Lite;
use Mojo::UserAgent;
use IO::Compress::Gzip 'gzip';

# The hypnotoad port I use, which relies on a sytem route to redirect
# users who connect to port 80, so I don't have to run hypnotoad as root
app->config( hypnotoad => {listen=>['http://*:8000']} );

my $app = app;
my $version = Mojolicious->VERSION;

# Add current working directory as path to static files
my $static = $app->static;
push @{$static->paths}, ($ENV{PWD});

# Create new instance of Mojo::UserAgent to use in routes
my $ua = Mojo::UserAgent->new;

  hook before_dispatch => sub {
    my $c = shift;
    my $app = $c->app;
	my $path = $c->req->url;
	my $port  = $c->req->url->port;
	my $base_url = '';
    ( $base_url, $port ) = $c->req->url->base =~ /(.+\.org)(\:\d+)?/;
	$app->log->debug("$base_url, $port, $path") if( $base_url );
	if( ($base_url) && ($base_url =~ /global-survival\.org/) ) {
		my $title = "Global-Survival/GSs : Netention";
		$port = ':8080';
		getFrame($c, $base_url, $port, $path, $title);
	}
	
  };

  hook after_render => sub {
    my ($c, $output, $format) = @_;

    # Check if "gzip => 1" has been set in the stash
    #return unless $c->stash->{gzip};

    # Check if user agent accepts GZip compression
    return unless ($c->req->headers->accept_encoding // '') =~ /gzip/i;
    $c->res->headers->append(Vary => 'Accept-Encoding');

    # Compress content with GZip
    $c->res->headers->content_encoding('gzip');
    gzip $output, \my $compressed;
    $$output = $compressed;
  };

sub getIndex {
	my $self = shift;
	my $URL = $self->req->url->base;
	$self->stash( url => $URL, version => $version ); # stash the url and display in template
	$self->stash( canvasApp => 'js-demos/scripts/koch.js' );
	$self->render('index');
}

sub getFrame {
	my( $self, $URL, $port, $path, $title ) = @_;
	$self->stash( url => "$URL$port$path" );
	$self->stash( title => $title );
	$self->render('iframe');
};

get '/' => sub {
	my $self = shift;
	getIndex($self);
};

get '/index' => sub {
	my $self = shift;
	getIndex($self);
};

get '/index.html' => sub {
	my $self = shift;
	getIndex($self);
};

get '/vision' => sub {
	my $self = shift;
	$self->stash( version => $version ); # stash the url and display in template
	$self->stash( canvasApp => 'js-demos/scripts/interact-visualizer.js' );
	$self->render('vision');
};

get '/visualizer' => sub {
	my $self = shift;
	$self->stash( version => $version ); # stash the url and display in template
	$self->stash( canvasApp => 'js-demos/scripts/interact-visualizer.js' );
	$self->render('visualizer');
};

get '/mojolicious' => sub {
	my $self = shift;
	my $request = join("&", 
		(
			'accept: '.$self->req->headers->accept,
			'accept_encoding: '.$self->req->headers->accept_encoding,
    		#'accept_charset: '.$self->req->headers->accept_charset,
    		'accept_language: '.$self->req->headers->accept_language,
    		#'accept_ranges: '.$self->req->headers->accept_ranges,
    		#'authorization: '.$self->req->headers->authorization,
    		#'cache_control: '.$self->req->headers->cache_control,
    		'connection: '.$self->req->headers->connection,
    		#'content_disposition: '.$self->req->headers->content_disposition,
    		#'content_encoding: '.$self->req->headers->content_encoding,
    		#'content_length: '.$self->req->headers->content_length,
    		#'content_range: '.$self->req->headers->content_range,
    		#'content_type: '.$self->req->headers->content_type,
    		#'cookie: '.$self->req->headers->cookie,
    		#'date: '.$self->req->headers->date,
    		#'dnt: '.$self->req->headers->dnt,
    		#'etag: '.$self->req->headers->etag,
    		#'expect: '.$self->req->headers->expect,
    		#'expires: '.$self->req->headers->expires,
    		'host: '.$self->req->headers->host,
    		#'if_modified_since: '.$self->req->headers->if_modified_since,
    		'is_finished: '.$self->req->headers->is_finished,
    		#'is_limit_exceded: '.$self->req->headers->is_limit_exceeded,
    		#'last_modified: '.$self->req->headers->last_modified,
    		#'leftovers: '.$self->req->headers->leftovers,
    		#'location: '.$self->req->headers->location,
    		'names: '.(join " ", sort @{$self->req->headers->names} ),
    		#'origin: '.$self->req->headers->origin,
    		#'proxy_authenticate: '.$self->req->headers->proxy_authenticate,
    		#'proxy_authorization: '.$self->req->headers->proxy_authorization,
    		#'range: '.$self->req->headers->range,
    		'referrer: '.$self->req->headers->referrer,
    		#'sec_websocket_accept: '.$self->req->headers->sec_websocket_accept,
    		#'sec_websocket_extensions: '.$self->req->headers->sec_websocket_extensions,
    		#'sec_websocket_key: '.$self->req->headers->sec_websocket_key,
    		#'sec_websocket_protocol: '.$self->req->headers->sec_websocket_protocol,
    		#'sec_websocket_version: '.$self->req->headers->sec_websocket_version,
    		#'server: '.$self->req->headers->server,
    		#'set_cookie: '.$self->req->headers->set_cookie,
    		#'status: '.$self->req->headers->status,
    		#'te: '.$self->req->headers->te,
    		#'trailer: '.$self->req->headers->trailer,
    		#'transfer_encoding: '.$self->req->headers->transfer_encoding,
    		#'upgrade: '.$self->req->headers->upgrade,
    		'user_agent: '.$self->req->headers->user_agent,
    		#'www_authenticate: '.$self->req->headers->www_authenticate
		) 
	); 
	$self->stash( version => $version ); # stash the url and display in template
	$self->stash( canvasApp => 'js-demos/scripts/koch.js' );
	$self->render('mojo', request=>$request);
};

get '/my-mojo' => sub {
	# Redirect to My Mojolicious blog
	my $self = shift;
	my ($getp, $geta) = (0, 0);
	$getp = $self->param('p') if( $self->param('p') );
	$geta = $self->param('p') if( $self->param('a') );
	myMojo($self, $getp, $geta);
};
	
sub myMojo {
	my ($self, $getp, $geta) = @_;
	my (@gotten, @rendered);
	my ($responce, $gotten);
	my $apppath = $self->req->url->base.'/my-mojo/';
	my $abspath = 'http://uni-sol.ca:81/';
	if( $getp ) {
		$gotten = $ua->get($abspath."?p=$getp")->res->dom;
	} elsif( $geta ) {
		$gotten = $ua->get($abspath."?author=$geta")->res->dom;
	} else {
		$gotten = $ua->get($abspath)->res->dom;
	}
	@gotten = split( "\n", $gotten );

	for my $fline (@gotten) {
		# Make sure that linked resources use absolute URIs
		if ( ($fline =~ /(<a)/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.|\#)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
				if( $resname ) {
					$fline =~ s/$resname/$apppath$resname/;
				} 
			} else {
				$fline =~ s/$abspath/$apppath/;
			}
			print $fline."\n";
			$responce = $fline;

		} elsif ( ($fline =~ /(<link)/) and ($fline =~ /stylesheet/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
					$fline =~ s/$resname/$abspath$resname/;
					#print $fline."\n";
			} 
			$responce = $fline;

		} elsif ( ($fline =~ /(<script)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;
    
		} elsif ( ($fline =~ /(<iframe)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;

		} elsif ( ($fline =~ /(<img)/s) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ){
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;
 
		} elsif ( ($fline =~ /(<source)/s) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ){
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;
      
		}  else {
			$responce = $fline;
		}
		@rendered = (@rendered, $responce);
	}
	$self->render( inline => ( join "\n", @rendered ) );
}

# Make sure you change this to a personal password when 
# launching a live production site AND DO NOT GIT COMMIT 
# changes with your personal password showing ( 
# hint: store your pass in a file outside the source tree, 
# like /home/secret/private/auth/p@$$w0rd.pl or something )
#
$app->secret('p@$$w0rd');
$app->start;

__DATA__

@@ layouts/home.html.ep
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" >
<html xmlns="http://www.w3.org/1999/xhtml"><head>
  <title><%= title %></title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <meta name="viewport" content="width=640,user-scalable=no" />
  <link rel='stylesheet' type='text/css' href='styles/new_home.css' />
  
</head>
<body onload="load();">
  <div id="uni-sol">
  	<img id='layer1' alt="Blue Earth from space" width="100%" src="images/PlanetEarthBluePlanet.jpeg" />
  </div>

  <div id='transparent_background'></div>
  <div id='home_screen'>

      <div id='trademark'>
        Uni:Sol::<br />
        Creative:<br />
        Control:<br />     
      </div>
      <div id='title' class='titles'>
        <h1>Make Control</h1><br />
        <span id='mode'>reading: </span>
        <a id='read_site' href=''></a>
      </div>
	  
	  <div id="content">
	    <%= content %>
	  </div>
	  
  </div>
  
  <script type="text/javascript" src="scripts/jquery.min.js"></script>
  <script type="text/javascript" src="scripts/debugger.js"></script>
  <script type='text/javascript'>
    $(function() {
	  jQblink = function($obj, t) {
	    $obj.fadeOut(t);
		$obj.fadeIn(t);
		return $obj;
	  };
      $(window).scrollTop(2);
      $('#read_site')[0].innerHTML = (window.location.host)? window.location.host : window.location;
	  jQblink( jQblink( jQblink($('#mode'),600), 600), 600);
    });
  </script>
  
  <script type="text/javascript" id="cvSrc" src="<%= $canvasApp %>"></script>
  <script type="text/javascript">
	function load() {
		var canvas=document.createElement("canvas");
		document.getElementById('uni-sol').replaceChild( canvas, document.getElementById("layer1") );
		canvasApp(canvas);
		if (typeof Debugger === "function") { 
			Debugger.on = false;
			return; 
		} else {
			window.Debugger = {
				log: function() {
					/* no debugger.js */
				}
			};
		}
	}
  </script>
  <!--[if IE lt 9]><script type="text/javascript">
  try{ document.createElement('canvas').getContext('2d');} catch(e){
	document.getElementsByTagName('body')[0].onload='';
	alert("Your browser is missing some essential features and capabilities.\n Please install a recent release of Mozilla Firefox or Google Chrome.");
  }
  </script><![endif]-->

</body></html>

@@ iframe.html.ep
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" >
<html xmlns="http://www.w3.org/1999/xhtml" style="height:97%;"><head>
  <title><%= $title %></title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  
</head>
<body style="height:100%;background-color:black;"><iframe 
		frameborder="0" marginwidth="0" width="100%"  height="100%" 
		style="width:100%;height:100%;" 
		src="<%= $url %>" />
</body></html>
