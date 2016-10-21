package Complete::Fish::Gen::FromPerinciCmdLine;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use String::ShellQuote;

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_fish_complete_from_perinci_cmdline_script);

$SPEC{gen_fish_complete_from_perinci_cmdline_script} = {
    v => 1.1,
    summary => 'Dump Perinci::CmdLine script '.
        'and generate fish completion from it',
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        cmdname => {
            summary => 'Command name (by default will be extracted from filename)',
            schema => 'str*',
        },
        compname => {
            summary => 'Completer name (in case different from cmdname)',
            schema => 'str*',
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be fed to the fish shell',
    },
};
sub gen_fish_complete_from_perinci_cmdline_script {
    my %args = @_;
    my $filename = $args{filename};

    require Perinci::CmdLine::Dump;
    my $dump_res = Perinci::CmdLine::Dump::dump_perinci_cmdline_script(
        filename => $filename);
    return [500, "Can't dump script: $dump_res->[0] - $dump_res->[1]"]
        unless $dump_res->[0] == 200;

    my $cli = $dump_res->[2];

    if ($cli->{subcommands}) {
        return [200, "OK",
                "# TODO: script with subcommands not yet supported\n"];
    }

    state $pa = do {
        require Perinci::Access;
        Perinci::Access->new;
    };
    my $riap_res = $pa->request(meta => $cli->{url});
    return [500, "Can't Riap request: meta => $cli->{url}: ".
                "$riap_res->[0] - $riap_res->[1]"]
        unless $riap_res->[0] == 200;

    my $meta = $riap_res->[2];

    require Perinci::Sub::GetArgs::Argv;
    my $gengls_res = Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
        meta => $meta,
        meta_is_normalized => 1,
        common_opts => $cli->{common_opts},
        per_arg_json => $cli->{per_arg_json},
        per_arg_yaml => $cli->{per_arg_yaml},
    );
    return [500, "Can't generate Getopt::Long spec: ".
                "$gengls_res->[0] - $gengls_res->[1]"]
        unless $gengls_res->[0] == 200;
    my $glspec = $gengls_res->[2];

    $glspec->{'<>'} = sub{};

    my $cmdname = $args{cmdname};
    if (!$cmdname) {
        ($cmdname = $filename) =~ s!.+/!!;
    }
    my $compname = $args{compname} // $cmdname;

    require Complete::Fish::Gen::FromGetoptLong;
    Complete::Fish::Gen::FromGetoptLong::gen_fish_complete_from_getopt_long_spec(
        spec => $glspec,
        cmdname => $cmdname,
        compname => $compname,
    );
}

1;
# ABSTRACT:

=head1 SYNOPSIS


=head1 SEE ALSO

This module is used by L<Getopt::Long::Complete>.

L<Perinci::Sub::To::FishComplete>
