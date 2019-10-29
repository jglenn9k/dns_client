# @summary Manage DNS client settings
#
# Manage parts of the operating system that sets DNS client settings.
#
# @example
#   include dns_client
class dns_client (
  Array $nameservers = ['8.8.8.8', '8.8.4.4', '4.2.2.1'],
  Array $options     = [ 'rotate', 'timeout:1'],
  String $search     = undef,
) {
  case $facts['os']['name'] {
    'Ubuntu': {
      case $facts['os']['release']['full'] {
        '18.04': {
          $dns_nameservers = join($nameservers,',')
          file_line {'nameservers':
            ensure => 'present',
            path   => '/etc/netplan/01-netcfg.yaml',
            line   => "        addresses: [${dns_nameservers}]",
            match  => '^        addresses',
            notify => Exec['netplan apply'],
          }
          file_line {'nameservers':
            ensure => 'present',
            path   => '/etc/netplan/01-netcfg.yaml',
            line   => "        search: [${search}]",
            match  => '^        search',
            notify => Exec['netplan apply'],
          }
          exec {'netplan apply':
            path        => '/usr/sbin',
            user        => 'root',
            refreshonly => true,
          }
        }
        default: {
          file { '/etc/resolv.conf':
            ensure => 'link',
            owner  => 'root',
            group  => 'root',
            mode   => '0777',
            target => '../run/resolvconf/resolv.conf',
          }
          file {'/run/resolvconf/resolv.conf':
            ensure  => 'file',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('dns_client/resolv.conf.erb'),
          }
          $dns_nameservers = join($nameservers,' ')
          file_line { 'dns-nameservers':
            ensure => 'present',
            path   => '/etc/network/interfaces',
            line   => "dns-nameservers ${dns_nameservers}",
            match  => '^dns-nameservers',
          }
          file_line { 'dns-search':
            ensure => 'present',
            path   => '/etc/network/interfaces',
            line   => "dns-search ${search}",
            match  => '^dns-search',
          }
        }
      }
    }
    'windows': {
      notify { 'Work in progress.':
        withpath => true,
      }
    }
    default: {
      notify {"${::facts['os']['name']} is not supported. Please feel free to open a pull request at https://github.com/jglenn9k/dns_client.":
        withpath => true,
      }
    }
  }
}
