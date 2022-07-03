% DNS privacy lab

In this exercise we will have a look at the privacy implications of DNS resolution and will learn how to harden our DNS set-up against some of these issues.

## Resolver to authoritative name server privacy

We will first have a look at the data that is exposed in DNS transactions between the DNS resolver and the authoritative name server.

### DNS Query Name Minimisation ([RFC7816bis](https://www.ietf.org/archive/id/draft-ietf-dnsop-rfc7816bis-11.html))
Unbound already has a privacy feature enable by default. To get a better understanding of the potential privacy impact of DNS transactions we will disable this feature for now:

1. Disable QNAME minimisation support in your Unbound configuration:
   `qname-minimisation: no`

We will use the logging functionality in Unbound to display all the outgoing query information. Unbound has to be configured with a `verbosity` of 3 or higher to log all outgoing queries.

2. Restart your Unbound instance to make sure the cache is empty
3. Monitor the Unbound log output for all outgoing queries (hint, grep for `sending`)
4. Send a DNS query to Unbound (replace `<team-number>` with the number of your team):
   `drill www.dnslab.uk @res-<team-number>.do.dns-school.org`
   (or without `@res-<team-number>.do.dns-school.org` if you're doing the query
   on your resolver machine itself)
5. Observe which information from the query is exposed to which upstream name
   servers.
6. What does it say when you query for `qnamemintest.internet.nl TXT`?

We will now repeat this exercise with QNAME minimisation enabled.

7. Enable QNAME minimisation support in your unbound configuration:
   `qname-minimisation: yes`
8. Restart your Unbound instance again to make sure the cache is empty
9. Send the same DNS query to Unbound:
   `drill www.dnslab.uk @res-<team-number>.do.dns-school.org`
   (or without `@res-<team-number>.do.dns-school.org` if you're doing the query
   on your resolver machine itself)
10. Observe what information from the query is exposed to which upstream name
    servers. What are the differences?
11. What does it say now if you query for `qnamemintest.internet.nl TXT`?
    Can you tell how the test works?

### Running a Root Server Local to a Resolver ([RFC8806](https://www.rfc-editor.org/rfc/rfc8806.html))
Another way to limit the queries that Unbound has to send upstream is by loading authoritative DNS data into Unbound. In this exercise we will do this for the root zone.

12. Add this to your Unbound configuration to have it transfer the root zone into the resolver, having this data already in the resolver means that we don't have to send DNS queries to get it anymore:

```
   auth-zone:
     name: "."
     master: 199.9.14.201         # b.root-servers.net
     master: 192.33.4.12          # c.root-servers.net
     master: 199.7.91.13          # d.root-servers.net
     master: 192.5.5.241          # f.root-servers.net
     master: 192.112.36.4         # g.root-servers.net
     master: 193.0.14.129         # k.root-servers.net
     master: 192.0.47.132         # xfr.cjr.dns.icann.org
     master: 192.0.32.132         # xfr.lax.dns.icann.org
     master: 2001:500:200::b      # b.root-servers.net
     master: 2001:500:2::c        # c.root-servers.net
     master: 2001:500:2d::d       # d.root-servers.net
     master: 2001:500:2f::f       # f.root-servers.net
     master: 2001:500:12::d0d     # g.root-servers.net
     master: 2001:7fd::1          # k.root-servers.net
     master: 2620:0:2830:202::132 # xfr.cjr.dns.icann.org
     master: 2620:0:2d0:202::132  # xfr.lax.dns.icann.org
     fallback-enabled: yes
     for-downstream: no
     for-upstream: yes
```
13. Restart Unbound and again send the same query:
   `drill www.dnslab.uk @res-<team-number>.do.dns-school.org`
   How do the queries that are send to the root name servers with the auth-zone compare to the earlier    queries for the same domain name?
   
### Aggressive Use of DNSSEC-Validated Cache ([RFC8198](https://www.rfc-editor.org/rfc/rfc8198.html))
Yet another (and complimentary) way to reduce the number of outgoing queries is by using aggressive NSEC. Aggressive  NSEC is at the moment disabled by default in Unbound. We will first use this default to observe the traffic without
aggressive NSEC.

We first need to get some NSEC records in our cache.

14. Send a query for a non-existing domain. Observe the returned NSEC records.
   
       drill -D bangkok.nlnetlabs.nl @res-<team-number>.do.dns-school.org

    For above query this is one of the NSEC records we get back:
    
        bakkie.nlnetlabs.nl.	3600	IN	NSEC	bartok.nlnetlabs.nl.

15. Send a query for another domain that is covered by this NSEC record:

       drill -D banana.nlnetlabs.nl @res-<team-number>.do.dns-school.org

    If you now look at your Unbound log you will see that for both queries Unbound will contact the nlnetlabs.nl name server.

16. Enable aggressive NSEC in your Unbound configuration:

       aggressive-nsec: yes

