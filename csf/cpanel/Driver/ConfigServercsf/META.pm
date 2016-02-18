package Cpanel::Config::ConfigObj::Driver::ConfigServercsf::META;

use strict;

use Cpanel::Config::ConfigObj::Driver::ConfigServercsf ();

sub meta_version {
    return 1;
}

sub get_driver_name {
    return 'ConfigServercsf_driver';
}

sub content {
    my ($locale_handle) = @_;

    my $content = {
        'vendor' => 'Way to the Web Limited',
        'url'    => 'www.configserver.com',
        'name'   => {
            'short'  => 'ConfigServercsf Driver',
            'long'   => 'ConfigServercsf Driver',
            'driver' => get_driver_name(),
        },
        'since'    => 'cPanel 11.38.1',
        'abstract' => "A ConfigServercsf driver",
        'version'  => $Cpanel::Config::ConfigObj::Driver::ConfigServercsf::VERSION,
    };

    if ($locale_handle) {
        $content->{'abstract'} = $locale_handle->maketext("ConfigServer csf driver");
    }

    return $content;
}

sub showcase {
    return;
}
1;
