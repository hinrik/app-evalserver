#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Output;

BEGIN {
    eval "use JSON::Any";
    plan skip_all => "JSON::Any couldn't be loaded" if $@;
}

use App::EvalServer;
use POE;
use POE::Filter::JSON;
use POE::Wheel::ReadWrite;
use Socket;

plan tests => 4;

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw<
            _start
            connect_failed
            connected
            eval_read
            eval_error
            shutdown
        >],
    ],
);

sub writer {
    $poe_kernel->run;
}

stderr_unlike(\&writer, qr/Can't call method "kill" on unblessed reference/, "unblessed kill");

sub _start {
    my $port = get_port();
    $_[HEAP]{server} = App::EvalServer->new(
        port    => $port,
        unsafe  => 1,
        timeout => 0.01,
    );

    $_[HEAP]{server}->run();

    $_[HEAP]{socket} = POE::Wheel::SocketFactory->new(
        RemoteAddress  => '127.0.0.1',
        RemotePort     => $port,
        FailureEvent => 'connect_failed',
        SuccessEvent => 'connected',
    );
}

sub get_port {
    my $wheel = POE::Wheel::SocketFactory->new(
        BindAddress  => '127.0.0.1',
        BindPort     => 0,
        SuccessEvent => '_fake_success',
        FailureEvent => '_fake_failure',
    );  

    return if !$wheel;
    return unpack_sockaddr_in($wheel->getsockname()) if wantarray;
    return (unpack_sockaddr_in($wheel->getsockname))[0];
}

sub connect_failed {
    fail("Failed to connect to EvalServer: $_[ARG2]");
    $_[KERNEL]->yield('shutdown');
}

sub connected {
    my ($socket) = $_[ARG0];
    pass('Connected to EvalServer');

    $_[HEAP]{rw} = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Filter     => POE::Filter::JSON->new(),
        InputEvent => 'eval_read',
        ErrorEvent => 'eval_error',
    );

    $_[HEAP]{rw}->put({
        lang => 'perl',
        code => 'my $ret = 2+2; foreach (1..1000000) { $ret++; $ret--; } $ret',
    });
}

sub eval_read {
    my ($input) = $_[ARG0];
    is($input->{result}, undef, 'Got the right result');
    $_[HEAP]{success} = 1;
}

sub eval_error {
    if ($_[HEAP]{success}) {
        pass('Got disconnected');
    }
    else {
        fail('Got prematurely disconnected');
    }
    $_[KERNEL]->yield('shutdown');
}

sub shutdown {
    $_[HEAP]{server}->shutdown();
    delete $_[HEAP]{server};
    delete $_[HEAP]{rw};
    delete $_[HEAP]{socket};
}
