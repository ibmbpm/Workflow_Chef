name			'workflow'
maintainer		'IBM Corp'
maintainer_email 	''
license 		'Copyright 2018 IBM Corporation'
description      	'Installs and configures IBM Business Automation Workflow'
long_description 	IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version 		'3.0.2'

chef_version 		'>= 12.5' if respond_to?(:chef_version)

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/workflow/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/workflow'

depends			'ibm_cloud_utils'
#depends			'im'
depends			'linux'
supports		'Ubuntu16', '>= 16.0.4'

recipe 'workflow::prereq.rb', '
Adds the prerequisites that need to be added to the environment before you install Business Automation Workflow. This includes
Adding users, Packages, Kernel Configuration
'
recipe 'workflow::prereq_check.rb', '
Checks the environment before software is installed.
'
recipe 'workflow::install.rb', '
Installs IBM Business Automation Workflow.
'
recipe 'workflow::applyifix.rb', '
Apply ifixes for IBM Business Automation Workflow.
'
recipe 'workflow::cleanup.rb', '
Removes all unwanted files, such as installation media and temp files.
'
recipe 'workflow::gather_evidence.rb', '
This recipe will gather artifacts to prove an installation has occurred successfully.
'
recipe 'workflow::create_singlecluster.rb', '
Creates an IBM Business Automation Workflow SingleCluster topology.
'
recipe 'workflow::create_singleclusters.rb', '
Creates an IBM Business Automation Workflow SingleCluster on Multiple Nodes topology.
'
