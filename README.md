# ABOUT

dns-monitor is a project aimed at providing statistics on dns usage

## UPDATE

The WebUI has been removed from dns-monitor.  A new project which will be released
shortly will provide an updated UI.  The database of the new project is compatible
with the dns-monitor database, so transitioning will be simple.

# REQUIREMENTS

* Perl (5.10.1 or later)
* libpcap (1.1.1 recommended)
* PostgreSQL (8.3 or later)
  * PL/PgSQL
  * ltree plugin

# INSTALL

	# Configure the Perl Environment
	perl Makefile.PL

	# Configure the Application
	cp dns_monitor.yml.default dns_monitor.yml

	# Deploy the Database
	./devel/deploy_database_schema.pl

	# Run the Sniffer
	./bin/dnsmon_sniffer.pl

	# Run the analyzer
	./bin/dnsmon_analyzer.pl

		# Or alternatively:
		./devel/monit_config.pl

	# Install the ./bin/dnsmon_maintenance.pl into the server's crontab
	#  once every 2 hours is more than enough

# UPGRADE

	# If you installed the first release, you'll need to apply the schema updates:
	./devel/deploy_database_schema.pl upgrade 20121028

# CONFIGURATION

dns_monitor.yml is YAML, no, it's not JSON.  Don't mix tabs and spaces, you will regret it.