17. Restart Unbound and send the same two queries:
    
        drill -D bangkok.nlnetlabs.nl @res-<team-number>.do.dns-school.org

        drill -D banana.nlnetlabs.nl @res-<team-number>.do.dns-school.org

    Can you see a difference in the queuries that are send to the nlnetlabs.nl name servers?

### Stubby
We will use Stubby to proxy the DNS queries originating from our laptop over an encrypted channel to Unbound.

18. Install stubby on your laptop
	- Linux: `apt install stubby`
	- OS X: `brew install stubby`
	- Windows binaries available

    Have a look at <https://dnsprivacy.org/wiki/display/DP/About+Stubby> for detailed installation instructions.

    Although the default stubby configuration is already privacy aware, we will start with an empty configuration file to get a better understanding of all the different options.

    It may be convenient to run stubby on your auth machine.
    Just make sure to let NSD listen on the public IP addresses explicitly, so stubby can be used to listen on 127.0.0.1
    For that add the following lines to `/etc/nsd/nsd.conf`:

        interface: <IPv4 of your auth-<team> machine>
        interface: <IPv6 of your auth-<team> machine>

    and then restart nsd: `systemctl restart nsd`

19. Create a stubby configuration file names `stubby-nominet.yml` and add this configuration:

        listen_addresses:
          - 127.0.0.1
          - 0::1
        upstream_recursive_servers:
          - address_data: 8.8.8.8
        edns_client_subnet_private: 0

    Stubby will now listen on 127.0.0.1 and ::1 for DNS queries and send these queries upstream to the google resolver, which is not very private and perhaps less private than you might think. If your laptop already has a process listening on port 53 for this address try to use another local address, like 127.0.0.10.


20. Run stubby:
    
        stubby -C stubby-nominet.yml -l

21. Test your configuration by sending a DNS query to stubby:
   
        drill dns-school.org @127.0.0.1

### EDNS client subnet, client information exposure
In the previous example we configured stubby to send all queries to a resolver that sends ECS information in queries going to the google.com name servers. We are now going to look at the privacy implications of ECS.

