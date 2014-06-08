class postgresplus::service (
  $pg_service = $postgresplus::pg_service
  ){
  service { $pg_service :
    ensure  => running,
    enable  => true,
    require => Exec['Install PPA'],
    tag     => 'ppa_service'
  }
}