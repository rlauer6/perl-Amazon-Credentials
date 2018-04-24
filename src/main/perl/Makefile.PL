#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'Amazon::Credentials',
	      VERSION_FROM    => 'lib/Amazon/Credentials.pm',
	      AUTHOR          => ['Rob Lauer <rlauer6@comcast.net>'],
	      BUILD_REQUIRES  => {
				  'Date::Format' => 0,
				  'JSON'         => 0
				 },
	      PREREQ_PM       => {
				  'Class::Accessor' => 0,
				  'Data::Dumper'    => 0,
				  'Date::Format'    => 0,
				  'File::HomeDir'   => 0,
				  'File::chdir'     => 0,
				  'HTTP::Request'   => 0,
				  'HTTP::Response'  => 0,
				  'JSON'            => 0,
				  'LWP::UserAgent'  => 0,
				  'POSIX::strptime' => 0
				 }
	     );
