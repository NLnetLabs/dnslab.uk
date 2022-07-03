% Signing your zone the primitive way

This excercise takes place on your master server auth-*\<team nr\>*.do.dns-school.org or *\<name\>*.dnslab.uk.

1.  We will need the `ldnsutils`.

    Did you install them already?  If not...

       `apt install ldnsutils`

    This includes the `ldns-keygen` and `ldns-signzone` utilities that can be
    used to generate keys and sign the zone.
    
2.  We will create two keys, a Zone Signing Key (ZSK) and a Key Signing Key
    (KSK).  Which command generates which?

        cd /etc/nsd

        ldns-keygen -r /dev/urandom -a RSASHA256 <name>.dnslab.uk

        ldns-keygen -r /dev/urandom -a RSASHA256 -k <name>.dnslab.uk

    Unfortunately we have to use `/dev/urandom` here rather than a slightly
    better random number generator due to limitations of the lab environment.
    Don't do this for real.

    Both commands will output the base names of the files which have to be
    used next.  The basename will look like K<name>.dnslab.uk.+008+?????
    One of the base name is the ZSK and one is the KSK.  Note down the number
    (?????) for the ZSK and the one for the KSK.  We will refer to those
    numbers later with *\<ZSK\>* and *\<KSK\>*

3.  Sign your zone with both keys using their base names:

        ldns-signzone <name> K<name>.dnslab.uk.+008+<ZSK> K<name>.dnslab.uk.+008+<KSK>

    The sequence in which the keys are placed does not matter.
    `ldns-signzone` will write a new zonefile: *\<name\>*.signed

    You can validate all the signatures in the zone:

        ldns-verify-zone <name>.signed

    You can also verify using a trust anchor.

        ldns-verify-zone -k K<name>.dnslab.uk.+008+<ZSK>.key <name>.signed

    Did that validate?

    Does the command below validate?

        ldns-verify-zone -k K<name>.dnslab.uk.+008+<KSK>.key <name>.signed

    Why? What is the difference?

4.  Using your favorite editor have a look at the signed file.  So far we have
    covered the RRSIG and DNSKEY records.  But there are more resource
    records added or modified, can you spot them?

5.  Bind from ISC has a similar toolset to sign zone files on the command
    line.  Sometimes the file formats and command line uses are about the
    same, and sometimes the options differ quite a bit.  However mostly
    all functionality is the same.

    Creating keys for instance is done using the tool `dnssec-keygen`.  Let's
    create some fresh keys to resign and for convienence we will place
    these new keys in a separate directory that we'll create first:

        mkdir -p /etc/bind/keys

    Then create two keys, with two different roles:

        dnssec-keygen -K /etc/bind/keys -a RSASHA256 -L 3600 -b 1024 <name>.dnslab.uk
        dnssec-keygen -K /etc/bind/keys -a RSASHA256 -L 3600 -b 2048 -f KSK <name>.dnslab.uk

    It's probably not a big guess to understand what all the parameters
    specify.  But about the -L parameter, can we specify different values
    to each?

6.  The Bind tool to perform signing on the command line is `dnssec-signzone`.
    We can sign the existing zone file that we used earlier with these new
    keys using:

        dnssec-signzone -K /etc/bind/keys <name>.dnslab.uk

    That did not work, tools sometimes work differently.  This usage style
    of dnssec-signzone expects the keys to be already present in the zone
    file.  So we need to add them:

        cat <name>.dnslab.uk /etc/bind/keys/*.key >> <name>.dnslab.uk.unsigned

    And then we can sign the zone that includes the keys:

        dnssec-signzone -K /etc/bind/keys -o <name>.dnslab.uk -f <name>.dnslab.uk.signed <name>.dnslab.uk.unsigned

7.  More recent versions of dnssec-signzone also has a more smart modurandus
    of operation.  Instead of adding the keys we can invoke dnssec directly:

        dnssec-signzone -K /etc/bind/keys -S <name>.dnslab.uk

    It can find out which keys to use, even if there are keys for other
    zones defined or multiple keys with different activation times.  Have
    a look at the key file, there is metadata contained within the key files.

    This is a bit useful, but it still does not manage the keys for you.
