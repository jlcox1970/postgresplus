# == Class: postgresplus
#
# Full description of class postgresplus here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { postgresplus:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class postgresplus (
  $file_name = 'ppasmeta',
  $version = '9.3.1.3',
  $arch = 'linux-x64',
  $inst_mode = 'unattened',
  $url_base = 'https://www.dropbox.com/s/2br2697q7f8pf01',
  $superpassword = 'casper1',
  $webusername = '',
  $webpassword = '',
  $serverport = '5444',
  $key = '',
  $with_jre = false,
  $java_package = 'java-1.6.0-openjdk',
  $install_path = '/opt/PostgresPlus',
  $user = 'enterprisedb',
  $group = 'enterprisedb',
  $replication = false,
  $repl_mode = 'master',
  $repl_user = 'replicator',
  $repl_pass = 'replicator',
  $repl_target_address = 'all',
  $auth_method = 'trust'
){
 
  include concat::setup

  $v_number         = split ( $version , '[.]' )
  $v_major          = $v_number[0]
  $v_minor          = $v_number [1]
  $ver              = "$v_number[0].$v_number[1]"
  $pg_hba_conf_path = "$install_path/${v_major}.${v_minor}AS/data/pg_hba.conf"
  $pg_conf_path     = "$install_path/${v_major}.${v_minor}AS/data/postgresql.conf"
  $ppa_service      = "ppas-${v_major}.${v_minor}"
  $datadir          = "$install_path/${v_major}.${v_minor}AS/data"
  $bindir           = "$install_path/${v_major}.${v_minor}AS/bin"
  $psql_path        = "$bindir/psql"

  
  unless $superpassword {
    class {postgresplus::clean :}
    fail ( " Super User password not set")
  }
  unless $webusername {
    class {postgresplus::clean :}
    fail ( "Web User Name not set")
  }
  unless $webpassword {
    class {postgresplus::clean :}
    fail ("Web Password not set")
  }
  unless $key {
    class {postgresplus::clean :}
    fail ("Product Key not set")
  }
  if $with_jre == true {

    package { $java_package :
    }->
    exec {'Download PPA':
      cwd     => '/tmp',
      command => "wget ${url_base}/${file_name}-${version}-${arch}.tar.gz -O ${file_name}-${version}-${arch}.tar.gz",
      path    => '/usr/bin',
      creates => "/tmp/${file_name}-${version}-${arch}.tar.gz",
      require => Package[$java_package],
    }
  }
  else {
    exec {'Download PPA':
      cwd     => '/tmp',
      command => "wget ${url_base}/${file_name}-${version}-${arch}.tar.gz -O ${file_name}-${version}-${arch}.tar.gz",
      path    => '/usr/bin',
      creates => "/tmp/${file_name}-${version}-${arch}.tar.gz",
    }
  }

  anchor { 'postgresplus::start' : } ->
  exec {'Unpack PPA':
    cwd         => '/tmp',
    command     => "tar zxf ${file_name}-${version}-${arch}.tar.gz",
    path        => '/bin',
    subscribe   => Exec['Download PPA'],
    refreshonly => true,
  }->
  exec {'SeLinux Permissive':
    path        => '/usr/sbin',
    command     => 'setenforce Permissive',
    subscribe   => Exec['Unpack PPA'],
    refreshonly => true,
  }->
  exec {'Install PPA':
    cwd       => "/tmp/${file_name}-${version}-${arch}",
    command   => "${file_name}-${version}-${arch}.run --mode unattended --superpassword \"${superpassword}\" --webusername \"${webusername}\" --webpassword \"${webpassword}\" --serverport ${serverport} --productkey ${key} ",
    path      => "/tmp/${file_name}-${version}-${arch}:/usr/bin:/bin",
    onlyif    => "test ! -d /opt/PostgresPlus/${v_major}.${v_minor}AS",
  }->
  exec {'SeLinux Enforcing':
    path        => '/usr/sbin',
    command     => 'setenforce Enforcing',
    subscribe   => Exec['Install PPA'],
    refreshonly => true,
  }->
  concat { $pg_hba_conf_path:
    owner   => $user,
    group   => $group,
    mode    => '0600',
    notify => Service["$ppa_service"],
  }->
  service { "$ppa_service" :
    ensure => running,
    enable => true,
  }->
  anchor { 'postgresplus::end' : }
}
