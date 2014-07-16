#!/usr/bin/perl
use Mojolicious::Lite;
use Mojo::UserAgent;
use Mojo::Log;

# Additional modules requirements
use IO::Compress::Gzip 'gzip';
use Markdent::Parser;
use Markdent::Handler::HTMLStream::Fragment;

# The hypnotoad port I use, which relies on a sytem route to redirect
# users who connect to port 80, so I don't have to run hypnotoad as root
app->config( hypnotoad => {listen=>['http://*:8000']} );

our $version = Mojolicious->VERSION;

my $app = app;
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
    ( $base_url, $port ) = $c->req->url->base =~ /(.*[\w|\-|\.]+)(\:\d+)?/;
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
	$self->render('index');
};

sub getFrame {
	my( $self, $URL, $port, $path, $title ) = @_;
	$self->stash( url => "$URL$port$path" );
	$self->stash( title => $title );
	$self->render('iframe');
};

sub getReadme {
	my( $self, $readme ) = @_;
	my $log = Mojo::Log->new();
	my $URL = $self->req->url->base;
	my( $fh, $mh, $save_line_sep );
	my $mark2html = '';
	open $mh, '>', \$mark2html;
	my $mark = Markdent::Parser->new(
		dialect => 'GitHub',
		handler => Markdent::Handler::HTMLStream::Fragment->new(
			output => $mh
		)
	);
	
	open $fh, '<'.$readme;
	$save_line_sep = $/; # Save line seperator vaule
    undef $/; # Allows one pass input of entire file
	$mark->parse( markdown => <$fh> );
    $/ = $save_line_sep; # Restore line seprator
	close $fh;
	close $mh;
	
	$self->stash( 
		url => $URL, 
		version => $version, 
		mark2html => $mark2html 
	);
	$self->render('readme');
};

sub rel2AbsURI {
	my( $gotten, $abspath, $apppath ) = @_;
	my $log = Mojo::Log->new();
	$log->debug( "abspath: $abspath, apppath: $apppath \n" );
	my (@gotten, @rendered, $responce);
	@gotten = split( "\n", $gotten );

	for my $fline (@gotten) {
		# Make sure that linked resources use absolute URIs
		if ( ($fline =~ /(<a)/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.|\#)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			$log->debug( "<!--Resource $resname -->\n" );
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
				if( $resname ) {
					$fline =~ s/$resname/$apppath$resname/;
				} 
			}
			$log->debug( $fline."\n" );
			$responce = $fline;

		} elsif ( ($fline =~ /(<link)/) and ($fline =~ /stylesheet/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			$log->debug( "<!--Resource $resname -->\n" );
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
				$fline =~ s/$resname/$apppath$resname/;
				$log->debug( $fline."\n" );
			} 
			$responce = $fline;

		} elsif ( ($fline =~ /(<script)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			$log->debug( "<!--Resource $resname -->\n" );
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
				$fline =~ s/$resname/$apppath$resname/;
				$log->debug( $fline."\n" );
			} 
			$responce = $fline;
    
		} elsif ( ($fline =~ /(<iframe)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			$log->debug( "<!--Resource $resname -->\n" );
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$apppath$resname/;
				$log->debug( $fline."\n" );
			} 
			$responce = $fline;

		} elsif ( ($fline =~ /(<img)/s) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ){
			my $resname = $4;
			$log->debug( "<!--Resource $resname -->\n" );
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$apppath$resname/;
				$log->debug( $fline."\n" );
			} 
			$responce = $fline;
 
		} elsif ( ($fline =~ /(<source)/s) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ){
			my $resname = $4;
			$log->debug( "<!--Resource $resname -->\n" );
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$apppath$resname/;
				$log->debug( $fline."\n" );
			} 
			$responce = $fline;
      
		}  else {
			$responce = $fline;
		}
		@rendered = (@rendered, $responce);
	}
	
	return( inline => ( join "\n", @rendered ) );
};

get '/' => sub {
	my $self = shift;
	getIndex($self);
};

get '/readme' => sub {
	my $self = shift;
	getReadme($self, 'README.md');
};

get '/license' => sub {
	my $self = shift;
	getReadme($self, 'LICENSE.md');
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

# Import routes from submodules (if they exist)
#do qq{my-mojo/uni-sol.pl};
do qq{js-demos/uni-sol.pl};
do qq{svg-demos/uni-sol.pl};
do qq{revlin/uni-sol.pl};


# Make sure you change this to a personal password when 
# launching a live production site AND DO NOT GIT COMMIT 
# changes with your personal password showing ( 
# hint: store your pass in a file outside the source tree, 
# like /home/secret/private/auth/p@$$w0rd.pl or something )
#
#$app->secret('p@$$w0rd');
$app->start;

__DATA__

@@ layouts/home.html.ep
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" >
<html xmlns="http://www.w3.org/1999/xhtml"><head>
  <title><%= title %></title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <meta http-equiv="Pragma" content="no-cache">
  <meta name="viewport" content="width=640,user-scalable=no" />
  <link rel='stylesheet' type='text/css' href='/styles/new_home.css' />
  
  <script type="text/javascript" src="/scripts/jquery.min.js"></script>
  <script type="text/javascript" src="/scripts/cycle2/build/jquery.cycle2.min.js"></script>
  <script type="text/javascript" src="/scripts/debugger.js"></script>
  <script type="text/javascript" src="/scripts/control.js"></script>
  
</head>
<body <%{ no strict 'vars'; if( (defined $canvasApp) || (defined $svgApp) ){ %>onload="load();"<% } } %> >
  <div id="uni-sol">
  	<div <%
		{ no strict 'vars'; 
			if( (defined $svgApp) ){ 
		%>class="cycle-slideshow" style="z-index: -1" data-cycle-speed="1500" data-cycle-loop="1" data-cycle-allow-wrap="false" data-cycle-reverse="false">
  		<img id="layer0" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer1" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer2" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer3" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer4" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer5" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer6" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer7" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer8" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" />
  		<img id="layer9" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" /><%
			} else {
		%> >
  		<img id="layer1" alt="Blue Earth from Space" width="100%" src="/images/PlanetEarthBluePlanet.jpeg" /><% 
			}
		}
		%>
  	</div>
  </div>

  <div id='transparent_background'></div>
  <div id='home_screen'>

      <div id='trademark'>
        Uni:Sol::<br />
        Creative:<br />
        Control:<br />     
      </div>
      <div id='title' class='titles'>
        <h1><%
{ 
	no strict 'vars';
	if( defined $header ) {
		%><%= $header %><%
	} else { 
		%>Make Control<%
		1;
	}
}	
		%></h1><br />
			<span id='mode'>reading: </span>
			<a id='read_site' href=''></a>
		</div>

		<div id="content">
			<%= content %>
			<div id='mojo-version'>
				<p><img src="/images/triad.png" /></p>
				<a href="/mojolicious">Mojolicious</a><br /> 
				v<%= $version %> 
			</div>
			<br /><br /><br />
		</div>

	</div>
	
	<div id="control">
		<a id="toggle_control" href="."></a>
	</div>
  
<!--[if lt IE 9]><script type="text/javascript">
try{ document.createElement('canvas').getContext('2d');} catch(e){
document.getElementsByTagName('body')[0].onload='';
alert("Your browser is missing some essential features and capabilities.\n Please install a recent release of Mozilla Firefox or Google Chrome.");
}
</script><![endif]-->

</body></html>
