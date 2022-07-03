% Serving the signed zone file

1.  Let NSD serve the signed zonefile

    Edit `/etc/nsd/nsd.conf` and make sure your zonefile is read from the
    file suffixed with `.signed` (i.e. *\<name\>*.signed).

    Then, `reconfig` and `reload` NSD:

        nsd-control reconfig
        nsd-control reload

    Do you see an "unixtime" serial number in the SOA record for your zone?

        dig @localhost <name>.dnslab.uk SOA

    From your resolver machine (res-*\<team nr\>*.do.dns-school.org) you can 
    use drill to check the security:

        drill -k /var/lib/unbound/root.key -TD <name>.dnslab.uk

    Is the zone secure/trusted?

    Why not?

2.  Your zone cannot be validated yet until the chain of trust delegation
    is completed.  This means the DS record needs to be entered in
    the parent zone file.

    A DS record is available in `K<team>.dnslab.uk+013+<KSK>.ds`.
    `ldns-keygen` created it when creating the KSK.

    Optionally you can create a better DS (SHA384)

        ldns-key2ds -3 K<team>.dnslab.uk+013+<KSK>.key

    Look at the content of `K<team>.dnslab.uk+013+<KSK>.ds`  This contents
    should be placed in the parent zone, which are normally not within
    your administrative control which is now also the case.  Registries
    often have web-based forms to upload these DS records, but other
    solutions exist.
    We'll use the Slack channel, post the contents of
    the `K<team>.dnslab.uk+013+<KSK>.ds` file(s) in the slack channel to
    update them.

    You can check if the update happened already by watching:

       * <http://dnslab.uk/dnslab.uk.delegations.html>

    In future the CDS/CDNSKEY may be used to update DS records, but for
    new signing delegation this isn't an option.

3.  Now try to resolve on your resolver machine
    (res-*\<team nr\>*.dn.dns-school.org).

        dig +dnssec <name>.dnslab.uk SOA

    Is the zone secure?

        drill -k /var/lib/unbound/root.key -TD <name>.dnslab.uk

    Is the zone trusted?

    Also have a look at

      * <http://dnsviz.net/d/name.dnslab.uk>

    With *name* replaced with your name. Is everything good?

    `ldns-verify-zone` can also hunt down the chain of trust.
    If you obtained the root anchor key (the resolver machine has it for sure
    ), you could have better checked the validity of the zone:

        ldns-verify-zone -S -k /var/lib/unbound/root.key <name>.signed

4.  We have used the NSEC method to perform denial of existance proofs.
    This leads your zone open to something called "zone walking".
    You can discover all the labels in your zone:

        ldns-walk <name>.dnslab.uk

    Fun fact, the Cayman Island may be secretive about their tax havens,
    but their zone is open for walking:

        ldns-walk ky | head 30
