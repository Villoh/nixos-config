{ pkgs, ... }:

{
  networking.networkmanager = {
    enable = true;
    # DMS gestiona los perfiles OpenVPN importados en NetworkManager.
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  # DNS cifrado (DoT) a nivel de sistema. NetworkManager empuja el DNS de cada
  # interfaz a systemd-resolved, pero `Domains = [ "~." ]` hace que estos
  # servidores ganen para todo lo que no tenga un dominio mas especifico.
  # Verificar: `resolvectl status` (+DNSOverTLS) y
  # `dig @<ip> +tls +short TXT proto.on.quad9.net` (Quad9) o
  # https://1.1.1.1/help (Cloudflare).
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        # Cloudflare
        "1.1.1.1#one.one.one.one"
        "1.0.0.1#one.one.one.one"
        "2606:4700:4700::1111#one.one.one.one"
        "2606:4700:4700::1001#one.one.one.one"
        # Quad9 (filtra malware). Nota: on.quad9.net no resuelve con DNSSEC
        # activo (failed-auxiliary); usar `resolvectl query --validate=no`.
        # "9.9.9.9#dns.quad9.net"
        # "149.112.112.112#dns.quad9.net"
        # "2620:fe::fe#dns.quad9.net"
        # "2620:fe::9#dns.quad9.net"
      ];
      DNSOverTLS = "true"; # estricto: sin fallback en claro
      DNSSEC = "allow-downgrade";
      Domains = [ "~." ]; # prioriza estos DNS sobre el del router
      FallbackDNS = [ ];
    };
  };

  # DNS por adaptador/red (declarativo, no aplicado). Ejemplos de
  # `ensureProfiles`; cada perfil es un keyfile de NetworkManager
  # (https://networkmanager.dev/docs/api/latest/nm-settings-keyfile.html).
  #
  # Ethernet: el router solo resuelve *.lan, el resto va a los DNS globales.
  # El interface-name actual es enp7s0 (perfil autogenerado "Wired connection 2").
  #
  #   networking.networkmanager.ensureProfiles.profiles.ethernet-casa = {
  #     connection = {
  #       id = "ethernet-casa";
  #       type = "ethernet";
  #       interface-name = "enp7s0";
  #       autoconnect-priority = 10; # gana al perfil autogenerado
  #     };
  #     ipv4 = {
  #       method = "auto";
  #       ignore-auto-dns = true; # ignora el DNS del DHCP
  #       dns = "192.168.1.1;"; # separados por ';', con ';' final
  #       dns-search = "~lan;"; # el prefijo ~ lo hace solo de enrutado
  #     };
  #     ipv6.method = "auto";
  #   };
  #
  # VPN WireGuard de la red compartida: solo su dominio va a su DNS.
  # Para una VPN de tunel completo que exija su DNS, usar dns-search = "~.;".
  #
  #   networking.networkmanager.ensureProfiles.profiles.vpn-compartida = {
  #     connection = {
  #       id = "vpn-compartida";
  #       type = "wireguard";
  #       interface-name = "wg-compartida";
  #       autoconnect = false;
  #     };
  #     wireguard.private-key = "$WG_PRIVATE_KEY"; # viene de environmentFiles
  #     "wireguard-peer.<CLAVE_PUBLICA_DEL_PEER>" = {
  #       endpoint = "vpn.ejemplo.org:51820";
  #       allowed-ips = "10.0.0.0/24;";
  #     };
  #     ipv4 = {
  #       method = "manual";
  #       address1 = "10.0.0.5/32";
  #       dns = "10.0.0.1;";
  #       dns-search = "~interno.ejemplo.org;";
  #     };
  #   };
  #   # Secretos: archivo local fuera de git con WG_PRIVATE_KEY=...
  #   networking.networkmanager.ensureProfiles.environmentFiles = [ "/etc/nm-secrets.env" ];
  #
  # Avisos:
  # - Editar un perfil declarativo desde la GUI lo copia a almacenamiento
  #   persistente y quedan dos perfiles con el mismo nombre; edita el Nix.
  # - Un perfil quitado del Nix no desaparece hasta el siguiente reinicio.
  # - `nm2nix` convierte los perfiles existentes a codigo Nix.
}
