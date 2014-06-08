class postgresplus::service (
  $pg_service = $postgresplus::ppa_service
  ){
  service { $pg_service :
    ensure  => running,
    enable  => true,
    require => Exec['Install PPA'],
    tag     => 'ppa_service'
  }
}