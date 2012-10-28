# ABOUT

dns-monitor is a project aimed at providing statistics on dns usage


## UPDATE

This project will be replaced by a new dns monitoring suite, but the database structure will
remain the same, so transitioning to the new interface will be painless.


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

	# Run the application locally
	./scripts/dns_monitor.pl -p 3000

	# Point your web browser to
	http://localhost:3000/   # See Stuff

		# Or deploy using mod_fcgid and Apache with:
		ln -s ./conf/apache.conf /etc/httpd/conf.d/dnsmonitor.conf

		# Then navigate to:
		http://localhost/dns-monitor/

	# Install the ./bin/dnsmon_maintenance.pl into the server's crontab
	#  once every 2 hours is more than enough

# UPGRADE

	# If you installed the first release, you'll need to apply the schema updates:
	./devel/deploy_database_schema.pl upgrade 20121028

# CONFIGURATION

dns_monitor.yml is YAML, no, it's not JSON.  Don't mix tabs and spaces, you will regret it.