22. Query stubby for the TXT record of the `o-o.myaddr.l.google.com.` domain.
   
        drill o-o.myaddr.l.google.com. @127.0.0.1 txt

    This test domain returns the received ECS prefix as TXT record. You will now see the prefix of your IP address, even though this information is usually hidden by using the resolver!

    The [ECS RFC](https://tools.ietf.org/html/rfc7871) mandates that resolvers must use the received ECS option from the query if this is available and not override it themselves. This means that is we as client send a /0 option the ECS resolver should not reveal our address. It is possible to configure stubby to add the /0 option to every outgoing query.

23. Enable the `edns_client_subnet_private` option in your `stubby-nominet.yml` by setting it to 1 (which is also the default):
   
        edns_client_subnet_private: 1

24. Query stubby again for the TXT record of the `o-o.myaddr.l.google.com.` domain.
    
        drill o-o.myaddr.l.google.com. @127.0.0.1 txt

25. Observe the difference in the information received at the google.com name server. Note that the google name servers will display the source address of the _resolver_ when receiving an ECS option without useful information (like a /0 prefix).

## Stub to resolver privacy
We are now going to have a look at the privacy implications between the stub and the resolver. We are going to do this using stubby and your own Unbound installation.

26. Change the stubby configuration to send all queries to your own Unbound resolver: 

        upstream_recursive_servers:
          - address_data: <your-Unbound-IP-address>

    Replace `<your-Unbound-IP-address>` with the IP address of the machine running Unbound.

    To allow your resolver to be queried from your athoritative server, you need access-control entries in your Unbound configuration with the IP addresses of your authoritative server:

        access-control: <IPv4 of your auth-<team> machine> allow
        access-control: <IPv6 of your auth-<team> machine> allow

### DNS traffic on the wire

To get a better understanding of the privacy implications between the stub and the resolver we will use wireshark to monitor the network traffic.

27. Install wireshark on your local machine (https://www.wireshark.org/download.html).
    Alternatively install tshark on your auth machine to use it from there:

        apt install tshark
    
28. Start the capture on your network interface
29. Limit the displayed traffic to traffic that is going to and from your resolver, e.g. using the filter `ip.addr==<your-Unbound-IP-address>` where `<your-Unbound-IP-address>` the is replaced by address of your Unbound instance.
    On the auth machine using tshark this can be done like this:

        tshark -i eth0 -Y ip.addr=<your-Unbound-IP-address>
    
30. Send a DNS query via stubby to your Unbound resolver:
    
        drill dnslab.uk @127.0.0.1

31. Observe in wireshark the DNS information that is visible on the wire. This data will be visible to everybody that can somehow see the data that your machine is sending and receiving!

### DNS encryption
In this part of the exercise we will encrypt the DNS traffic between stubby on our laptop and Unbound on the experimentation server. This will be done by sending all the DNS transactions over TLS (DoT [RFC7858](https://tools.ietf.org/html/rfc7858)).

We will start by configuring Unbound to be a TLS server. For this a TLS certificate is needed. In this exercise we will request a [Let's Encrypt](https://letsencrypt.org/) certificate using [certbot](https://certbot.eff.org/).

32. Install certbot on the resolver server:
    
        apt install python3-certbot

33. Request a certificate for the domain of your resolver:
    
	systemctl stop apache2

        certbot certonly --standalone -d res-<team-number>.do.dns-school.org

    Replace *\<team-number\>* with your team number.
    
    Your newly generated CA signed certificate is now available at `/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/fullchain.pem`. The key matching this certificate is located at `/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/privkey.pem`. Time to tell Unbound where to find these files.

34. Add these lines to your Unbound configuration:
    
        tls-service-pem: "/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/fullchain.pem"
        tls-service-key: "/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/privkey.pem"
        port: 853

    Ubuntu upgraded it's security with respect to unbound, and unbound is 
    not allowed to access files in the `/etc/letsencrypt` directories anymore.
    To bypass these extra security measurements do the following:

        ln -s /etc/apparmor.d/usr.sbin.unbound /etc/apparmor.d/disable/
        apparmor_parser -R /etc/apparmor.d/usr.sbin.unbound
        service  unbound restart

    Over TCP on port 853 only TLS connection are will be accepted by Unbound now. It is however still possible to send unencrypted queries over UDP to port 853, let's disable UDP to the client to make sure all our queries to Unbound will be encrypted.

35. In the Unbound configuration:

        do-udp: no
        udp-upstream-without-downstream: yes

    Now that Unbound (only) accepts DNS queries over TLS we should change the stubby configuration to use TLS for the outgoing queries.

    And restart the unbound service

        service unbound restart

36. Edit you stubby configuration to always send queries over a TLS connection:
    ```
    dns_transport_list:
      - GETDNS_TRANSPORT_TLS
    ```

Because we requested a certificate that is signed by a trusted CA we can use the CAs store that is (probably) already on your machine for the authentication.

37. Edit your stubby.conf to only send queries when the TLS connection is authenticated, and specify the location of the CAs you trust:
    ```
    tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
    tls_ca_path: "/etc/ssl/certs/"
    ```

38. Edit the `upstream_recursive_server` stubby configuration to specify the domain name in the certificate that will be used for authentication:
	```
	upstream_recursive_servers:
	 - address_data: <your-Unbound-IP-address>
	   tls_auth_name: "res-<team-number>.do.dns-school.org"
	```
39. Send a query to stubby and observe using whireshark the data on the wire between stubby and Unbound

### DNS Queries over HTTPS (DoH) [RFC8484](https://www.rfc-editor.org/rfc/rfc8484.html)

Unfortunately the default unbound package on Ubuntu does not support DoH.
To enable it we have to recompile unbound ourselves. Follow below steps to do that.

40. Install build tools and dependencies needed for DoH support in unbound
    
        apt install build-essential libssl-dev libexpat-dev libsystemd-dev libevent-dev libnghttp2-dev

41. Fetch unbound from github

        git clone https://github.com/NLnetLabs/unbound.git

42. Configure and build unbound
    The options to `configure` below are taken from what the Ubuntu package was configured with, except that python and dnstap support are removed (so we don't need to install those dependencies too), and `--with-libnghttp2` added (at the end) to enable DoH support.

        cd unbound
        ./configure --build=x86_64-linux-gnu --prefix=/usr --includedir=${prefix}/include --mandir=${prefix}/share/man --infodir=${prefix}/share/info --sysconfdir=/etc --localstatedir=/var --disable-option-checking --disable-silent-rules --libdir=${prefix}/lib/x86_64-linux-gnu --libexecdir=${prefix}/lib/x86_64-linux-gnu --disable-maintainer-mode --disable-dependency-tracking --disable-rpath --with-pidfile=/run/unbound.pid --with-rootkey-file=/var/lib/unbound/root.key --with-libevent --enable-systemd --with-chroot-dir= --with-dnstap-socket-path=/run/dnstap.sock --libdir=/usr/lib --with-libnghttp2
        make install

43. To enable DoH on Unbound we only have to add the following to the Unbound configuration.

        interface: 0.0.0.0@443
        interface: ::0@443
        https-port: 443

44. Restart unbound:

        systemctl restart unbound

45. Follow [these](https://developers.cloudflare.com/1.1.1.1/encrypted-dns/dns-over-https/encrypted-dns-browsers) instruction to use your DoH resolver from your browser:
    - <https://developers.cloudflare.com/1.1.1.1/encrypted-dns/dns-over-https/encrypted-dns-browsers>

    Remember that your home network needs to be allowed to query the resolver!
    If the resolver does not do udp anymore (which you configed in step 35 above), then it is "okay" to just allow anyone:

        access-control: 0.0.0.0/0 allow
        access-control: ::0/0 allow

<!---
***TODO, (as bonus?):***
 - better TCP performance
   - stubby: idle_timeout
   - unbound: incoming-num-tcp, tcp-idle-timeout
   - TCP fasty open
 - android Pie
 - Monitoring
 - Cert renewal**
-->

